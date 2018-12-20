#!/bin/bash -x

BASE_DIR="$(pwd)"

#exec >& $BASE_DIR/buildTVault.log
source openstack.properties

rm -rf build
mkdir -p build/
cp /mnt/build-vault/${git_branch}/tvault-appliance-os-${TVAULT_VERSION}.qcow2.tar.gz build/
cd build/
tar -xvzf tvault-appliance-os-${TVAULT_VERSION}.qcow2.tar.gz
