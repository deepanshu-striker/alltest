#!/bin/bash -x

BASE_DIR="$(pwd)"
#Mount your storage at /mnt/ansible

source $BASE_DIR/build.properties
#Set properties
rm -rf $EXTRACTED_BUILD
rm -rf $LATEST_BUILD
mkdir $LATEST_BUILD
mkdir $EXTRACTED_BUILD


#Edit ova settings
cd $EXTRACTED_BUILD
ovftool $OLD_BUILD/$OLD_BUILD_NAME ${EXTRACTED_BUILD_NAME}
sed -i "s/$OLD_BUILD_VERSION/$NEW_BUILD_VERSION/" ${EXTRACTED_BUILD_NAME}
sed -i "s/$OLD_BUILD_NAME/$NEW_BUILD_NAME/" ${EXTRACTED_BUILD_NAME}
sed -i "s/$OLD_SOURCE_NETWORK1/$NEW_SOURCE_NETWORK1/" ${EXTRACTED_BUILD_NAME}
sed -i "s/$OLD_SOURCE_NETWORK2/$NEW_SOURCE_NETWORK2/" ${EXTRACTED_BUILD_NAME}



#Edit manifest
NEW_HASH=`openssl sha1 tvault-old.ovf`
sed -i "s|.*tvault-old.ovf.*|${NEW_HASH}|" tvault-old.mf
