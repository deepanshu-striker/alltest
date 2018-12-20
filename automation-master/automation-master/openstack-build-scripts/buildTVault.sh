#!/bin/bash -x

BASE_DIR="$(pwd)"

rm -f build.properties openstack-auth.sh /etc/ansible/hosts
cp build_setup/build.properties .
cp build_setup/openstack-auth.sh .
cp $BASE_DIR/build_setup/ansible_hosts /etc/ansible/
mv /etc/ansible/ansible_hosts /etc/ansible/hosts

#exec >& $BASE_DIR/buildTVault.log
source build.properties
source openstack-auth.sh

rpm_build_server="192.168.1.119"
build_deb_server="192.168.12.32"
docker_server="192.168.6.25"

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
echo "git_branch: $git_branch" >> vars/tvault-config.yml
echo "client_git_branch: $client_git_branch" >> vars/tvault-config.yml
echo "TVAULT_VERSION: $TVAULT_VERSION" >> vars/tvault-config.yml
echo "tvault_passwd: $TVAULT_APPLIANCE_PASSWORD" >> vars/tvault-config.yml

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
     echo "NFS mount failed, exiting.."
     exit 1
   fi
fi

#Update build version
./update_code.sh
if [ $? -ne 0 ]
then
 echo -e "Update code failed, exiting \n"
 exit 1
fi

##Create ansible script's bundle
rm -rf $BASE_DIR/automation
cd $BASE_DIR
rm -f tvault-ansible-scripts*
git clone -b ${git_branch} git@github.com:trilioData/automation.git
cd automation/
mkdir -p tvault-ansible-scripts-${TVAULT_VERSION}/tvault-pure-ansible-scripts
mkdir -p tvault-puppet-scripts-${TVAULT_VERSION}
mv master-scripts tvault-ansible-scripts-${TVAULT_VERSION}
mv ../../triliovault-cfg-scripts/ansible tvault-ansible-scripts-${TVAULT_VERSION}/tvault-pure-ansible-scripts/
mv ../../triliovault-cfg-scripts/redhat-director-scripts tvault-puppet-scripts-${TVAULT_VERSION}
tar -czf tvault-ansible-scripts-${TVAULT_VERSION}.tar.gz tvault-ansible-scripts-${TVAULT_VERSION}
tar -czf trilio-redhat-director-scripts-${TVAULT_VERSION}.tar.gz tvault-puppet-scripts-${TVAULT_VERSION}
mv tvault-ansible-scripts-${TVAULT_VERSION}.tar.gz ../
mv trilio-redhat-director-scripts-${TVAULT_VERSION}.tar.gz ../
##Copy Ubuntu16.04 image
cd $BASE_DIR
./copy_build.sh Ubuntu16

#Deploy old build
ansible-playbook deploy_tvault.yml --extra-vars "build_path=$OLD_BUILD_FILE"
if [ $? -ne 0 ]
then
 echo "Deploy_Old_Build failed, exiting..\n"
 exit 1
fi
sleep 2m

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

##Build rpms for contego, api, horizon plugin and workloadmgr client
TVAULT_RELEASE=`echo $TVAULT_VERSION | cut -f 1-2 -d "."`
ansible-playbook build_rpms.yml --extra-vars "host=$rpm_build_server TVAULT_VERSION=$TVAULT_VERSION TVAULT_RELEASE=$TVAULT_RELEASE"
if [ $? -ne 0 ]
then
 echo -e "Build rpms for contego, api, horizon plugin and workloadmgr client failed, exiting \n"
 exit 1
fi

scp -r $BASE_DIR/automation/$rpm_build_server/var/www/html/ root@$floating_ip:/var/www/

##Build deb packages for contego, api, horizon plugin and workloadmgr client
ansible-playbook build_deb_pacakges.yml --extra-vars "host=$build_deb_server TVAULT_VERSION=$TVAULT_VERSION TVAULT_RELEASE=$TVAULT_RELEASE"
if [ $? -ne 0 ]
then
 echo -e "Build deb packages failed, exiting \n"
 exit 1
fi

ansible-playbook  git_auth_setup.yml --extra-vars "host=$floating_ip rpm_build_server=$rpm_build_server build_deb_server=$build_deb_server"
if [ $? -ne 0 ]
then
 exit 1
fi

ansible-playbook update_repos.yml --extra-vars "host=$floating_ip"
if [ $? -ne 0 ]
then
 exit 1
fi

##Clean unwanted files, directories
ssh root@$floating_ip TVAULT_VERSION=$TVAULT_VERSION 'bash -s' < cleanTVault.sh
if [ $? -ne 0 ]
then
 exit 1
fi
sleep 15s


# Build Docker Images
ansible-playbook build_docker_images.yml --extra-vars "host=$docker_server floating_ip=$floating_ip tvault_version=$TVAULT_VERSION"
if [ $? -ne 0 ]
then
 echo -e "Build docker images failed, exiting \n"
 exit 1
fi

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

TVAULT_BUILD_NAME=tvault-appliance-os-${TVAULT_VERSION}.qcow2
rm -rf build
mkdir build

cp compress_build.sh build/

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

tar -zcvf ${TVAULT_BUILD_NAME}.tar.gz ${TVAULT_BUILD_NAME}
if [ $? -ne 0 ]
then
 echo "Create_New_Build failed, exiting..\n"
 exit 1
fi

size=`du -sh ${TVAULT_BUILD_NAME}.tar.gz | awk '{print $1}'`
export build_tar_size=$size

##Upload build
if [ $? -eq 0 ]
then
 echo "Latest build created successfully, Build file: $BASE_DIR/build/${TVAULT_BUILD_NAME}.tar.gz"
 cd $BASE_DIR
 ./upload-build.sh
 glance image-delete ${TVAULT_IMAGE_ID}
else
 echo "Latest build creation failed"
 glance image-delete ${TVAULT_IMAGE_ID}
 exit 1
fi

#build compression added
chmod +x buildCompression.sh
./buildCompression.sh
if [ $? -ne 0 ]
then
 echo "Something Nasty Happened while build compression, exiting..\n"
 exit 1
fi

##Clean local ansible bundle
cd $BASE_DIR/
rm -rf tvault-ansible-scripts*
rm -rf trilio-redhat-director-scripts*
rm -rf automation
rm -rf contego/ contegoclient/ horizon-tvault-plugin/ python-workloadmgrclient/ workloadmgr/

export TVAULT_INSTANCE_ID=`nova list | grep $floating_ip | tail -1 | awk '{print $2;}'`
nova delete ${TVAULT_INSTANCE_ID}
