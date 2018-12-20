#!/bin/bash -x

BASE_DIR="$(pwd)"

rm -f build.properties openstack-auth.sh /etc/ansible/hosts
cp build_setup/build.properties .
cp build_setup/openstack-auth.sh .
cp $BASE_DIR/build_setup/ansible_hosts /etc/ansible/
mv /etc/ansible/ansible_hosts /etc/ansible/hosts
sed -i '/TVAULT_SNAPSHOT_NAME=/c TVAULT_SNAPSHOT_NAME="tvault-build-vm-snapshot-dev"' build.properties
sed -i '/tvault_vm_name=/c tvault_vm_name=tvault-build-vm-dev' build.properties
sed -i '/image_name=/c image_name=tvault-build-img-dev' build.properties
sed -i '/key_name=/c key_name=tvault-test-key-dev' build.properties
sed -i '/security_group_name=/c security_group_name=tvault-build-secgrp-dev' build.properties


#exec >& $BASE_DIR/buildTVault.log
source build.properties
source openstack-auth.sh

if [ ! -d $BASE_DIR/vars ]; then
   mkdir -p $BASE_DIR/vars
fi
echo "flavor_name: $flavor_name" > vars/tvault-config.yml
echo "tvault_vm_name: $tvault_vm_name" >> vars/tvault-config.yml
echo "image_name: $image_name" >> vars/tvault-config.yml
echo "security_group_name: $security_group_name" >> vars/tvault-config.yml
echo "key_name: $key_name" >> vars/tvault-config.yml
echo "fixed_network_id: $fixed_network_id" >> vars/tvault-config.yml
echo "floating_ip: $floating_ip" >> vars/tvault-config.yml
echo "old_build_file: $OLD_BUILD_FILE" >> vars/tvault-config.yml
echo "git_branch_contego: $git_branch_contego" >> vars/tvault-config.yml
echo "git_branch_horizon: $git_branch_horizon" >> vars/tvault-config.yml
echo "git_branch_workloadmgr: $git_branch_workloadmgr" >> vars/tvault-config.yml
echo "git_branch_workloadmgr_client: $git_branch_workloadmgr_client" >> vars/tvault-config.yml
echo "git_branch_contegoclient: $git_branch_contegoclient" >> vars/tvault-config.yml
echo "client_git_branch: $client_git_branch" >> vars/tvault-config.yml
echo "dev_username: $DEV_USERNAME" >> vars/tvault-config.yml
echo "TVAULT_VERSION: $TVAULT_VERSION" >> vars/tvault-config.yml
echo "tvault_passwd: $TVAULT_APPLIANCE_PASSWORD" >> vars/tvault-config.yml
echo "old_branch: $old_branch" >> vars/tvault-config.yml

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

OLD_BUILD_FILE="$BASE_DIR$OLD_BUILD_FILE"
TEST_RESULTS_FILE="$BASE_DIR/test_results"

#Clean old files
rm -f $TEST_RESULTS_FILE

#Mount NFS share
if mountpoint -q /mnt/build-vault
then
   echo "NFS already mounted"
else
   echo "NFS not mounted. Mounting.."
   mkdir -p /mnt/build-vault
   mount -t nfs 192.168.1.20:/mnt/build-vault /mnt/build-vault
   if [ $? -ne 0 ]
   then
     echo "Mount NFS share failed, exiting.."
     exit 1
   fi
fi

#Remove old repos
rm -rf $BASE_DIR/horizon-tvault-plugin
rm -rf $BASE_DIR/contego
rm -rf $BASE_DIR/python-workloadmgrclient
rm -rf $BASE_DIR/workloadmgr
rm -rf $BASE_DIR/contegoclient
echo -e "Removed old repositories \n"

##Checkout latest code
git clone git@github.com:${DEV_USERNAME}/horizon-tvault-plugin.git
git clone git@github.com:${DEV_USERNAME}/contego.git
git clone git@github.com:${DEV_USERNAME}/workloadmanager-client.git python-workloadmgrclient
git clone git@github.com:${DEV_USERNAME}/workloadmanager.git workloadmgr
git clone git@github.com:${DEV_USERNAME}/contegoclient.git
echo -e "Cloned all repositories \n"

##Create ansible script's bundle
rm -rf $BASE_DIR/automation
cd $BASE_DIR 
rm -f tvault-ansible-scripts* 
rm -f validate-build.log
git clone -b ${old_branch} git@github.com:trilioData/automation.git
cd automation/
mv master-scripts tvault-ansible-scripts-${TVAULT_VERSION}
tar -czf tvault-ansible-scripts-${TVAULT_VERSION}.tar.gz tvault-ansible-scripts-${TVAULT_VERSION}
mv tvault-ansible-scripts-${TVAULT_VERSION}.tar.gz ../
cd $BASE_DIR

#Copy old build
./copy_build.sh Ubuntu16

#Deploy Ubuntu16 instance
ansible-playbook deploy_tvault.yml --extra-vars "build_path=$OLD_BUILD_FILE"
if [ $? -ne 0 ]
then
 echo "Deploy_Old_Build FAILED" >> $TEST_STEP_RESULTS_FILE
 exit 1
fi
sleep 4m

