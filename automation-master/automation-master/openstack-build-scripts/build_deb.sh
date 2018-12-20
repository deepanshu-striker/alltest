#!/bin/bash -x

set -e

if [ "$#" -lt 2 ]; then
   echo -e "Provide packge name and version as command line paramaters, like following... \n./build_deb.sh tvault-contego-api 3.0.5\n./build_deb.sh tvault-contego 3.0.5"
   exit 1
fi

cd /opt/stack/contego

cp MANIFEST.in ../
export DEBFULLNAME=TrilioData
export DEBEMAIL=info@trilio.io
export TVAULT_PACKAGE=$1
export PACKAGE=$1
export VERSION=$2

if [ "$TVAULT_PACKAGE" = "tvault-contego" ]; then
   echo 'exclude contego/nova/api.py' >> MANIFEST.in
elif [ "$TVAULT_PACKAGE" = "tvault-contego-api" ]
then
    echo 'exclude contego/*.*
    include contego/__init__.py' > MANIFEST.in
fi

make builddeb
#mv ../tvault-contego* deb_dist/
#cp deb_dist/tvault-contego* /home/deb/packages/
mv ../MANIFEST.in .
#rm deb_dist/tvault-contego*
unset TVAULT_PACKAGE
unset PACKAGE
unset VERSION
make clean
