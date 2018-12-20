#!/bin/bash -x

set -e

export VERSION="$TVAULT_VERSION"
echo $VERSION > /tmp/TVAULT_VERSION
cat /tmp/TVAULT_VERSION
TVAULT_VERSION=`cat /tmp/TVAULT_VERSION`
echo -e "tvault version: $TVAULT_VERSION"

export RELEASE="$TVAULT_RELEASE"
echo $RELEASE > /tmp/TVAULT_RELEASE
cat /tmp/TVAULT_RELEASE
TVAULT_RELEASE=`cat /tmp/TVAULT_RELEASE`
echo -e "tvault RELEASE: $TVAULT_RELEASE"

CWD="$PWD"

BASE_DIR="/opt/rpm"
REPO_DIR=/var/www/html/yum-repo/



rm -rf $BASE_DIR
rm -rf $REPO_DIR
mkdir -p $BASE_DIR
cp tvault-contego.spec $BASE_DIR/
cp puppet-triliovault.spec $BASE_DIR/
cp tvault-contego-api-clean $BASE_DIR/
cp tvault-horizon-plugin-clean $BASE_DIR/
cp python-workloadmgrclient-clean $BASE_DIR/
mkdir -p $REPO_DIR/newton
mkdir -p $REPO_DIR/queens
cd $BASE_DIR
git clone git@github.com:trilioData/contego.git



##Create contego extension rpm
rm -rf ~/rpmbuild/
mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
mkdir -p ~/rpmbuild/RPMS/{noarch,i386,i686}
rm -rf ~/rpmbuild/BUILD/*
echo "%_topdir %(echo $HOME)/rpmbuild" > ~/.rpmmacros
cd $BASE_DIR/contego/
make clean
git checkout setup.py
sed -i "s/os\.getenv('VERSION'.*/\'${TVAULT_VERSION}\'/" setup.py
sed -i "s/os\.getenv('TVAULT_PACKAGE'.*/\'tvault-contego\'/" setup.py
echo 'exclude contego/nova/api.py' > MANIFEST.in
python setup.py bdist_rpm --release=$TVAULT_RELEASE --requires=puppet-triliovault
contego_rpm="tvault-contego-${TVAULT_VERSION}-${TVAULT_RELEASE}.noarch.rpm" 
cp dist/${contego_rpm} ${REPO_DIR}/newton/
cp dist/${contego_rpm} ${REPO_DIR}/queens/


##Create tvault horizon plugin rpm
cd $BASE_DIR/
git clone git@github.com:trilioData/horizon-tvault-plugin.git
cd $BASE_DIR/horizon-tvault-plugin/
sed -i "s/os\.getenv('VERSION'.*/\'${TVAULT_VERSION}\'\,/" setup.py
python setup.py bdist_rpm --release=$TVAULT_RELEASE --pre-install=$BASE_DIR/tvault-horizon-plugin-clean
cp dist/tvault-horizon-plugin-${TVAULT_VERSION}-${TVAULT_RELEASE}.noarch.rpm ${REPO_DIR}/newton/
cp dist/tvault-horizon-plugin-${TVAULT_VERSION}-${TVAULT_RELEASE}.noarch.rpm ${REPO_DIR}/queens/


##Create workloadmgr client rpm
cd $BASE_DIR/
git clone git@github.com:trilioData/workloadmanager-client.git python-workloadmgrclient
cd $BASE_DIR/python-workloadmgrclient
sed -i "s/os\.getenv('VERSION'.*/\'${TVAULT_VERSION}\'\,/" setup.py
make clean
python setup.py bdist_rpm --release=$TVAULT_RELEASE --pre-install=$BASE_DIR/python-workloadmgrclient-clean
cp dist/python-workloadmgrclient-${TVAULT_VERSION}-${TVAULT_RELEASE}.noarch.rpm ${REPO_DIR}/newton/
cp dist/python-workloadmgrclient-${TVAULT_VERSION}-${TVAULT_RELEASE}.noarch.rpm ${REPO_DIR}/queens/

