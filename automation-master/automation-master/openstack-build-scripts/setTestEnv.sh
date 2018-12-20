#!/bin/bash -x

BASE_DIR="$(pwd)"

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
TEST_RESULTS_FILE="$BASE_DIR/test_results"

#Clean old files
rm -rf $TEST_RESULTS_FILE

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

##Download latest build
./copy_build.sh Latest_Build

#Deploy latest build
cd $BASE_DIR/build
CURRENT_DIR=`pwd`
LATEST_BUILD_TAR=`find "$CURRENT_DIR" -name *.qcow2.tar.gz`
tar -xvzf $LATEST_BUILD_TAR
LATEST_BUILD_FILE=`find "$CURRENT_DIR" -name *.qcow2`

cd $BASE_DIR
rm -f setTestEnv.log
ansible-playbook deploy_tvault.yml --extra-vars "build_path=$LATEST_BUILD_FILE" --inventory-file=$ansible_inventory_file
if [ $? -ne 0 ]
then
   echo "Unable to launch tvault, exiting\n"
   exit 1
fi
sleep 3m

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

#Check if Tvault landing page is accessible
cnt=0
flag=False
while [ $cnt -lt 10 ]
do
  curl -k 'https://'"${floating_ip}"'/landing_page_openstack'
  if [ $? -ne 0 ]
  then
    echo -e "tVault appliance is not up yet, sleeping for 2 more minutes\n"
    sleep 2m
    cnt=`expr $cnt + 1`
  else
    flag=True
    break
  fi
done
echo $cnt

if [ "$flag" == "True" ]
then
  echo "tVault appliance is up\n"
else
  echo "tVault appliance is not getting up, exiting...\n"
  exit 1
fi

