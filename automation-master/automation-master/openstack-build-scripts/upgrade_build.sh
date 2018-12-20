#!/bin/bash -x

LAUNCH=$1
CONFIGURE=$2

BASE_DIR=$PWD
ENV_DIR=$BASE_DIR/../deployment-scripts/environments

generate_ssh_key()
{
   #Generate SSH key
   ssh-keygen -R $controller_node_ip
   sleep 5s

   ./copy_ssh_key.expect root $controller_node_password $controller_node_ip
   if [ $? -ne 0 ]
   then
     exit 1
   fi
   sleep 5s

   ssh-keygen -R $compute_node_ip
   sleep 5s

   ./copy_ssh_key.expect root $compute_node_password $compute_node_ip
   if [ $? -ne 0 ]
   then
     exit 1
   fi
   sleep 5s
}

launch_tvm()
{
   rm -f openstack-auth.sh build.properties
   cp $ENV_DIR/${TVM_LAUNCH_SETUP}/openstack-auth.sh .
   cp $ENV_DIR/${TVM_LAUNCH_SETUP}/build.properties .

   source build.properties
   source openstack-auth.sh

   #Mount NFS Share
   if mountpoint -q /mnt/build-vault
   then
      echo "NFS already mounted"
   else
      echo "NFS not mounted. Mounting.."
      mkdir -p /mnt/build-vault
      mount -t nfs 192.168.1.20:/mnt/build-vault /mnt/build-vault
      if [ $? -ne 0 ]
      then
        echo "Error occured in NFS mount, exiting.."
        exit 1
      fi
   fi

   if [ "$TVAULTBUILD_NUMBER" == "" ]
   then
      TVAULT_BUILD_NUMBER=`ls /mnt/build-vault/${GIT_BRANCH_NAME}/latest/ | cut -f 4 -d '-' | cut -f 1,2,3 -d '.'`
   else
      TVAULT_BUILD_NUMBER=$TVAULTBUILD_NUMBER
   fi
   echo $TVAULT_BUILD_NUMBER

   generate_ssh_key

   sed -i '/floating_ip=/c floating_ip='$TVAULT_IP'' build.properties
   sed -i '/git_branch=/c git_branch='$GIT_BRANCH_NAME'' build.properties
   sed -i '/TVAULT_VERSION=/c TVAULT_VERSION='$TVAULT_BUILD_NUMBER'' build.properties
   sed -i '/flavor_name=tvault/c flavor_name=tvault-test-flavor-'$BUILD_USER_ID build.properties
   sed -i '/tvault_vm_name=/c tvault_vm_name=tvault-test-vm-'$BUILD_USER_ID build.properties
   sed -i '/image_name=tvault/c image_name=tvault-test-img-'$BUILD_USER_ID'-'$TVAULT_BUILD_NUMBER'' build.properties
   sed -i '/security_group_name=/c security_group_name=tvault-test-secgrp-'$BUILD_USER_ID build.properties
   INV_FILE=$ENV_DIR"/"$TVM_LAUNCH_SETUP"/ansible_hosts"
   sed -i '/ansible_inventory_file=/c ansible_inventory_file="'$INV_FILE'"' build.properties

   ./setTestEnv.sh
   if [ $? -ne 0 ]
   then
      exit 1
   fi
}

