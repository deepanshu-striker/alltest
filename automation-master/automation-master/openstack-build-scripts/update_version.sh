#!/bin/bash -x

rm -f build.properties
cp build_setup/build.properties .

#Properties
source build.properties
BASE_DIR="$(pwd)"

#Remove old repos
rm -rf $BASE_DIR/horizon-tvault-plugin
rm -rf $BASE_DIR/contego
rm -rf $BASE_DIR/python-workloadmgrclient
rm -rf $BASE_DIR/workloadmgr
rm -rf $BASE_DIR/contegoclient
echo -e "Removed old repositories \n"

##Checkout latest code
git clone git@github.com:TrilioBuild/horizon-tvault-plugin.git
git clone git@github.com:TrilioBuild/contego.git
git clone git@github.com:TrilioBuild/workloadmanager-client.git python-workloadmgrclient
git clone git@github.com:TrilioBuild/workloadmanager.git workloadmgr
git clone git@github.com:TrilioBuild/contegoclient.git
echo -e "Cloned all repositories \n"

##Set version properties
sed -i '/TVAULT_VERSION/d' build_setup/build.properties
sed -i '/PRE_OLD_VERSION_i/d' build_setup/build.properties
sed -i '/OLD_VERSION_i/d' build_setup/build.properties
sed -i '/NEW_VERSION_i/d' build_setup/build.properties
sed -i '/OLD_VERSION/d' build_setup/build.properties

ls ${BUILD_STORE_DIR}/${git_branch}/latest/ | grep tvault
if [ $? -ne 0 ]; then
   echo "Latest build is not available, please check the build store"
   exit 1
fi
export OLD_TVAULT_VERSION=`ls ${BUILD_STORE_DIR}/${git_branch}/latest/ | cut -f 4 -d '-' | cut -f 1,2,3 -d '.'`

p=(${OLD_TVAULT_VERSION//./ })

p1=${p[0]}
p2=${p[1]}
old_build_number=${p[2]}


build_number=`expr $old_build_number + 1`
pre_old_build_number=`expr $build_number - 2`

export PRE_OLD_VERSION_i="${p1}_${p2}_$pre_old_build_number"
export OLD_VERSION_i="${p1}_${p2}_$old_build_number"
export NEW_VERSION_i="${p1}_${p2}_$build_number"
export OLD_VERSION="${p1}.${p2}.$old_build_number"
export TVAULT_VERSION="${p1}.${p2}.$build_number"

echo "TVAULT_VERSION=$TVAULT_VERSION" >> build_setup/build.properties
echo "PRE_OLD_VERSION_i=$PRE_OLD_VERSION_i" >> build_setup/build.properties
echo "OLD_VERSION_i=$OLD_VERSION_i" >> build_setup/build.properties
echo "NEW_VERSION_i=$NEW_VERSION_i" >> build_setup/build.properties
echo "OLD_VERSION=$OLD_VERSION"  >> build_setup/build.properties

#Fetch changes from upstream
cd $BASE_DIR/workloadmgr
git checkout $git_branch
git remote add upstream git@github.com:trilioData/workloadmanager.git
git fetch upstream
git merge upstream/$git_branch --no-edit

cd $BASE_DIR/python-workloadmgrclient
git checkout $git_branch
git remote add upstream git@github.com:trilioData/workloadmanager-client.git
git fetch upstream
git merge upstream/$git_branch --no-edit

cd $BASE_DIR/contego
git checkout $git_branch
git remote add upstream git@github.com:trilioData/contego.git
git fetch upstream
git merge upstream/$git_branch --no-edit

cd $BASE_DIR/contegoclient
git checkout $git_branch
git remote add upstream git@github.com:trilioData/contegoclient.git
git fetch upstream
git merge upstream/$git_branch --no-edit

cd $BASE_DIR/horizon-tvault-plugin
git checkout $git_branch
git remote add upstream git@github.com:trilioData/horizon-tvault-plugin.git
git fetch upstream
git merge upstream/$git_branch --no-edit

echo -e "Fetched changes from upstream \n"

#Update version
cd $BASE_DIR
sed -i "s/DB_VERSION = '.*'/DB_VERSION = '${TVAULT_VERSION}'/" workloadmgr/workloadmgr/db/sqlalchemy/models.py
sed -i "s/os.getenv('VERSION', '.*')/os.getenv('VERSION', '${TVAULT_VERSION}')/" contego/setup.py
sed -i "s/TVAULT_CONTEGO_VERSION=.*/TVAULT_CONTEGO_VERSION=${TVAULT_VERSION}/" contego/install-scripts/tvault-contego-install.sh
sed -i "s/TVAULT_V=.*.tar.gz/TVAULT_V=${TVAULT_VERSION}.tar.gz/" horizon-tvault-plugin/install-scripts/tvault-horizon-plugin-install.sh
sed -i "s/os.getenv('VERSION', '.*')/os.getenv('VERSION', '${TVAULT_VERSION}')/" horizon-tvault-plugin/setup.py
sed -i "s/os.getenv('VERSION', '.*')/os.getenv('VERSION', '${TVAULT_VERSION}')/" python-workloadmgrclient/setup.py
echo -e "Updated version to $TVAULT_VERSION \n"

#Commit changes
cd $BASE_DIR/workloadmgr/
git status
git add *
git commit -m "Updating version to $TVAULT_VERSION"
git push origin $git_branch

cd $BASE_DIR/contego/
git status
git add *
git commit -m "Updating version to $TVAULT_VERSION"
git push origin $git_branch

cd $BASE_DIR/python-workloadmgrclient
git status
git add *
git commit -m "Updating version to $TVAULT_VERSION"
git push origin $git_branch

cd $BASE_DIR/horizon-tvault-plugin
git status
git add *
git commit -m "Updating version to $TVAULT_VERSION"
git push origin $git_branch

echo -e "Commited changes to $git_branch \n"

#Create pull request

cd $BASE_DIR
sed -i '/TVAULT_SNAPSHOT_NAME=/c TVAULT_SNAPSHOT_NAME=tvault-build-vm-snapshot-'$TVAULT_VERSION'' build_setup/build.properties