ping -c 3 $floating_ip > /dev/null 2>&1
if [ $? -ne 0 ]
then
  echo -e "tVault appliance is not up yet, sleeping for 2 more minutes\n"
  sleep 2m
  ping -c 3 $floating_ip > /dev/null 2>&1
  if [ $? -ne 0 ]
  then
    echo "tVault appliance is not getting up, exiting...\n"
    exit 1
  fi
fi

ssh-keygen -R $floating_ip
cert_file=$BASE_DIR/vars/$key_name
ssh -q -o "StrictHostKeyChecking no" -i $cert_file ubuntu@$floating_ip 'bash -s' < setupTVault.sh
if [ $? -ne 0 ]
then
 exit 1
fi

./copy_ssh_key.expect root $TVAULT_APPLIANCE_PASSWORD $floating_ip
if [ $? -ne 0 ]
then
 exit 1
fi

ansible-playbook  git_auth_setup.yml --extra-vars "host=$floating_ip"
if [ $? -ne 0 ]
then
 exit 1
fi

ansible-playbook update_repos_dev.yml --extra-vars "host=$floating_ip"
if [ $? -ne 0 ]
then
 exit 1
fi

##Clean unwanted files, directories
ssh root@$floating_ip 'bash -s' < cleanTVault.sh
sleep 15s

##Take snapshot of TVM
nova image-create $tvault_vm_name $TVAULT_SNAPSHOT_NAME --poll
if [ $? -ne 0 ]
then
 exit 1
fi

##Create qcow2 file of TVM snapshot
export TVAULT_IMAGE_ID=`glance image-list | grep $TVAULT_SNAPSHOT_NAME | tail -1 | awk '{print $2;}'`
if [ $? -ne 0 ]
then
 exit 1
fi
TVAULT_BUILD_NAME=tvault-appliance-os-${DEV_USERNAME}-${TVAULT_VERSION}-${FEATURE_NAME}.qcow2
rm -rf build
mkdir build
cd build
qemu-img convert -o compat=0.10 -t none -O qcow2 ${GLANCE_STORE}/${TVAULT_IMAGE_ID} ${TVAULT_BUILD_NAME}
if [ $? -ne 0 ]
then
 exit 1
fi
#virt-sysprep -a ${TVAULT_BUILD_NAME}
virt-sysprep --enable yum-uuid,utmp,udev-persistent-net,tmp-files,sssd-db-log,smolt-uuid,script,samba-db-log,rpm-db,rhn-systemid,random-seed,puppet-data-log,password,pam-data,package-manager-cache,pacct-log,net-hwaddr,net-hostname,mail-spool,machine-id,logfiles,hostname,firstboot,dovecot-data,dhcp-server-state,dhcp-client-state,cron-spool,crash-data,blkid-tab,bash-history,abrt-data,lvm-uuids -a ${TVAULT_BUILD_NAME}
if [ $? -ne 0 ]
then
 exit 1
fi

##Compress qcow2 build file
tar -zcvf ${TVAULT_BUILD_NAME}.tar.gz ${TVAULT_BUILD_NAME}
if [ $? -ne 0 ]
then
 echo "Create_New_Build FAILED, exiting..\n"
 exit 1
fi

##Clean local ansible bundle
cd $BASE_DIR/
rm -rf tvault-ansible-scripts*
rm -rf automation
rm -rf contego/ contegoclient/ horizon-tvault-plugin/ python-workloadmgrclient/ workloadmgr/

##Upload build
if [ $? -eq 0 ]
then
 echo "Latest build created successfully, Build file: $BASE_DIR/build/${TVAULT_BUILD_NAME}.tar.gz"
 cd $BASE_DIR
 cd $BASE_DIR/build
 CURRENT_DIR=`pwd`
 LATEST_BUILD=`find "$CURRENT_DIR" -name *.gz`
 cp $LATEST_BUILD /mnt/build-vault/dev-builds/
 drive upload -p $DRIVE_LOCATION -f $LATEST_BUILD >  ../build_upload.log
 if [ $? -eq 0 ]
 then
   rm -f $LATEST_BUILD_FILE
   cd $BASE_DIR/
   GOOGLE_DRIVE_ID=`cat build_upload.log | grep Id | awk '{print $2}'`
   cat build_ids | grep $TVAULT_VERSION
   if [ $? -eq 0 ]; then
      sed -i "s/$TVAULT_VERSION.*/$TVAULT_VERSION $GOOGLE_DRIVE_ID/g" build_ids
   else
      echo "$TVAULT_VERSION $GOOGLE_DRIVE_ID" >> build_ids
   fi
   ./send_mail_dev.py 0 $TVAULT_BUILD_NAME $DEV_EMAIL $GOOGLE_DRIVE_ID $DEV_USERNAME
 fi
 glance image-delete ${TVAULT_IMAGE_ID}
else
 echo "Latest dev build creation failed"
 ./send_mail_dev.py 1 $TVAULT_BUILD_NAME $DEV_EMAIL
 glance image-delete ${TVAULT_IMAGE_ID}
 exit 1
fi

##Clean local ansible bundle
cd $BASE_DIR/
rm -rf tvault-ansible-scripts*
rm -rf automation
rm -rf contego/ contegoclient/ horizon-tvault-plugin/ python-workloadmgrclient/ workloadmgr/

export TVAULT_INSTANCE_ID=`nova list | grep $floating_ip | tail -1 | awk '{print $2;}'`
nova delete ${TVAULT_INSTANCE_ID}
