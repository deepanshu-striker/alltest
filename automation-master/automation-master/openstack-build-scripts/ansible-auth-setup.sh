#!/bin/bash -x

BASE_DIR="$(pwd)"

#exec >& $BASE_DIR/buildTvault.log
source build.properties
./auth.expect root $PASSWORD $IP1
if [ $? -ne 0 ]
then
 exit 0
fi

./auth.expect stack $PASSWORD $IP1
if [ $? -ne 0 ]
then
 exit 0
fi
