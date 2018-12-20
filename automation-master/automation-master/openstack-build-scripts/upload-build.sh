#!/bin/bash -x
source build.properties

BASE_DIR="$(pwd)"

cd $BASE_DIR/build
CURRENT_DIR=`pwd`
LATEST_BUILD=`find "$CURRENT_DIR" -name *.gz`
drive upload -p $DRIVE_LOCATION -f $LATEST_BUILD >  ../build_upload.log

mkdir -p /mnt/build-vault/${git_branch}
rm -rf /mnt/build-vault/${git_branch}/latest
mkdir -p /mnt/build-vault/${git_branch}/latest
cp $LATEST_BUILD /mnt/build-vault/${git_branch}/latest/
cp $LATEST_BUILD /mnt/build-vault/${git_branch}/
   
if [ $? -eq 0 ]
then
   cd $BASE_DIR/
   GOOGLE_DRIVE_ID=`cat build_upload.log | grep Id | awk '{print $2}'`
   cat build_ids | grep $TVAULT_VERSION
   if [ $? -eq 0 ]; then
      sed -i "s/$TVAULT_VERSION.*/$TVAULT_VERSION $GOOGLE_DRIVE_ID/g" build_ids
   else
      echo "$TVAULT_VERSION $GOOGLE_DRIVE_ID" >> build_ids
   fi
   ./send_mail.py 0 $TVAULT_VERSION $GOOGLE_DRIVE_ID $MAIL_TO
fi
