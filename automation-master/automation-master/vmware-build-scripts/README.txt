


To create latest build follow below steps:
1. Go to /mnt/ansible/build_automation directory of 192.168.3.45 machine
1. Edit build.properties file for old and new build versions
2. Download latest build and put it in old-build directory, if directory not present create one in currect directory
3. Scripts needs an free IP, as configured in build.properties, make sure it is free
4. Run buildTVault.sh script like ./buildTvault.sh
5. It will create latest build and will copy it in latest-build directory  

To setup new build machine follow below steps:-
1. Create 1 centos6 machine
2. Install ansible server
3. Create ssh keys for root user
4. /etc/ansible/hosts file create [webservers] entry pointing to a free ip
5. Clone automation repository from
   git@github.com:trilioData/automation.git
6. Go to build automation directory, copy ansible/hosts file to /etc/ansible
7. Edit /etc/ansible/ansible.cfg for roles path, set it to your build_automation directory 
8. You are done now.
