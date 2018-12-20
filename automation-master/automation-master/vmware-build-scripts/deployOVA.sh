#!/bin/bash -x

BASE_DIR="$(pwd)"

source $BASE_DIR/build.properties 

cd ${EXTRACTED_BUILD}

ovftool --overwrite --powerOffTarget --powerOn -ds=${DATASTORE} \
--net:"${NEW_SOURCE_NETWORK1}"="${TARGET_NETWORK1}" --net:"${NEW_SOURCE_NETWORK2}"="${TARGET_NETWORK2}" \
--diskMode=${DISK_MODE} --name=${BUILD_VM_NAME} --prop:hostname=${HOSTNAME} --prop:ip1=${IP1} --prop:netmask1=${NETMASK1} \
--prop:gateway1=${GATEWAY} --prop:ip2=${IP2} --prop:netmask2=${NETMASK2} \
${EXTRACTED_BUILD_NAME} ${VI_LOCATOR}

sleep 5m
