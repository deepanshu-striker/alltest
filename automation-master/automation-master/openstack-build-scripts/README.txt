

buildTVault.sh 
===================
This script will create new tvault openstack build with latest code.


Pre-requisites
=================
#Running openstack setup 
#Ansible server setup on controller node of openstack

How to use?
=================
#Copy openstack-build-automation directory contents to your ansible roles directory on
openstack controller node
cp openstack-build-automation/* /etc/ansible/roles/

#Edit openstack-auth.sh script to provide correct openstack authentications properties

#Edit build.properties to provide correct build settings as per your enviornment

#Execute buildTVault.sh script from ansible roles directory
./buildTVault.sh
