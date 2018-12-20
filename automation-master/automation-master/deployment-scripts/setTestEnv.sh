#!/bin/bash -x

BASE_DIR="$(pwd)"

#exec >& $BASE_DIR/buildTVault.log
mount -a
#rm -f master-scripts
#cp -R ../automation/master-scripts .

if [ -z "$1" ]
then
  echo "Please provide setup name"
  exit 1
fi
setup=$1
rm -f openstack.properties
rm -f master-scripts/tvault-config.answers
rm -f master-scripts/tvault-horizon-plugin-answers.yml
rm -f master-scripts/tvault-contego-answers.yml
cp environments/${setup}/openstack.properties .
cp environments/${setup}/tvault-config.properties master-scripts/tvault-config.answers
cp environments/${setup}/tvault-horizon-plugin.properties master-scripts/tvault-horizon-plugin-answers.yml
cp environments/${setup}/tvault-contego.properties master-scripts/tvault-contego-answers.yml
cp environments/${setup}/hosts master-scripts/tvault-config-ansible-scripts/
cp environments/${setup}/hosts master-scripts/tvault-contego-install-ansible-scripts/
cp environments/${setup}/hosts master-scripts/tvault-horizonplugin-install-ansible-scripts/
source openstack.properties


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

##Download latest build
#./copy_latest_build.sh


##Create tvm
LATEST_BUILD_FILE="tvault-appliance-os-${TVAULT_VERSION}.qcow2"
rm -f setTestEnv.log
#ansible-playbook deploy_tvault.yml --extra-vars "build_path=build/$LATEST_BUILD_FILE"

if [ $? -ne 0 ]
then
  echo "Deploy tvault step has failed"  >> setTestEnv.log
  exit 1
else
  echo "Deploy tvault step has sucessfully completed"  >> setTestEnv.log
fi
#sleep 4m

ping -c 3 $floating_ip > /dev/null 2>&1
if [ $? -ne 0 ]
then
  echo -e "tVault appliance is not up yet, sleeping for 2 more minutes\n"
  sleep 2m
  ping -c 3 $floating_ip > /dev/null 2>&1
  if [ $? -ne 0 ]
  then
    echo "tVault appliance is not getting up, exiting...\n" >> setTestEnv.log
    exit 1
  fi
fi

##Configure tvault , install contego, install horizon plugin
cd master-scripts
./master-install.sh --all
if [ $? -ne 0 ]
then
  echo "Tvault deployment has failed"  >> setTestEnv.log
  exit 1
fi
cat master-install.log >> $BASE_DIR/setTestEnv.log
cd $BASE_DIR
echo -e "===============Results================================\n"
cat setTestEnv.log
echo -e "======================================================\n"
