These ansible scripts are designed to deploy trilioVault extension on OpenStack.
================================================================================



===Pre-requisites to use these scripts===============================
1.	Ansible server

2.	Ansible’s host inventory file should have two host goups, one is "controller" listing all controller nodes and other is "compute" listing all compute nodes
        For Ex. Your /etc/ansible/hosts file should look like this
        ---/etc/ansible/hosts------
        [controller]
        192.168.1.5
        192.168.1.8
       
        [compute]
        192.168.1.7
        192.168.1.9
        --------------------------
         
3.	On all these nodes (Compute and controller) Ansible server’s authentication setup should be done(Server should be able to run ansible scripts on these nodes).



===Steps to deploy trilioVault extension(trilioVault contego) on OpenStack================
1.	Download/clone these scripts

2.	Put it in your ansible roles directory (Generally its /etc/ansible/roles)

3.	Edit vars/tvault-contego-answers.yml and configure things like TVault appliance IP address, snapshot storage settings.

4.	Execute tvault-contego-install.yml script using following command

        ansible-playbook tvault-contego-install.yml

5.	Logs of scripts executing on respective nodes(Compute and controller) would be avaiable in currrent 
        directory at "logs/<host-name>/tvault-contego-install.log"