configure_tvault()
{
   if [[ $SETUP_NAME == *"Automation"* ]]
   then
      SETUP_NAME1=`echo $SETUP_NAME | sed -e 's/_Automation//g'`
   else
      SETUP_NAME1=$SETUP_NAME
   fi

   SETUP_DIR=$ENV_DIR"/"$SETUP_NAME1
   rm -f $BASE_DIR/openstack-auth.sh build.properties
   cp $SETUP_DIR/openstack-auth.sh .
   cp $SETUP_DIR/build.properties .

   rm -f $BASE_DIR/../master-scripts/tvault-config.answers $BASE_DIR/../master-scripts/tvault-contego-answers.yml 
   rm -f $BASE_DIR/../master-scripts/tvault-horizon-plugin-answers.yml $BASE_DIR/vars/tvault-contego-answers.yml
   cp $SETUP_DIR/tvault-config.answers $BASE_DIR/../master-scripts/
   cp $SETUP_DIR/configure_vars.yml $BASE_DIR/../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
   cp $SETUP_DIR/tvault-contego-answers.yml $BASE_DIR/../master-scripts/
   cp $SETUP_DIR/tvault-horizon-plugin-answers.yml $BASE_DIR/../master-scripts/
   cp $BASE_DIR/../master-scripts/tvault-contego-answers.yml  $BASE_DIR/vars/
   cp $SETUP_DIR/ansible_hosts /etc/ansible
   mv /etc/ansible/ansible_hosts /etc/ansible/hosts
   #INV_FILE=$SETUP_DIR"/ansible_hosts"
   INV_FILE="/etc/ansible/hosts"
   sed -i '3 a INV_FILE="'$INV_FILE'"' ../master-scripts/master-install.sh
   sed -i 's/tvault-contego-install.yml/tvault-contego-install.yml --inventory-file=$INV_FILE/g' ../master-scripts/master-install.sh
   sed -i 's/contego-service-start.yml/contego-service-start.yml --inventory-file=$INV_FILE/g' ../master-scripts/master-install.sh
   sed -i 's/tvault-horizon-plugin-install.yml/tvault-horizon-plugin-install.yml --inventory-file=$INV_FILE/g' ../master-scripts/master-install.sh

   sed -i '/floating_ip=/c floating_ip='$TVAULT_IP'' build.properties
   sed -i '/git_branch=/c git_branch='$GIT_BRANCH_NAME'' build.properties
   sed -i '/TVAULT_VERSION=/c TVAULT_VERSION='$TVAULT_BUILD_NUMBER'' build.properties
   
   sed -i '/configurator_node_ip: /c configurator_node_ip: '$TVAULT_IP'' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
   sed -i '/controller_nodes: /c controller_nodes: \"'$TVAULT_IP=tvm1'\"' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
   sed -i '/virtual_ip: /c virtual_ip: \"'$VIRTUAL_IP/16'\"' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
   
   sed -i '/controller_node_ip=/c controller_node_ip='$TVAULT_IP'' ../master-scripts/tvault-config.answers

   sed -i '/IP_ADDRESS: /c IP_ADDRESS: '$TVAULT_IP'' ../master-scripts/tvault-contego-answers.yml

   sed -i '/TVAULTAPP: /c TVAULTAPP: '$TVAULT_IP'' ../master-scripts/tvault-horizon-plugin-answers.yml

   case "$STORAGE" in
     NFS) sed -i '/backup_target_type=/c backup_target_type=NFS' ../master-scripts/tvault-config.answers
     sed -i '/storage_nfs_export=/c storage_nfs_export='$STORAGE_NFS_EXPORT'' ../master-scripts/tvault-config.answers
     sed -i '/swift_auth_version/c swift_auth_version=' ../master-scripts/tvault-config.answers
     sed -i '/swift_auth_url/c swift_auth_url=' ../master-scripts/tvault-config.answers
     sed -i '/swift_username/c swift_username=' ../master-scripts/tvault-config.answers
     sed -i '/swift_password/c swift_password=' ../master-scripts/tvault-config.answers
     sed -i '/backup_target_type: /c backup_target_type: NFS' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
     sed -i '/NFS:/c NFS: True' ../master-scripts/tvault-contego-answers.yml
     sed -i '/^S3:/c S3: False' ../master-scripts/tvault-contego-answers.yml
     sed -i '/Swift:/c Swift: False' ../master-scripts/tvault-contego-answers.yml
     sed -i '/NFS_SHARES: /c NFS_SHARES: '$STORAGE_NFS_EXPORT'' ../master-scripts/tvault-contego-answers.yml
     sed -i '/VAULT_SWIFT_AUTH_VERSION: /c VAULT_SWIFT_AUTH_VERSION: ' ../master-scripts/tvault-contego-answers.yml
     sed -i '/VAULT_SWIFT_AUTH_URL: /c VAULT_SWIFT_AUTH_URL: ' ../master-scripts/tvault-contego-answers.yml
     sed -i '/VAULT_SWIFT_USERNAME: /c VAULT_SWIFT_USERNAME: ' ../master-scripts/tvault-contego-answers.yml
     sed -i '/VAULT_SWIFT_PASSWORD: /c VAULT_SWIFT_PASSWORD: ' ../master-scripts/tvault-contego-answers.yml;;
     SWIFT-KEYSTONEV2) sed -i '/backup_target_type=/c backup_target_type=SWIFT' ../master-scripts/tvault-config.answers
     sed -i '/storage_nfs_export=/c storage_nfs_export=' ../master-scripts/tvault-config.answers
     sed -i '/swift_auth_version/c swift_auth_version=KEYSTONE' ../master-scripts/tvault-config.answers
     sed -i '/swift_auth_url/c swift_auth_url=' ../master-scripts/tvault-config.answers
     sed -i '/swift_username/c swift_username=' ../master-scripts/tvault-config.answers
     sed -i '/swift_password/c swift_password=' ../master-scripts/tvault-config.answers
     sed -i '/NFS:/c NFS: False' ../master-scripts/tvault-contego-answers.yml
     sed -i '/Swift:/c Swift: True' ../master-scripts/tvault-contego-answers.yml
     sed -i '/NFS_SHARES: /c NFS_SHARES: ' ../master-scripts/tvault-contego-answers.yml
     sed -i '/VAULT_SWIFT_AUTH_VERSION: /c VAULT_SWIFT_AUTH_VERSION: KEYSTONEV2' ../master-scripts/tvault-contego-answers.yml
     sed -i '/VAULT_SWIFT_AUTH_URL: /c VAULT_SWIFT_AUTH_URL: ' ../master-scripts/tvault-contego-answers.yml
     sed -i '/VAULT_SWIFT_USERNAME: /c VAULT_SWIFT_USERNAME: ' ../master-scripts/tvault-contego-answers.yml
     sed -i '/VAULT_SWIFT_PASSWORD: /c VAULT_SWIFT_PASSWORD: ' ../master-scripts/tvault-contego-answers.yml;;
     SWIFT-KEYSTONEV3) sed -i '/backup_target_type=/c backup_target_type=SWIFT' ../master-scripts/tvault-config.answers
     sed -i '/storage_nfs_export=/c storage_nfs_export=' ../master-scripts/tvault-config.answers
     sed -i '/swift_auth_version/c swift_auth_version=KEYSTONE' ../master-scripts/tvault-config.answers
     sed -i '/swift_auth_url/c swift_auth_url=' ../master-scripts/tvault-config.answers
     sed -i '/swift_username/c swift_username=' ../master-scripts/tvault-config.answers
     sed -i '/swift_password/c swift_password=' ../master-scripts/tvault-config.answers
     sed -i '/NFS:/c NFS: False' ../master-scripts/tvault-contego-answers.yml
     sed -i '/Swift:/c Swift: True' ../master-scripts/tvault-contego-answers.yml
     sed -i '/NFS_SHARES: /c NFS_SHARES: ' ../master-scripts/tvault-contego-answers.yml
     sed -i '/VAULT_SWIFT_AUTH_VERSION: /c VAULT_SWIFT_AUTH_VERSION: KEYSTONEV3' ../master-scripts/tvault-contego-answers.yml
     sed -i '/VAULT_SWIFT_AUTH_URL: /c VAULT_SWIFT_AUTH_URL: ' ../master-scripts/tvault-contego-answers.yml
     sed -i '/VAULT_SWIFT_USERNAME: /c VAULT_SWIFT_USERNAME: ' ../master-scripts/tvault-contego-answers.yml
     sed -i '/VAULT_SWIFT_PASSWORD: /c VAULT_SWIFT_PASSWORD: ' ../master-scripts/tvault-contego-answers.yml;;
     SWIFT-TEMPAUTH) sed -i '/backup_target_type=/c backup_target_type=SWIFT' ../master-scripts/tvault-config.answers
     sed -i '/storage_nfs_export=/c storage_nfs_export=' ../master-scripts/tvault-config.answers
     sed -i '/swift_auth_version/c swift_auth_version=TEMPAUTH' ../master-scripts/tvault-config.answers
     sed -i '/swift_auth_url/c swift_auth_url='$SWIFT_AUTH_URL'' ../master-scripts/tvault-config.answers
     sed -i '/swift_username/c swift_username='$SWIFT_USERNAME'' ../master-scripts/tvault-config.answers
     sed -i '/swift_password/c swift_password='$SWIFT_PASSWORD'' ../master-scripts/tvault-config.answers
     sed -i '/NFS:/c NFS: False' ../master-scripts/tvault-contego-answers.yml
     sed -i '/Swift:/c Swift: True' ../master-scripts/tvault-contego-answers.yml
     sed -i '/NFS_SHARES: /c NFS_SHARES: ' ../master-scripts/tvault-contego-answers.yml
     sed -i '/VAULT_SWIFT_AUTH_VERSION: /c VAULT_SWIFT_AUTH_VERSION: TEMPAUTH' ../master-scripts/tvault-contego-answers.yml
     sed -i '/VAULT_SWIFT_AUTH_URL: /c VAULT_SWIFT_AUTH_URL: '$SWIFT_AUTH_URL'' ../master-scripts/tvault-contego-answers.yml
     sed -i '/VAULT_SWIFT_USERNAME: /c VAULT_SWIFT_USERNAME: '$SWIFT_USERNAME'' ../master-scripts/tvault-contego-answers.yml
     sed -i '/VAULT_SWIFT_PASSWORD: /c VAULT_SWIFT_PASSWORD: '$SWIFT_PASSWORD'' ../master-scripts/tvault-contego-answers.yml;;
     S3-AMAZON) sed -i '/backup_target_type=/c backup_target_type=S3' ../master-scripts/tvault-config.answers
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
     sed -i '/s3_type=/c s3_type=REDHAT_CEPH' ../master-scripts/tvault-config.answers
     sed -i '/s3_endpoint_url=/c s3_endpoint_url='$REDHAT_S3_ENDPOINT_URL'' ../master-scripts/tvault-config.answers
     sed -i '/s3_access_key=/c s3_access_key='$REDHAT_S3_ACCESS_KEY'' ../master-scripts/tvault-config.answers
     sed -i '/s3_secret_key=/c s3_secret_key='$REDHAT_S3_SECRET_KEY'' ../master-scripts/tvault-config.answers
     sed -i '/s3_bucket=/c s3_bucket='$REDHAT_S3_BUCKET'' ../master-scripts/tvault-config.answers
     sed -i '/backup_target_type: /c backup_target_type: S3' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
	  sed -i '/s3_type: /c s3_type: REDHAT_CEPH' ../master-scripts/tvault-config-ansible-scripts/vars/configure_vars.yml
     sed -i '/NFS:/c NFS: False' ../master-scripts/tvault-contego-answers.yml
     sed -i '/Swift:/c Swift: False' ../master-scripts/tvault-contego-answers.yml
     sed -i '/^S3:/c S3: True' ../master-scripts/tvault-contego-answers.yml
     sed -i '/VAULT_S3_ENDPOINT_URL:/c VAULT_S3_ENDPOINT_URL: '$REDHAT_S3_ENDPOINT_URL'' ../master-scripts/tvault-contego-answers.yml
     sed -i '/VAULT_S3_ACCESS_KEY:/c VAULT_S3_ACCESS_KEY: '$REDHAT_S3_ACCESS_KEY'' ../master-scripts/tvault-contego-answers.yml
     sed -i '/VAULT_S3_SECRET_ACCESS_KEY:/c VAULT_S3_SECRET_ACCESS_KEY: '$REDHAT_S3_SECRET_KEY'' ../master-scripts/tvault-contego-answers.yml
     sed -i '/VAULT_S3_BUCKET:/c VAULT_S3_BUCKET: '$REDHAT_S3_BUCKET'' ../master-scripts/tvault-contego-answers.yml
     sed -i '/Amazon:/c Amazon: False' ../master-scripts/tvault-contego-answers.yml
     sed -i '/Ceph_S3:/c Ceph_S3: True' ../master-scripts/tvault-contego-answers.yml;;
   esac
  
   source build.properties 
   generate_ssh_key

   cd $BASE_DIR  
   cp $BASE_DIR/../master-scripts/tvault-contego-answers.yml  $BASE_DIR/vars/

   #Uninstall existing Tvault-contego
   ansible-playbook tvault-contego-uninstall.yml --inventory-file="$INV_FILE"
   if [ $? -ne 0 ]
   then
     echo -e "Uninstall existing tvault-contego failed, exiting\n" >> $RESULTS_FILE
     exit 1
   else
     echo "Uninstall existing tvault-contego successful"
   fi
  
   cd $BASE_DIR/../master-scripts
   ./master-install.sh --config
   if [ $? -ne 0 ]
   then
      echo "Unable to complete Tvault configuration, exiting..\n" >> $RESULTS_FILE
      exit 1
   else
      echo "Tvault configuration complete.."
   fi

   cd $BASE_DIR/../master-scripts
   ./master-install.sh --contego
   if [ $? -ne 0 ]
   then
      echo "Tvault contego failed, exiting..\n" >> $RESULTS_FILE
      exit 1
   else
      echo "Tvault contego complete.."
   fi

   #Update contego script and restart service if required

   cd $BASE_DIR/../master-scripts
   ./master-install.sh --horizon
   if [ $? -ne 0 ]
   then
      echo "Tvault horizon failed, exiting..\n" >> $RESULTS_FILE
      exit 1
   else
      echo "Tvault horizon complete.."
   fi 

}

if [ $LAUNCH == "1" ]
then
   launch_tvm
else
   echo "Skipping tvault launch.."
fi

if [ $CONFIGURE == "1" ]
then
   configure_tvault
else
   echo "Skipping tvault configuration.."
fi
