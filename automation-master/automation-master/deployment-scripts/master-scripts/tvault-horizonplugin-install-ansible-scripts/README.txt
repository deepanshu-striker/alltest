These ansible scripts are designed to install trilioVault's horizon plugin for OpenStack.
==================================================================================================



=========Pre-requisites to use these scripts===
1.	Ansible server
2.	Ansible’s host inventory file should have a hostgroup named "horizon", listing all openstack horizon nodes.
        For example. Your ansible inventory file should look like this
        ---/etc/ansible/hosts------
        [horizon]
        192.168.1.10
        192.168.1.12
        --------------------------
3.	On all these nodes (Compute and controller) Ansible server’s authentication setup should be done(Server should be 
        able to run ansible scripts on these nodes).



========Steps to deploy TrilioVault extension on OpenStack
1.	Download/clone "tvault-horizonplugin-install-ansible-scripts" directory 

2.	Copy it in your ansible roles directory (Generally it's /etc/ansible/roles)

3.	Edit vars/tvault-horizon-plugin-answers.yml and configure required parameters.

4.	Execute tvault-horizon-plugin-install.yml script using following command

        ansible-playbook tvault-horizon-plugin-install.yml

5.      Logs of scripts executing on respective nodes(horizon nodes) would be avaiable in currrent 
        directory(of ansible server) at "logs/<host-name>/tvault-horizon-plugin-install.log"
