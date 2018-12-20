Configure triliovault controller node additional node
=====================================

Prerequisites
==============

## Tvault appliance deployed in cloud environment
## Floating ip address assigned which can be pinged within private network
## Openstack keystone service credentials
## Ansible installed on machine from where to configure


Steps to configure
==========================================

## Checkout github repository tvault-config-ansible-scripts
## Input data to vars/configure_vars.yml file accordingly
## Run following command to configure trilioVault controller node       
./configure.sh -c              
## Run following command to configure trilioVault additional node
./configure.sh -a
