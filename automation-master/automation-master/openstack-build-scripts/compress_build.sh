#!/bin/bash -x

export TVAULT_BUILD_NAME="$TVAULT_BUILD_NAME"

echo $TVAULT_BUILD_NAME > /tmp/TVAULT_BUILD_NAME
cat /tmp/TVAULT_BUILD_NAME

TVAULT_BUILD_NAME=`cat /tmp/TVAULT_BUILD_NAME`
echo -e "build: $TVAULT_BUILD_NAME"

cd /home/
sudo modprobe nbd
sudo qemu-nbd -c /dev/nbd0 ${TVAULT_BUILD_NAME}
sudo kpartx -a /dev/nbd0
sudo partprobe /dev/nbd0
sudo zerofree /dev/nbd0p1
sudo qemu-nbd -d /dev/nbd0
sudo kpartx -d /dev/nbd0
sudo qemu-img convert -o compat=0.10 -t none -O qcow2 ${TVAULT_BUILD_NAME} ${TVAULT_BUILD_NAME}.1
mv ${TVAULT_BUILD_NAME}.1 ${TVAULT_BUILD_NAME}
tar czvf ${TVAULT_BUILD_NAME}.tar.gz ${TVAULT_BUILD_NAME}
