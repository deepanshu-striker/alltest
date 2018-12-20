#!/bin/bash -x

BASE_DIR="$(pwd)"
LOAD_BUILD=$1

#exec >& $BASE_DIR/buildTVault.log
source build.properties
source openstack-auth.sh

if [ $LOAD_BUILD == "Old_Build_Dev" ]
then
   rm -rf old-build/
   mkdir -p old-build/
   cp /mnt/build-vault/${old_branch}/tvault-appliance-os-${OLD_VERSION}.qcow2.tar.gz old-build/
   cd old-build/
   tar -xvzf tvault-appliance-os-${OLD_VERSION}.qcow2.tar.gz
   if [ $? -eq 0 ]
   then
      mv tvault-appliance-os-${OLD_VERSION}.qcow2 tvault-appliance-os.qcow2
      rm -f tvault-appliance-os-${OLD_VERSION}.qcow2.tar.gz
   else
      exit 1
   fi

elif [ $LOAD_BUILD == "Old_Build" ]
then
   rm -rf old-build/
   mkdir -p old-build/
   cp /mnt/build-vault/${git_branch}/tvault-appliance-os-${OLD_VERSION}.qcow2.tar.gz old-build/
   cd old-build/
   tar -xvzf tvault-appliance-os-${OLD_VERSION}.qcow2.tar.gz
   if [ $? -eq 0 ]
   then
      mv tvault-appliance-os-${OLD_VERSION}.qcow2 tvault-appliance-os.qcow2
      rm -f tvault-appliance-os-${OLD_VERSION}.qcow2.tar.gz
   else
      exit 1
   fi

elif [ $LOAD_BUILD == "Latest_Build" ]
then
   rm -rf build
   mkdir -p build/
   cp /mnt/build-vault/${git_branch}/tvault-appliance-os-${TVAULT_VERSION}.qcow2.tar.gz build/
   cd build/
   tar -xvzf tvault-appliance-os-${TVAULT_VERSION}.qcow2.tar.gz

elif [ $LOAD_BUILD == "Ubuntu16" ]
then
   rm -rf old-build/
   mkdir -p old-build/
   cp /mnt/build-vault/ubuntu-images/ubuntu16.04.qcow2 old-build/

fi