##Create dmapi rpm
cd $BASE_DIR/
git clone git@github.com:trilioData/dmapi dmapi
cd $BASE_DIR/dmapi
ver_str="version = ${TVAULT_VERSION}"
sed -i "s/^version.*/${ver_str}/" setup.cfg
#make clean
python setup.py bdist_rpm --release=$TVAULT_RELEASE
find dist/  -iregex "dist/dmapi-.*noarch.rpm" -exec cp {} ${REPO_DIR}/newton/ \;
find dist/  -iregex "dist/dmapi-.*noarch.rpm" -exec cp {} ${REPO_DIR}/queens/ \;


##Create puppet triliovault rpm 
git clone git@github.com:trilioData/triliovault-cfg-scripts.git $BASE_DIR/triliovault-cfg-scripts
cd $BASE_DIR/triliovault-cfg-scripts/redhat-director-scripts/puppet/trilio
rm -rf .git
rm -f .gitignore

#For newton
rm -rf ~/rpmbuild/
mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
mkdir -p ~/rpmbuild/RPMS/{noarch,i386,i686}
rm -rf ~/rpmbuild/BUILD/*
rm -rf /opt/automation
echo "%_topdir %(echo $HOME)/rpmbuild" > ~/.rpmmacros
cd ~/rpmbuild/
cp -R $BASE_DIR/triliovault-cfg-scripts/redhat-director-scripts/puppet/trilio ~/rpmbuild/
git clone git@github.com:trilioData/automation.git /opt/automation
cp /opt/automation/openstack-build-scripts/artifacts/newton/tvault-contego-virtenv.tar.gz trilio/files/
find trilio/ -type f > INSTALLED_FILES
sed -i 's/^/\/usr\/share\/openstack-puppet\/modules\//' INSTALLED_FILES
cp INSTALLED_FILES BUILD/
cp -R trilio ~/rpmbuild/BUILD/
sed -i.bak "s/VERSION/${TVAULT_VERSION}/" ${BASE_DIR}/puppet-triliovault.spec
sed -i.bak "s/RELEASE/${TVAULT_RELEASE}/" ${BASE_DIR}/puppet-triliovault.spec
cp $BASE_DIR/puppet-triliovault.spec ~/rpmbuild/SPECS/
cd ~/rpmbuild/SPECS/
rpmbuild -ba puppet-triliovault.spec
cd ~/rpmbuild
cp ~/rpmbuild/RPMS/noarch/puppet-triliovault-${TVAULT_VERSION}-${TVAULT_RELEASE}.noarch.rpm ${REPO_DIR}/newton/

#For queens
rm -rf ~/rpmbuild/
mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
mkdir -p ~/rpmbuild/RPMS/{noarch,i386,i686}
rm -rf ~/rpmbuild/BUILD/*
echo "%_topdir %(echo $HOME)/rpmbuild" > ~/.rpmmacros
cd ~/rpmbuild/
cp -R $BASE_DIR/triliovault-cfg-scripts/redhat-director-scripts/puppet/trilio ~/rpmbuild/
cp /opt/automation/openstack-build-scripts/artifacts/queens/tvault-contego-virtenv.tar.gz trilio/files/
find trilio/ -type f > INSTALLED_FILES
sed -i 's/^/\/usr\/share\/openstack-puppet\/modules\//' INSTALLED_FILES
cp INSTALLED_FILES BUILD/
cp -R trilio ~/rpmbuild/BUILD/
sed -i.bak "s/VERSION/${TVAULT_VERSION}/" ${BASE_DIR}/puppet-triliovault.spec
sed -i.bak "s/RELEASE/${TVAULT_RELEASE}/" ${BASE_DIR}/puppet-triliovault.spec
cp $BASE_DIR/puppet-triliovault.spec ~/rpmbuild/SPECS/
cd ~/rpmbuild/SPECS/
rpmbuild -ba puppet-triliovault.spec
cd ~/rpmbuild
cp ~/rpmbuild/RPMS/noarch/puppet-triliovault-${TVAULT_VERSION}-${TVAULT_RELEASE}.noarch.rpm ${REPO_DIR}/queens/


##Createing yum repodata
createrepo ${REPO_DIR}/newton/
createrepo ${REPO_DIR}/queens/

echo "rpms are built sucessfully, please find them in ${REPO_DIR} directory"
