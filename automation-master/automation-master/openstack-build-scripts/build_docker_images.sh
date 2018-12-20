#!/bin/bash -x

set -e
BASE_DIR="$(pwd)"

export FLOATING_IP=$FLOATING_IP
export TVAULT_VERSION=$TVAULT_VERSION

#Remove old repos
rm -rf $BASE_DIR/triliovault-cfg-scripts
echo -e "Removed old repositories \n"

##Checkout latest code
git clone git@github.com:trilioData/triliovault-cfg-scripts
echo -e "Cloned all repositories \n"

# build trilio-datamover
cd $BASE_DIR/triliovault-cfg-scripts/redhat-director-scripts/docker/trilio-datamover/
cat > trilio.repo <<-EOF
[trilio-queens]
name=Trilio Repository
baseurl=http://${FLOATING_IP}:8085/yum-repo/queens/
enabled=1
gpgcheck=0
EOF
./build_container.sh trilio/trilio-datamover ${TVAULT_VERSION}-queens 

if [ $? -ne 0 ]
then
 echo -e "Dokcer images for trilio-datamover built failed, exiting \n"
 exit 1
fi
echo -e "Dokcer images for trilio-datamover built successfully.\n"

# build trilio-datamover-api
cd $BASE_DIR/triliovault-cfg-scripts/redhat-director-scripts/docker/trilio-datamover-api/
cat > trilio.repo <<-EOF
[trilio-queens]
name=Trilio Repository
baseurl=http://${FLOATING_IP}:8085/yum-repo/queens/
enabled=1
gpgcheck=0
EOF
./build_container.sh trilio/trilio-datamover-api ${TVAULT_VERSION}-queens

if [ $? -ne 0 ]
then
 echo -e "Dokcer images for trilio-datamover-api built failed, exiting \n"
 exit 1
fi

echo -e "Dokcer images for trilio-datamover-api built successfully.\n"

# build trilio-horizon-plugin
cd $BASE_DIR/triliovault-cfg-scripts/redhat-director-scripts/docker/trilio-horizon-plugin/
cat > trilio.repo <<-EOF
[trilio-queens]
name=Trilio Repository
baseurl=http://${FLOATING_IP}:8085/yum-repo/queens/
enabled=1
gpgcheck=0
EOF
./build_container.sh trilio/openstack-horizon-with-trilio-plugin ${TVAULT_VERSION}-queens

if [ $? -ne 0 ]
then
 echo -e "Dokcer images for trilio-horizon-plugin built failed, exiting \n"
 exit 1
fi

echo -e "Dokcer images for trilio-horizon-plugin built successfully.\n"
