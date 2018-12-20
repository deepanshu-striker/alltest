#!/bin/bash -x

BASE_DIR="$(pwd)"

rm -f build.properties openstack-auth.sh test_results*
cp build_setup/build.properties .
cp build_setup/openstack-auth.sh .

source build.properties
source openstack-auth.sh

if [ ! -d $BASE_DIR/vars ]; then
   mkdir -p $BASE_DIR/vars
fi
echo "flavor_name: $flavor_name-test" > vars/tvault-config.yml
echo "tvault_vm_name: $tvault_vm_name-test" >> vars/tvault-config.yml
echo "image_name: $image_name-$TVAULT_VERSION" >> vars/tvault-config.yml
echo "security_group_name: $security_group_name-test" >> vars/tvault-config.yml
echo "key_name: $key_name" >> vars/tvault-config.yml
echo "fixed_network_id: $fixed_network_id" >> vars/tvault-config.yml
echo "floating_ip: $floating_ip" >> vars/tvault-config.yml
echo "old_build_file: $OLD_BUILD_FILE" >> vars/tvault-config.yml

echo "auth:" > vars/openstack-config.yml
echo "    auth_url: $OS_AUTH_URL" >> vars/openstack-config.yml
echo "    username: $OS_USERNAME" >> vars/openstack-config.yml
echo "    password: $OS_PASSWORD" >> vars/openstack-config.yml
echo "    project_name: $OS_PROJECT_NAME" >> vars/openstack-config.yml
echo "    project_domain_id: $OS_PROJECT_DOMAIN_ID" >> vars/openstack-config.yml
echo "    user_domain_id: $OS_USER_DOMAIN_ID" >> vars/openstack-config.yml
echo "    tenant_name: $OS_TENANT_NAME" >> vars/openstack-config.yml
echo "image_api_version: $OS_IMAGE_API_VERSION" >> vars/openstack-config.yml
echo "volume_api_version: $OS_VOLUME_API_VERSION" >> vars/openstack-config.yml

SETUPS=("Redhat_Kilo_V2")
TESTS=("Attached_Volume" "Boot_from_Volume")
LAUNCH_TVM=$1
KVM_IP="192.168.10.50"
#Remove old data for the tvault if any
ssh-keygen -f "/root/.ssh/known_hosts" -R $floating_ip

add_ssh_keys()
{
   cd $BASE_DIR
   #Generate SSH key
   ssh-keygen -R $compute_node_ip
   ./copy_ssh_key.expect root $compute_node_password $compute_node_ip
   if [ $? -ne 0 ]
   then
     exit 1
   fi

   ssh-keygen -R $controller_node_ip
   ./copy_ssh_key.expect root $controller_node_password $controller_node_ip
   if [ $? -ne 0 ]
   then
     exit 1
   fi
}

launch_tvm()
{
   ./copy_ssh_key.expect root "Password1!" $KVM_IP
   ssh -q -o "StrictHostKeyChecking no" root@$KVM_IP TVAULT_NAME=$TVAULT_NAME TVAULT_IP=$TVAULT_IP TVAULT_VERSION=$TVAULTBUILD_NUMBER IP_COUNT=$TVAULTS_COUNT 'bash -s' < setTvmOnKvm.sh
   if [ $? -ne 0 ]
   then
     echo "Build deployment step failed, please launch tvault on kvm manually\n" >> validate-build.log
     exit 1
   else
     echo "Build deployement step sucessfully complete\n" >> validate-build.log
   fi
   #Mount NFS Share
   #if mountpoint -q /mnt/build-vault
   #then
   #  echo "NFS already mounted"
   #else
   #  echo "NFS not mounted. Mounting.."
   #  mkdir -p /mnt/build-vault
   #  mount -t nfs 192.168.1.20:/mnt/build-vault /mnt/build-vault
   #  if [ $? -ne 0 ]
   #  then
   #    echo "Error occured in NFS mount, exiting.."
   #    exit 1
   #  fi
   #fi

   #Copy latest build
   #./copy_build.sh Latest_Build

   #Deploy latest build
   #cd $BASE_DIR/build
   #LATEST_BUILD_FILE=`find "$BASE_DIR/build" -name *.qcow2`
   #cd $BASE_DIR
   #rm -f validate-build.log
   #ansible-playbook deploy_tvault.yml --extra-vars "build_path=$LATEST_BUILD_FILE"
   #if [ $? -ne 0 ]
   #then
   #  echo "Build deployment step failed, please execute ansible script in --vvv mode to get more details\n" >> validate-build.log
   #  exit 1
   #else
   #  echo "Build deployement step sucessfully complete\n" >> validate-build.log
   #fi
   #sleep 3m
   #ssh-keygen -R $floating_ip
   #./copy_ssh_key.expect root $TVAULT_APPLIANCE_PASSWORD $floating_ip
}


