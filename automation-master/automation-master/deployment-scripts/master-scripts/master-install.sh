#!/bin/bash
BASE_DIR="$(pwd)"

echo -e "Base dir: $BASE_DIR \n"
#Copy All config files
rm -f $BASE_DIR/tvault-config-ansible-scripts/tvault-config.answers
rm -f $BASE_DIR/tvault-contego-install-ansible-scriptd/tvault-contego-answers.yml
rm -f $BASE_DIR/tvault-horizonplugin-install-ansible-scripts/tvault-horizon-plugin-answers.yml


cp $BASE_DIR/tvault-config.answers $BASE_DIR/tvault-config-ansible-scripts/vars
cp $BASE_DIR/tvault-contego-answers.yml  $BASE_DIR/tvault-contego-install-ansible-scripts/vars/
cp $BASE_DIR/tvault-horizon-plugin-answers.yml $BASE_DIR/tvault-horizonplugin-install-ansible-scripts/vars/

rm -rf $BASE_DIR/master-install.log
source $BASE_DIR/tvault-config.answers

rm -rf $BASE_DIR/logs
mkdir -p $BASE_DIR/logs

if [ "$1" == "--config" ] ; then
###Configuring trilioVault cluster
   echo -e "=====Started configuring trilioVault cluster=====\n"
   cd $BASE_DIR/tvault-config-ansible-scripts/
   ./configure.sh -c
   if [ $? -eq 0 ] ; then
      echo -e "\nController node configuration is successful" >> $BASE_DIR/master-install.log
      if [ -n "$additional_nodes_list" ]; then
        ./configure.sh -a -f
        if [ $? -eq 0 ] ; then
           echo -e "\nAdditional nodes configuration is successful" >> $BASE_DIR/master-install.log
           echo -e "\ntrilioVault cluster configuration task is successfully completed\n" >> $BASE_DIR/master-install.log
        else
           echo -e "\nController node configuration is successful but additional nodes configuration is failed\ntrilioVault cluster configuration task is failed\n"  >> $BASE_DIR/master-install.log 
        fi
      else 
        echo -e "No additional nodes configuration requested, trilioVault cluster configuration is completed\n" >> $BASE_DIR/master-install.log
      fi
      
    else
        echo -e "\nController node configuration is failed, skipping additional nodes configuration\ntrilioVault cluster configuration task is failed\n"  >> $BASE_DIR/master-install.log
        echo -e "\nScript results are stored in master-install.log file, detailed logs can be found under logs/ directory\n"
        exit 1
    fi
    if [ -f $BASE_DIR/tvault-config-ansible-scripts/results.txt ] ; then
        rm -rf $BASE_DIR/logs/tvault-config/
        mkdir -p $BASE_DIR/logs/tvault-config/
        cd $BASE_DIR/logs/tvault-config/
        cp $BASE_DIR/tvault-config-ansible-scripts/results.txt .
    fi
elif [ "$1" == "--config-additional-nodes" ] ; then
###Configuring trilioVault cluster
   echo -e "=====Started configuring additional nodes of trilioVault cluster=====\n"
   cd $BASE_DIR/tvault-config-ansible-scripts/
      if [ -n "$additional_nodes_list" ]; then
        ./configure.sh -a -f
        if [ $? -eq 0 ] ; then
           echo -e "\nAdditional nodes configuration is successful\n" >> $BASE_DIR/master-install.log
        else
           echo -e "\nAdditional nodes configuration is failed\n"  >> $BASE_DIR/master-install.log
        fi
      else
        echo -e "No additional nodes configuration requested, please edit tvault-config.answers file for additional node list\n" >> $BASE_DIR/master-install.log
      fi
	  
   if [ -f $BASE_DIR/tvault-config-ansible-scripts/results.txt ] ; then
        rm -rf $BASE_DIR/logs/tvault-config/
        mkdir -p $BASE_DIR/logs/tvault-config/
        cd $BASE_DIR/logs/tvault-config/
        cp $BASE_DIR/tvault-config-ansible-scripts/results.txt .
   fi
