#!/bin/bash -x
BASE_DIR="$(pwd)"
echo $BASE_DIR

cd $BASE_DIR/contego
git pull git@github.com:trilioData/contego.git
rm -rf usr *.rpm
python setup.py bdist_rpm
if [ $? -ne 0 ]
then
  exit 0;
fi

cd dist
export e=`ls tvault-contego-*.noarch.rpm`
cp -f $e $BASE_DIR
cd $BASE_DIR
rpm2cpio $e | cpio -idmv
find usr/  -type f > INSTALLED_FILES
sed -i 's/^/\//' INSTALLED_FILES
rm -f $e

version=`python contego/setup.py --version`
oldVersion="%define version "
newVersion="%define version $version"
sed -i.bak "s/$oldVersion.*/$newVersion/g" tvault-contego.spec
sed -i.bak "s/$oldVersion.*/$newVersion/g" tvault-contego-api.spec


mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
mkdir -p ~/rpmbuild/RPMS/{noarch,i386,i686}
rm -rf ~/rpmbuild/BUILD/*
echo "%_topdir %(echo $HOME)/rpmbuild" > ~/.rpmmacros

cp -R usr ~/rpmbuild/BUILD
cp -f $BASE_DIR/INSTALLED_FILES ~/rpmbuild/BUILD
cp $BASE_DIR/tvault-contego-api.spec ~/rpmbuild/SPECS
cp $BASE_DIR/tvault-contego.spec ~/rpmbuild/SPECS

cd ~/rpmbuild/SPECS
rpmbuild -ba tvault-contego.spec
rpmbuild -ba tvault-contego-api.spec
cp ~/rpmbuild/RPMS/noarch/*.rpm $BASE_DIR
cd $BASE_DIR
echo "---------------------------------------------------------"
echo "Tvault-contego rpms are built sucessfully, please find them in current directory"
echo "---------------------------------------------------------"