#if [ "$LAUNCH_TVM" == "Yes" ]
#then
#  echo "Launching Tvault VM.."
#  launch_tvm
#else
#  echo "Skipping Tvault VM launch.."
#fi

#Perform sanity checks for each of the setups
for SETUP in "${SETUPS[@]}"
do
   TEST_RESULTS_FILE="test_results"
   cd $BASE_DIR
   SETUP_DIR=$BASE_DIR"/"$SETUP
   echo $SETUP
   echo $SETUP_DIR
   TEST_RESULTS_FILE=$TEST_RESULTS_FILE"_"$SETUP
   git checkout ../master-scripts/master-install.sh
   sed -i '/TEST_RESULTS_FILE=/c TEST_RESULTS_FILE="$BASE_DIR/../openstack-build-scripts/'$TEST_RESULTS_FILE'"' ../master-scripts/master-install.sh
   sed -i '/sanity_results_file=/c sanity_results_file="'$BASE_DIR'/../openstack-build-scripts/'$TEST_RESULTS_FILE'"' $BASE_DIR/../tempest/tempest/reporting.py
   sed -i '/source/d' $BASE_DIR/../tempest/run_tempest.sh

   rm -f build.properties openstack-auth.sh
   cp $SETUP_DIR/build.properties .
   cp $SETUP_DIR/openstack-auth.sh .
   cp $SETUP_DIR/backup_user_rc .

   sed -i '/floating_ip=/c floating_ip='$floating_ip'' build.properties
   source build.properties
   source openstack-auth.sh
   sed -i '2isource '$SETUP_DIR'/'$TEMPEST_SOURCE_FILE $BASE_DIR/../tempest/run_tempest.sh
   
   #Clean target openstack setup before run sanity/smoke test
   scp backup_user_rc root@$controller_node_ip:/root/
   ssh root@$controller_node_ip ". backup_user_rc; nova list | awk '\$2 && \$2 != "ID" {print \$2}' | xargs -n1 nova delete"
   ssh root@$controller_node_ip ". backup_user_rc; cinder snapshot-list | awk '\$2 && \$2 != "ID" {print \$2}' | xargs -n1 cinder snapshot-delete"
   ssh root@$controller_node_ip ". backup_user_rc; cinder list | awk '\$2 && \$2 != "ID" {print \$2}' | xargs -n1 cinder delete"
   
   ENABLED_TESTS=""
   cnt=0
   for i in "${TESTS[@]}"
   do
      for CINDER in "${CINDER_TYPE[@]}"
      do
         val=$i"_"$CINDER
         if [ $cnt -eq 0 ]
         then
            ENABLED_TESTS="[""\""$val"\""
            cnt=`expr $cnt + 1`
         else
            ENABLED_TESTS=$ENABLED_TESTS",\""$val"\""
         fi
      done
   done
   ENABLED_TESTS=$ENABLED_TESTS"]"

   rm -f $BASE_DIR/../master-scripts/tvault-config.answers $BASE_DIR/../master-scripts/tvault-contego-answers.yml $BASE_DIR/../master-scripts/tvault-horizon-plugin-answers.yml $BASE_DIR/vars/tvault-contego-answers.yml $BASE_DIR/../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
   cp $SETUP_DIR/tvault-config.answers $BASE_DIR/../master-scripts/
   cp $SETUP_DIR/tvault-contego-answers.yml $BASE_DIR/../master-scripts/
   cp $SETUP_DIR/tvault-horizon-plugin-answers.yml $BASE_DIR/../master-scripts/
   cp $SETUP_DIR/configure_vars.yml $BASE_DIR/../master-scripts/tvault-config-ansible-scripts/vars/
   cp $BASE_DIR/../master-scripts/tvault-contego-answers.yml  $BASE_DIR/vars/
   INV_FILE=$SETUP_DIR"/ansible_hosts"
   sed -i '3 a INV_FILE="'$INV_FILE'"' ../master-scripts/master-install.sh
   sed -i 's/tvault-contego-install.yml/tvault-contego-install.yml --inventory-file=$INV_FILE/g' ../master-scripts/master-install.sh
   sed -i 's/contego-service-start.yml/contego-service-start.yml --inventory-file=$INV_FILE/g' ../master-scripts/master-install.sh
   sed -i 's/tvault-horizon-plugin-install.yml/tvault-horizon-plugin-install.yml --inventory-file=$INV_FILE/g' ../master-scripts/master-install.sh

   #Create virtual environment
   #echo "http://$floating_ip:8081/packages/python-workloadmgrclient-$TVAULT_VERSION.tar.gz" >> $BASE_DIR/../tempest/requirements.txt
   #cd $BASE_DIR/../tempest
   #sed -i '/sanity_results_file=/c sanity_results_file="'$BASE_DIR'/../openstack-build-scripts/'$TEST_RESULTS_FILE'"' tempest/reporting.py
   #sed -i '/PASS = /c PASS = "PASSED"' tempest/tvaultconf.py
   #sed -i '/FAIL = /c FAIL = "FAILED"' tempest/tvaultconf.py
   #python tools/install_venv.py
   
   #Need to verify below steps for NFS, Swift - TEMPAUTH, KEYSTONEV2, KEYSTONEV3, S3 - AMAZON, REDHAT CEPH, SUSE CEPH
   for STORAGE in "${STORAGES[@]}"
   do
      cd $BASE_DIR
      if [ "$LAUNCH_TVM" == "Yes" ]
      then
        echo "Launching Tvault VM.."
        TVAULT_NAME="tvault_"$SETUP
        TVAULT_IP=$floating_ip
        TVAULTBUILD_NUMBER=$TVAULT_VERSION
        TVAULTS_COUNT=1
        launch_tvm
      else
        echo "Skipping Tvault VM launch.."
      fi
      
      #Create virtual environment
      echo "http://$floating_ip:8081/packages/python-workloadmgrclient-$TVAULT_VERSION.tar.gz" >> $BASE_DIR/../tempest/requirements.txt
      cd $BASE_DIR/../tempest
      sed -i '/sanity_results_file=/c sanity_results_file="'$BASE_DIR'/../openstack-build-scripts/'$TEST_RESULTS_FILE'"' tempest/reporting.py
      sed -i '/PASS = /c PASS = "PASSED"' tempest/tvaultconf.py
      sed -i '/FAIL = /c FAIL = "FAILED"' tempest/tvaultconf.py
      python tools/install_venv.py
      
      cd $BASE_DIR
      
      echo "---------------------"$STORAGE"--------------------" >> $TEST_RESULTS_FILE
      case "$STORAGE" in
         NFS) sed -i '/backup_target_type=/c backup_target_type=NFS' ../master-scripts/tvault-config.answers
	      sed -i '/backup_target_type: /c backup_target_type: NFS' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
              sed -i '/storage_nfs_export=/c storage_nfs_export='$STORAGE_NFS_EXPORT'' ../master-scripts/tvault-config.answers
	      sed -i '/backup_target_type: /c backup_target_type: NFS' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
              sed -i '/NFS:/c NFS: True' ../master-scripts/tvault-contego-answers.yml
              sed -i '/Swift:/c Swift: False' ../master-scripts/tvault-contego-answers.yml
              sed -i '/^S3:/c S3: False' ../master-scripts/tvault-contego-answers.yml
              sed -i '/NFS_SHARES: /c NFS_SHARES: '$STORAGE_NFS_EXPORT'' ../master-scripts/tvault-contego-answers.yml;;
         SWIFT-KEYSTONEV2) sed -i '/backup_target_type=/c backup_target_type=SWIFT' ../master-scripts/tvault-config.answers
              sed -i '/swift_auth_version/c swift_auth_version=KEYSTONE' ../master-scripts/tvault-config.answers
              sed -i '/NFS:/c NFS: False' ../master-scripts/tvault-contego-answers.yml
              sed -i '/Swift:/c Swift: True' ../master-scripts/tvault-contego-answers.yml
	      sed -i '/^S3:/c S3: False' ../master-scripts/tvault-contego-answers.yml
              sed -i '/VAULT_SWIFT_AUTH_VERSION: /c VAULT_SWIFT_AUTH_VERSION: KEYSTONEV2' ../master-scripts/tvault-contego-answers.yml;;
         SWIFT-KEYSTONEV3) sed -i '/backup_target_type=/c backup_target_type=SWIFT' ../master-scripts/tvault-config.answers
              sed -i '/swift_auth_version/c swift_auth_version=KEYSTONE' ../master-scripts/tvault-config.answers
              sed -i '/NFS:/c NFS: False' ../master-scripts/tvault-contego-answers.yml
              sed -i '/Swift:/c Swift: True' ../master-scripts/tvault-contego-answers.yml
   	      sed -i '/^S3:/c S3: False' ../master-scripts/tvault-contego-answers.yml
              sed -i '/VAULT_SWIFT_AUTH_VERSION: /c VAULT_SWIFT_AUTH_VERSION: KEYSTONEV3' ../master-scripts/tvault-contego-answers.yml;;
         SWIFT-TEMPAUTH) sed -i '/backup_target_type=/c backup_target_type=SWIFT' ../master-scripts/tvault-config.answers
              sed -i '/swift_auth_version/c swift_auth_version=TEMPAUTH' ../master-scripts/tvault-config.answers
              sed -i '/swift_auth_url/c swift_auth_url='$SWIFT_AUTH_URL'' ../master-scripts/tvault-config.answers
              sed -i '/swift_username/c swift_username='$SWIFT_USERNAME'' ../master-scripts/tvault-config.answers
              sed -i '/swift_password/c swift_password='$SWIFT_PASSWORD'' ../master-scripts/tvault-config.answers
              sed -i '/NFS:/c NFS: False' ../master-scripts/tvault-contego-answers.yml
              sed -i '/Swift:/c Swift: True' ../master-scripts/tvault-contego-answers.yml
 	      sed -i '/^S3:/c S3: False' ../master-scripts/tvault-contego-answers.yml
              sed -i '/VAULT_SWIFT_AUTH_VERSION: /c VAULT_SWIFT_AUTH_VERSION: TEMPAUTH' ../master-scripts/tvault-contego-answers.yml
              sed -i '/VAULT_SWIFT_AUTH_URL: /c VAULT_SWIFT_AUTH_URL: '$SWIFT_AUTH_URL'' ../master-scripts/tvault-contego-answers.yml
              sed -i '/VAULT_SWIFT_USERNAME: /c VAULT_SWIFT_USERNAME: '$SWIFT_USERNAME'' ../master-scripts/tvault-contego-answers.yml
              sed -i '/VAULT_SWIFT_PASSWORD: /c VAULT_SWIFT_PASSWORD: '$SWIFT_PASSWORD'' ../master-scripts/tvault-contego-answers.yml;;
         S3-AMAZON) sed -i '/backup_target_type=/c backup_target_type=S3' ../master-scripts/tvault-config.answers
	      sed -i '/backup_target_type: /c backup_target_type: S3' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
	      sed -i '/s3_type: /c s3_type: AMAZON' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
	      sed -i '/s3_type=/c s3_type=AMAZON' ../master-scripts/tvault-config.answers
	      sed -i '/s3_access_key=/c s3_access_key='$S3_ACCESS_KEY'' ../master-scripts/tvault-config.answers
	      sed -i '/s3_secret_key=/c s3_secret_key='$S3_SECRET_KEY'' ../master-scripts/tvault-config.answers
	      sed -i '/s3_bucket=/c s3_bucket='$S3_BUCKET'' ../master-scripts/tvault-config.answers
	      sed -i '/s3_region_name=/c s3_region_name='$S3_REGION_NAME'' ../master-scripts/tvault-config.answers
	      sed -i '/backup_target_type: /c backup_target_type: S3' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
	      sed -i '/s3_type: /c s3_type: AMAZON' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
              sed -i '/NFS:/c NFS: False' ../master-scripts/tvault-contego-answers.yml
              sed -i '/Swift:/c Swift: False' ../master-scripts/tvault-contego-answers.yml
	      sed -i '/^S3:/c S3: True' ../master-scripts/tvault-contego-answers.yml
	      sed -i '/VAULT_S3_ACCESS_KEY:/c VAULT_S3_ACCESS_KEY: '$S3_ACCESS_KEY'' ../master-scripts/tvault-contego-answers.yml
	      sed -i '/VAULT_S3_SECRET_ACCESS_KEY:/c VAULT_S3_SECRET_ACCESS_KEY: '$S3_SECRET_KEY'' ../master-scripts/tvault-contego-answers.yml
              sed -i '/VAULT_S3_REGION_NAME:/c VAULT_S3_REGION_NAME: '$S3_REGION_NAME'' ../master-scripts/tvault-contego-answers.yml
	      sed -i '/VAULT_S3_BUCKET:/c VAULT_S3_BUCKET: '$S3_BUCKET'' ../master-scripts/tvault-contego-answers.yml
	      sed -i '/Amazon:/c Amazon: True' ../master-scripts/tvault-contego-answers.yml
	      sed -i '/Ceph_S3:/c Ceph_S3: False' ../master-scripts/tvault-contego-answers.yml;;
         S3-REDHAT-CEPH) sed -i '/backup_target_type=/c backup_target_type=S3' ../master-scripts/tvault-config.answers
	      sed -i '/backup_target_type: /c backup_target_type: S3' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
	      sed -i '/s3_type: /c s3_type: REDHAT_CEPH' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
              sed -i '/s3_type=/c s3_type=REDHAT_CEPH' ../master-scripts/tvault-config.answers
              sed -i '/s3_access_key=/c s3_access_key='$REDHAT_S3_ACCESS_KEY'' ../master-scripts/tvault-config.answers
              sed -i '/s3_secret_key=/c s3_secret_key='$REDHAT_S3_SECRET_KEY'' ../master-scripts/tvault-config.answers
              sed -i '/s3_bucket=/c s3_bucket='$REDHAT_S3_BUCKET'' ../master-scripts/tvault-config.answers
              sed -i '/s3_endpoint_url=/c s3_endpoint_url='$REDHAT_S3_ENDPOINT_URL'' ../master-scripts/tvault-config.answers

	      sed -i '/s3_access_key=/c s3_access_key='$REDHAT_S3_ACCESS_KEY'' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
              sed -i '/s3_secret_key=/c s3_secret_key='$REDHAT_S3_SECRET_KEY'' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
              sed -i '/s3_bucket=/c s3_bucket='$REDHAT_S3_BUCKET'' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
              sed -i '/s3_endpoint_url=/c s3_endpoint_url='$REDHAT_S3_ENDPOINT_URL'' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
	      sed -i '/s3_access_key: /c s3_access_key: '$REDHAT_S3_ACCESS_KEY'' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
              sed -i '/s3_secret_key: /c s3_secret_key: '$REDHAT_S3_SECRET_KEY'' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
              sed -i '/s3_bucket: /c s3_bucket: '$REDHAT_S3_BUCKET'' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
	      sed -i '/s3_endpoint_url: /c s3_endpoint_url: '$REDHAT_S3_ENDPOINT_URL'' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml

	      sed -i '/backup_target_type: /c backup_target_type: S3' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
	      sed -i '/s3_type: /c s3_type: REDHAT_CEPH' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
              sed -i '/NFS:/c NFS: False' ../master-scripts/tvault-contego-answers.yml
              sed -i '/Swift:/c Swift: False' ../master-scripts/tvault-contego-answers.yml
              sed -i '/^S3:/c S3: True' ../master-scripts/tvault-contego-answers.yml
              sed -i '/VAULT_S3_ACCESS_KEY:/c VAULT_S3_ACCESS_KEY: '$REDHAT_S3_ACCESS_KEY'' ../master-scripts/tvault-contego-answers.yml
              sed -i '/VAULT_S3_SECRET_ACCESS_KEY:/c VAULT_S3_SECRET_ACCESS_KEY: '$REDHAT_S3_SECRET_KEY'' ../master-scripts/tvault-contego-answers.yml
              sed -i '/VAULT_S3_ENDPOINT_URL:/c VAULT_S3_ENDPOINT_URL: '$REDHAT_S3_ENDPOINT_URL'' ../master-scripts/tvault-contego-answers.yml
              sed -i '/VAULT_S3_BUCKET:/c VAULT_S3_BUCKET: '$REDHAT_S3_BUCKET'' ../master-scripts/tvault-contego-answers.yml
              sed -i '/Amazon:/c Amazon: False' ../master-scripts/tvault-contego-answers.yml
              sed -i '/Ceph_S3:/c Ceph_S3: True' ../master-scripts/tvault-contego-answers.yml;;

      esac
      sleep 5s
      LOG_DIR=$BASE_DIR/$SETUP/$STORAGE"-logs"
      rm -rf $LOG_DIR
      mkdir -p $LOG_DIR

      case "$SETUP" in
         Redhat_Kilo_V2) EDIT_CONTEGO=0
                         ADD_SSH_KEYS=1;;

         Redhat_Liberty_V3|Redhat_Mitaka_V2|Redhat_Newton_V2|Redhat_Queens_V3|Ubuntu_Queens_V3) EDIT_CONTEGO=1
                         ADD_SSH_KEYS=1;;

         Redhat_Ocata_V2) EDIT_CONTEGO=0
                         ADD_SSH_KEYS=1;;

         Mirantis_Mitaka_V2_Ceph) EDIT_CONTEGO=0
                         ADD_SSH_KEYS=0;;

         Canonical_Newton_V3) EDIT_CONTEGO=0
                         ADD_SSH_KEYS=1;;

         Suse_Cloud7) EDIT_CONTEGO=0
                      ADD_SSH_KEYS=0;;

      esac


      if [ $ADD_SSH_KEYS -eq 1 ]
      then
        add_ssh_keys
      fi

      #Uninstall existing Tvault-contego
      cd $BASE_DIR
      ansible-playbook tvault-contego-uninstall.yml --inventory-file=$INV_FILE
      if [ $? -ne 0 ]
      then
        echo -e "Uninstall existing tvault-contego failed\n"
        echo "Uninstall_existing_contego FAILED" >> $TEST_RESULTS_FILE
        continue
      fi
      sleep 10s

      ssh root@$controller_node_ip 'mysqladmin flush-hosts'
      #Tvault configuration and installation
      cd ../master-scripts
      ./master-install.sh --config
      if [ $? -ne 0 ]
      then
        echo -e "Tvault configuration failed, exiting..\n"
        #Copy log files to local machine
        cd $BASE_DIR
        ./copy_logs.sh $floating_ip $TVAULT_APPLIANCE_PASSWORD /var/log/upstart/ $LOG_DIR
        ./copy_logs.sh $floating_ip $TVAULT_APPLIANCE_PASSWORD /var/log/workloadmgr/ $LOG_DIR
        continue
      fi

      case "$SETUP" in
         Redhat_Kilo_V2) ssh root@$floating_ip "sed -i '/glance_api_version/c glance_api_version = 1' /etc/workloadmgr/workloadmgr.conf"
		         ssh root@$floating_ip 'service wlm-api restart' 
		 	 ssh root@$floating_ip 'service wlm-scheduler restart'
		 	 ssh root@$floating_ip 'service wlm-workloads restart'
			 ssh root@$compute_node_ip 'service openstack-nova-compute restart';;

	 Redhat_Liberty_V3|Redhat_Mitaka_V2|Redhat_Newton_V2|Redhat_Ocata_V2|Redhat_Queens_V3) ssh root@$compute_node_ip 'service openstack-nova-compute restart';;

	 Mirantis_Mitaka_V2_Ceph|Canonical_Newton_V3) ssh root@$compute_node_ip 'service nova-compute restart';;

         Suse_Cloud7) ssh root@$compute_node_ip 'service openstack-nova-compute restart';;

      esac

      cd ../master-scripts
      ./master-install.sh --contego
      if [ $? -ne 0 ]
      then
        echo -e "Tvault contego failed, exiting..\n"
        continue
      fi

      if [ $EDIT_CONTEGO -eq 1 ]
      then
	ssh root@$compute_node_ip 'echo "[libvirt]" >> /etc/tvault-contego/tvault-contego.conf'
        ssh root@$compute_node_ip 'echo "images_rbd_ceph_conf = /etc/ceph/ceph.conf" >> /etc/tvault-contego/tvault-contego.conf'
        ssh root@$compute_node_ip 'echo "rbd_user = cinder" >> /etc/tvault-contego/tvault-contego.conf'
        ssh root@$compute_node_ip 'service tvault-contego restart'
	sleep 20s
	ssh root@$compute_node_ip 'service tvault-contego restart'
      fi

      cd ../master-scripts
      ./master-install.sh --horizon
      if [ $? -ne 0 ]
      then
        echo -e "Tvault horizon failed, exiting..\n"
        continue
      fi
      sleep 5s

      cd $BASE_DIR
      ./setTempestEnv.sh $SETUP
      sed -i '/enabled_tests =/c enabled_tests = '$ENABLED_TESTS'' $BASE_DIR/../tempest/tempest/tvaultconf.py
      rm -rf /opt/lock

      cd $BASE_DIR/../tempest
      ./run_tempest.sh tempest.api.workloadmgr.license.test_create_license
      if [ $? -ne 0 ]
      then
         echo "Error applying license, exiting\n"
         echo "Apply_License FAILED" >> $BASE_DIR/../openstack-build-scripts/$TEST_RESULTS_FILE
         continue
      else
         echo "Apply_License PASSED" >> $BASE_DIR/../openstack-build-scripts/$TEST_RESULTS_FILE
      fi
      mv tempest.log tempest_license_$STORAGE.log
      mv tempest*.log $LOG_DIR
      
      rm -rf /opt/lock
      ./run_tempest.sh tempest.api.workloadmgr.sanity.test_create_full_snapshot
      mv tempest.log $LOG_DIR

      cd $BASE_DIR
      ./copy_logs.sh $compute_node_ip $compute_node_password /var/log/nova/tvault-contego.log $LOG_DIR
      ./copy_logs.sh $compute_node_ip $compute_node_password /var/log/nova/nova-api.log $LOG_DIR
   
      #ssh -q -o "StrictHostKeyChecking no" root@$KVM_IP "virsh destroy ${TVAULT_NAME}_1"
      #sleep 2m
      #ssh -q -o "StrictHostKeyChecking no" root@$KVM_IP "virsh undefine ${TVAULT_NAME}_1"
      ssh -q -o "StrictHostKeyChecking no" root@$KVM_IP 'rm -rf /var/lib/libvirt/images/$TVAULT_NAME/'
      ssh -q -o "StrictHostKeyChecking no" root@$KVM_IP 'rm -rf /home/build/$TVAULT_NAME/'
      ssh -q -o "StrictHostKeyChecking no" root@$KVM_IP 'free && sync && echo 3 > /proc/sys/vm/drop_caches && free'
   done
done

cd $BASE_DIR
python sanity_report.py $TVAULT_VERSION $floating_ip
if [ $? -ne 0 ]
then
   echo "Unable to create sanity test report"
   exit 1
else
   echo "Sanity test report created"
fi