elif [ "$1" == "--contego" ] ; then
####Deploy trilioVault Contego 
    echo -e "=====Started deploying trilioVault Contego=====\n"
    cd $BASE_DIR/tvault-contego-install-ansible-scripts/
    ansible-playbook tvault-contego-install.yml -i hosts
    ansible-playbook contego-service-start.yml -i hosts
    if [ $? -eq 0 ] ; then
        echo -e "\ntrilioVault contego installation task is successfully completed\n" >> $BASE_DIR/master-install.log
    else
        echo -e "\ntrilioVault contego installation task is failed\n"  >> $BASE_DIR/master-install.log
    fi
    if [ -d $BASE_DIR/tvault-contego-install-ansible-scripts/logs ] ; then
        rm -rf $BASE_DIR/logs/tvault-contego/
        mkdir -p $BASE_DIR/logs/tvault-contego/
        cd $BASE_DIR/logs/tvault-contego/
        cp -R $BASE_DIR/tvault-contego-install-ansible-scripts/logs/* .
    fi

elif [ "$1" == "--horizon" ] ; then
####Install trilioVault horizon plugin
    echo -e "=====Started installing trilioVault horizon plugin====\n"
    cd $BASE_DIR/tvault-horizonplugin-install-ansible-scripts/
    ansible-playbook tvault-horizon-plugin-install.yml -i hosts
    if [ $? -eq 0 ] ; then
        echo -e "\ntrilioVault horizon plugin installation task is successfully completed\n" >> $BASE_DIR/master-install.log
    else
        echo -e "\ntrilioVault horizon plugin installation task is failed\n"  >> $BASE_DIR/master-install.log
    fi
    if [ -d $BASE_DIR/tvault-horizonplugin-install-ansible-scripts/logs ] ; then
        rm -rf $BASE_DIR/logs/tvault-horizonplugin/
        mkdir -p $BASE_DIR/logs/tvault-horizonplugin/
        cd $BASE_DIR/logs/tvault-horizonplugin/
        cp -R $BASE_DIR/tvault-horizonplugin-install-ansible-scripts/logs/* .    
    fi
elif [ "$1" == "--all" ] ; then
###Configuring trilioVault cluster
    echo -e "=====Started configuring trilioVault cluster=====\n"
    cd $BASE_DIR/tvault-config-ansible-scripts/
    ./configure.sh -c
    if [ $? -eq 0 ] ; then
         echo -e "\nController node configuration is successful" >> $BASE_DIR/master-install.log
         if [ -n "$additional_nodes_list" ]; then
           ./configure.sh -a -f
           if [ $? -eq 0 ] ; then
              echo -e "\nAdditional nodes configuration is successful" >> $BASE_DIR/master-install.log
              echo -e "\ntrilioVault cluster configuration task is successfully completed\n" >> $BASE_DIR/master-install.log
           else
              echo -e "\nController node configuration is successful but additional nodes configuration is failed\ntrilioVault cluster configuration task is failed\n"  >> $BASE_DIR/master-install.log
           fi
         else
           echo -e "No additional nodes configuration requested, trilioVault cluster configuration is completed\n" >> $BASE_DIR/master-install.log
         fi
     else
        echo -e "\nController node configuration is failed, skipping additional nodes configuration\ntrilioVault cluster configuration task is failed\n"  >> $BASE_DIR/master-install.log
    fi


    if [ -f $BASE_DIR/tvault-config-ansible-scripts/results.txt ] ; then
        rm -rf $BASE_DIR/logs/tvault-config/
        mkdir -p $BASE_DIR/logs/tvault-config/
        cd $BASE_DIR/logs/tvault-config/
        cp $BASE_DIR/tvault-config-ansible-scripts/results.txt .
    fi


####Deploy trilioVault Contego
    echo -e "=====Started deploying trilioVault Contego=====\n"
    cd $BASE_DIR/tvault-contego-install-ansible-scripts/
    ansible-playbook tvault-contego-install.yml -i hosts
    ansible-playbook contego-service-start.yml -i hosts
    if [ $? -eq 0 ] ; then
        echo -e "\ntrilioVault contego installation task is successfully completed\n" >> $BASE_DIR/master-install.log
    else
        echo -e "\ntrilioVault contego installation task is failed\n"  >> $BASE_DIR/master-install.log
    fi
    if [ -d $BASE_DIR/tvault-contego-install-ansible-scripts/logs ] ; then
        rm -rf $BASE_DIR/logs/tvault-contego/
        mkdir -p $BASE_DIR/logs/tvault-contego/
        cd $BASE_DIR/logs/tvault-contego/
        cp -R $BASE_DIR/tvault-contego-install-ansible-scripts/logs/* .
    fi


####Install trilioVault horizon plugin
    echo -e "=====Started installing trilioVault horizon plugin====\n"
    cd $BASE_DIR/tvault-horizonplugin-install-ansible-scripts/
    ansible-playbook tvault-horizon-plugin-install.yml -i hosts
    if [ $? -eq 0 ] ; then
        echo -e "\ntrilioVault horizon plugin installation task is successfully completed\n" >> $BASE_DIR/master-install.log
    else
        echo -e "\ntrilioVault horizon plugin installation task is failed\n"  >> $BASE_DIR/master-install.log
    fi
    if [ -d $BASE_DIR/tvault-horizonplugin-install-ansible-scripts/logs ] ; then
        rm -rf $BASE_DIR/logs/tvault-horizonplugin/
        mkdir -p $BASE_DIR/logs/tvault-horizonplugin/
        cd $BASE_DIR/logs/tvault-horizonplugin/
        cp -R $BASE_DIR/tvault-horizonplugin-install-ansible-scripts/logs/* .
    fi
elif [ "$1" == "--help" ] ; then
####Help document
    echo -e "Usage:\n./master-install.sh --config      To configure trilioVault cluster(Controller & additional nodes)\n./master-install.sh --config-additional-nodes    To configure additional nodes only \n./master-install.sh --contego     To deploy trilioVault contego extension\n./master-install.sh --horizon     To install trilioVault horizon plugin\n./master-install.sh --all         To perform above all thre tasks(config, contego, horizon plugin)\n./master-install.sh --help        To get help"

    exit 0
else
####Invalid option provided
    echo -e "Invalid option provided, please refer help using --help option\n"
    echo -e "Usage:\n./master-install.sh --config      To configure trilioVault cluster(Controller & additional nodes)\n./master-install.sh --config-additional-nodes    To configure additional nodes only \n./master-install.sh --contego     To deploy trilioVault contego extension\n./master-install.sh --horizon     To install trilioVault horizon plugin\n./master-install.sh --all         To perform above all thre tasks(config, contego, horizon plugin)\n./master-install.sh --help        To get help"

    exit 1
fi


echo -e "\nScript results are stored in master-install.log file, detailed logs can be found under logs/ directory\n"
