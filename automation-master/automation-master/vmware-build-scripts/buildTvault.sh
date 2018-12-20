#!/bin/bash -x

BASE_DIR="$(pwd)"

#exec >& $BASE_DIR/buildTvault.log
source build.properties

$BASE_DIR/editOVA.sh
if [ $? -ne 0 ]
then
 exit 0
fi


$BASE_DIR/deployOVA.sh
if [ $? -ne 0 ]
then
 exit 0
fi

cd $BASE_DIR/ansible-scripts

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

./auth.expect tvault-gui $PASSWORD $IP1
if [ $? -ne 0 ]
then
 exit 0
fi



ansible-playbook finalBuild.yml
if [ $? -ne 0 ]
then
 exit 0
fi


cd $BASE_DIR

$BASE_DIR/exportOVA.sh
if [ $? -ne 0 ]
then
 exit 0
fi

echo "---------------------------------------------------------------------------------"
echo "Build is successful"
echo "Please find latest build in $LATEST_BUILD directory"
echo "For detailed log see: $BASE_DIR/buildTvault.log"
echo "---------------------------------------------------------------------------------"
