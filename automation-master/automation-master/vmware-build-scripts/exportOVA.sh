#!/bin/bash -x

BASE_DIR="$(pwd)"

source $BASE_DIR/build.properties 

cd ${LATEST_BUILD}


ovftool --overwrite --powerOffSource ${EXPORT_VI_LOCATOR} ${NEW_BUILD_NAME}
