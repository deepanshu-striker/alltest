These ansible scripts are designed to configure tvault cluster, deploy trilioVault extension and install trilioVault horizon plugin
=====================================================================================================================================



===Pre-requisites to use these scripts===============================
1.	Ansible server

2.	Ansible’s host inventory file should have three host goups, one is "controller" listing all controller nodes, next is "compute" listing all compute nodes and last is "horizon" listing all horizon nodes
        For Ex. Your /etc/ansible/hosts file should look like this
        ---/etc/ansible/hosts------
        [controller]
        192.168.1.5
        192.168.1.8
       
        [compute]
        192.168.1.7
        192.168.1.9

        [horizon]
        192.168.1.5
        192.168.1.11

        [localhost]
        127.0.0.1
        --------------------------
         
3.	On all these nodes (Compute, controller and horizon) Ansible server’s authentication setup should be done(Server should be able to run ansible scripts on these nodes).

4.      Tvault appliance deployed in cloud environment and floating ip which is accessible from ansible server should be assigned to all tvault nodes.



===Steps to use these scripts================
1.	Download/clone master-scripts directory in your ansible roles directory (Generally its /etc/ansible/roles)

2.	Edit tvault-config.answers, tvault-contego-answers.yml and tvault-horizon-plugin-answers.yml files to configure necessary parameters

3.	Execute master-install.sh to configure tvault nodes and install contego and horizon plugin. Use following command.

        ./master-install.sh --all

4.	Logs of script can be found in master-install.log and under logs/ directory.

5.      Use --help option of script(master-install.sh) to get more help
