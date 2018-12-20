#!/bin/bash -x

#Properties
source build.properties
BASE_DIR="$(pwd)"

#Remove old repos
rm -rf $BASE_DIR/horizon-tvault-plugin
rm -rf $BASE_DIR/contego
rm -rf $BASE_DIR/python-workloadmgrclient
rm -rf $BASE_DIR/workloadmgr
rm -rf $BASE_DIR/contegoclient
rm -rf $BASE_DIR/dmapi
echo -e "Removed old repositories \n"

##Checkout latest code
git clone git@github.com:TrilioBuild/horizon-tvault-plugin.git
git clone git@github.com:TrilioBuild/contego.git
git clone git@github.com:TrilioBuild/workloadmanager-client.git python-workloadmgrclient
git clone git@github.com:TrilioBuild/workloadmanager.git workloadmgr
git clone git@github.com:TrilioBuild/contegoclient.git
git clone git@github.com:TrilioBuild/dmapi.git
echo -e "Cloned all repositories \n"

#Fetch changes from upstream

cd $BASE_DIR/workloadmgr
git remote add upstream git@github.com:trilioData/workloadmanager.git
git fetch upstream
git checkout $git_branch
git merge upstream/$git_branch --no-edit

cd $BASE_DIR/python-workloadmgrclient
git remote add upstream git@github.com:trilioData/workloadmanager-client.git
git fetch upstream
git checkout $git_branch
git merge upstream/$git_branch --no-edit

cd $BASE_DIR/contego
git remote add upstream git@github.com:trilioData/contego.git
git fetch upstream
git checkout $git_branch
git merge upstream/$git_branch --no-edit

cd $BASE_DIR/contegoclient
git remote add upstream git@github.com:trilioData/contegoclient.git
git fetch upstream
git checkout $git_branch
git merge upstream/$git_branch --no-edit

cd $BASE_DIR/horizon-tvault-plugin
git remote add upstream git@github.com:trilioData/horizon-tvault-plugin.git
git fetch upstream
git checkout $git_branch
git merge upstream/$git_branch --no-edit

cd $BASE_DIR/dmapi
git remote add upstream git@github.com:trilioData/dmapi.git
git fetch upstream
git checkout $git_branch
git merge upstream/$git_branch --no-edit

echo -e "Fetched changes from upstream \n"

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

cd $BASE_DIR/contegoclient
git status
git add *
git commit -m "Updating version to $TVAULT_VERSION"
git push origin $git_branch

cd $BASE_DIR/dmapi
git status
git add *
git commit -m "Updating version to $TVAULT_VERSION"
git push origin $git_branch

echo -e "Commited changes to $git_branch \n"

#Create pull request

