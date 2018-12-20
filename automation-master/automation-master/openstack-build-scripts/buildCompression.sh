#!/bin/bash -x

BASE_DIR="$(pwd)"

cd $BASE_DIR
source build.properties
build_compression_server="192.168.6.27"
max_build_size=2147483648

TVAULT_BUILD_NAME=tvault-appliance-os-${TVAULT_VERSION}.qcow2

get_flag_for_compression()
{
                size=$(stat -c%s "${TVAULT_BUILD_NAME}.tar.gz")
                flag=`echo $size'>'$max_build_size | bc -l`
}

do_compression()
{
                cp $BASE_DIR/compress_build.sh $BASE_DIR/build/
                cd $BASE_DIR/build
                ssh root@${build_compression_server} 'rm -rf /home/tvault*'
                if [ $? -ne 0 ]
                then
                 echo "removing old build failed, exiting..\n"
                 exit 1
                fi

                scp ${TVAULT_BUILD_NAME} root@${build_compression_server}:/home/
                if [ $? -ne 0 ]
                then
                 echo "copying new build failed, exiting..\n"
                 exit 1
                fi

                ssh -q -o "StrictHostKeyChecking no" root@${build_compression_server} TVAULT_BUILD_NAME=$TVAULT_BUILD_NAME 'bash -s' < compress_build.sh

                scp root@${build_compression_server}:/home/${TVAULT_BUILD_NAME}.tar.gz ${TVAULT_BUILD_NAME}.tar.gz
}

wait_for_server_up()
{
                ping -c 3 ${build_compression_server} > /dev/null 2>&1
                if [ $? -ne 0 ]
                then
                  echo -e "build_compression_server is not up yet, sleeping for 2 more minutes\n"
                  sleep 2m
                  ping -c 3 ${build_compression_server} > /dev/null 2>&1
                  if [ $? -ne 0 ]
                  then
                        echo "build_compression_server is not getting up, exiting...\n"
                        exit 1
                  fi
                fi
}

ssh root@${build_compression_server} 'shutdown -r now'
sleep 5m
wait_for_server_up
do_compression
get_flag_for_compression

if [ $flag = 1 ]
then
   echo "build compression failing"
   echo "#retry"
   echo "#reboot"
   ssh root@${build_compression_server} 'shutdown -r now'
   sleep 5m
   wait_for_server_up
   echo "#retrying compression"
   do_compression
   get_flag_for_compression
   FAIL=2
   if [ $flag = 1 ]
   then
      echo "#build compression still failing"
      cd $BASE_DIR
      ./send_mail.py $FAIL $TVAULT_VERSION "" $MAIL_TO
      exit 1
    else
       ##Upload build
       echo "Latest build compressed successfully, Build file: $BASE_DIR/build/${TVAULT_BUILD_NAME}.tar.gz"
       cd $BASE_DIR/build
       size=`du -sh ${TVAULT_BUILD_NAME}.tar.gz | awk '{print $1}'`
       export build_tar_size=$size
       cd $BASE_DIR
       ./upload-build.sh
    fi
else
   ##Upload build
   echo "Latest build compressed successfully, Build file: $BASE_DIR/build/${TVAULT_BUILD_NAME}.tar.gz"
   cd $BASE_DIR/build
   size=`du -sh ${TVAULT_BUILD_NAME}.tar.gz | awk '{print $1}'`
   export build_tar_size=$size
   cd $BASE_DIR
   ./upload-build.sh
fi
