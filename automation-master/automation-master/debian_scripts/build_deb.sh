#!/bin/bash -x
set -e

if [ "$#" -lt 2 ]; then
   echo -e "Provide package name and version as command line paramaters, like following... \n./build_deb.sh tvault-contego-api 3.0.5\n./build_deb.sh tvault-contego 3.0.5"
   exit 1
fi

export DEBFULLNAME=TrilioData
export DEBEMAIL=info@trilio.io
export TVAULT_PACKAGE=$1
export PACKAGE=$1
export VERSION=$2

if [ "$TVAULT_PACKAGE" = "tvault-contego" ]; then
   cd $(pwd)/contego
   cp MANIFEST.in ../
   export CURDIR=$(pwd)
   echo 'exclude contego/*.*
   include contego/__init__.py' > MANIFEST.in
   make builddeb
elif [ "$TVAULT_PACKAGE" = "contego" ]; then
   cp contego.tar.gz contego_$VERSION.orig.tar.gz
   cd $(pwd)/contego_extension
   rm -rf $(pwd)/debian/changelog
   rm -rf $(pwd)/contego
   debchange --create --distribution xenial --package ${TVAULT_PACKAGE} --newversion ${VERSION} "TrilioData Debian Package"
   export CURDIR=$(pwd)
   debuild -us -uc
   rm -rf contego_$VERSION.orig.tar.gz
elif [ "$TVAULT_PACKAGE" = "tvault-contego-api" ]; then
   cd $(pwd)/contego
   cp MANIFEST.in ../
   export CURDIR=$(pwd)
   echo 'exclude contego/*.*
   include contego/__init__.py' > MANIFEST.in
   make builddeb  
elif [ "$TVAULT_PACKAGE" = "tvault-horizon-plugin" ]; then
   cd $(pwd)/horizon-tvault-plugin
   export CURDIR=$(pwd)
   make builddeb
elif [ "$TVAULT_PACKAGE" = "python-workloadmgrclient" ]; then
   cd $(pwd)/workloadmanager-client
   export CURDIR=$(pwd)
   make builddeb
elif [ "$TVAULT_PACKAGE" = "dmapi" ]; then
   cd $(pwd)/dmapi
   export CURDIR=$(pwd)
   make builddeb
fi

#make builddeb
#mv ../tvault-contego* deb_dist/
#cp deb_dist/tvault-contego* /home/deb/packages/
#cp -r ../contego_bk/* contego/
#rm -rf ../contego_bk
#rm deb_dist/tvault-contego*
unset TVAULT_PACKAGE
unset PACKAGE
unset VERSION
unset CURDIR
make clean
