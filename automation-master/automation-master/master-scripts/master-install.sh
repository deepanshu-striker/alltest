#!/bin/bash
BASE_DIR="$(pwd)"

echo -e "Base dir: $BASE_DIR \n"
#Copy All config files
rm -f $BASE_DIR/tvault-config-ansible-scripts/tvault-config.answers
rm -f $BASE_DIR/tvault-contego-install-ansible-scriptd/tvault-contego-answers.yml
rm -f $BASE_DIR/tvault-horizonplugin-install-ansible-scripts/tvault-horizon-plugin-answers.yml

mkdir -p $BASE_DIR/tvault-config-ansible-scripts/vars $BASE_DIR/tvault-contego-install-ansible-scripts/vars/ $BASE_DIR/tvault-horizonplugin-install-ansible-scripts/vars/

cp $BASE_DIR/tvault-config.answers $BASE_DIR/tvault-config-ansible-scripts/vars
cp $BASE_DIR/tvault-contego-answers.yml  $BASE_DIR/tvault-contego-install-ansible-scripts/vars/
cp $BASE_DIR/tvault-horizon-plugin-answers.yml $BASE_DIR/tvault-horizonplugin-install-ansible-scripts/vars/

rm -rf $BASE_DIR/master-install.log
source $BASE_DIR/tvault-config.answers

rm -rf $BASE_DIR/logs
mkdir -p $BASE_DIR/logs
TEST_RESULTS_FILE="$BASE_DIR/test_results"

if [ "$1" == "--config" ] ; then
###Configuring trilioVault cluster
   echo -e "=====Started configuring trilioVault cluster=====\n"
   cd $BASE_DIR/tvault-config-ansible-scripts/
   pwd
   #./configure.sh -c
   ansible-playbook site.yml
   #sleep 3m
   #ansible-playbook site.yml
   if [ $? -eq 0 ] ; then
      echo -e "\nController node configuration is successful" >> $BASE_DIR/master-install.log
      echo "Tvault_Configuration PASSED" >> $TEST_RESULTS_FILE
      if [ -n "$additional_nodes_list" ]; then
        ./configure.sh -a -f
        if [ $? -eq 0 ] ; then
           echo -e "\nAdditional nodes configuration is successful" >> $BASE_DIR/master-install.log
           echo -e "\ntrilioVault cluster configuration task is successfully completed\n" >> $BASE_DIR/master-install.log
           echo "Additional_Node_Configuration PASSED" >> $TEST_RESULTS_FILE
        else
           echo -e "\nController node configuration is successful but additional nodes configuration is failed\ntrilioVault cluster configuration task is failed\n"  >> $BASE_DIR/master-install.log 
           echo "Additional_Node_Configuration FAILED" >> $TEST_RESULTS_FILE
        fi
      else 
        echo -e "No additional nodes configuration requested, trilioVault cluster configuration is completed\n" >> $BASE_DIR/master-install.log
      fi
      
    else
        echo -e "\nController node configuration is failed, skipping additional nodes configuration\ntrilioVault cluster configuration task is failed\n"  >> $BASE_DIR/master-install.log
        echo -e "\nScript results are stored in master-install.log file, detailed logs can be found under logs/ directory\n"
        echo "Tvault_Configuration FAILED" >> $TEST_RESULTS_FILE
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
    ansible-playbook tvault-contego-install.yml
    if [ $? -eq 0 ] ; then
        echo -e "\ntrilioVault contego installation task is successfully completed\n" >> $BASE_DIR/master-install.log
        echo "Tvault_Contego_Installation PASSED" >> $TEST_RESULTS_FILE
    else
        echo -e "\ntrilioVault contego installation task is failed\n"  >> $BASE_DIR/master-install.log
        echo "Tvault_Contego_Installation FAILED" >> $TEST_RESULTS_FILE
        exit 1
    fi

    ansible-playbook contego-service-start.yml
    if [ $? -eq 0 ] ; then
        echo -e "\ntrilioVault contego installation task is successfully completed\n" >> $BASE_DIR/master-install.log
        echo "Start_Contego_Service PASSED" >> $TEST_RESULTS_FILE
    else
        echo -e "\ntrilioVault contego installation task is failed\n"  >> $BASE_DIR/master-install.log
        echo "Start_Contego_Service FAILED" >> $TEST_RESULTS_FILE
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
    ansible-playbook tvault-horizon-plugin-install.yml
    if [ $? -eq 0 ] ; then
        echo -e "\ntrilioVault horizon plugin installation task is successfully completed\n" >> $BASE_DIR/master-install.log
        echo "Tvault_Horizon_Plugin_Installation PASSED" >> $TEST_RESULTS_FILE
    else
        echo -e "\ntrilioVault horizon plugin installation task is failed\n"  >> $BASE_DIR/master-install.log
        echo "Tvault_Horizon_Plugin_Installation FAILED" >> $TEST_RESULTS_FILE
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
	 echo "Tvault_Configuration PASSED" >> $TEST_RESULTS_FILE
         if [ -n "$additional_nodes_list" ]; then
           ./configure.sh -a -f
           if [ $? -eq 0 ] ; then
              echo -e "\nAdditional nodes configuration is successful" >> $BASE_DIR/master-install.log
              echo -e "\ntrilioVault cluster configuration task is successfully completed\n" >> $BASE_DIR/master-install.log
	      echo "Additional_Node_Configuration PASSED" >> $TEST_RESULTS_FILE
           else
              echo -e "\nController node configuration is successful but additional nodes configuration is failed\ntrilioVault cluster configuration task is failed\n"  >> $BASE_DIR/master-install.log
              echo "Additional_Node_Configuration FAILED" >> $TEST_RESULTS_FILE
              exit 1
           fi
         else
           echo -e "No additional nodes configuration requested, trilioVault cluster configuration is completed\n" >> $BASE_DIR/master-install.log
         fi
     else
        echo -e "\nController node configuration is failed, skipping additional nodes configuration\ntrilioVault cluster configuration task is failed\n"  >> $BASE_DIR/master-install.log
        echo "Tvault_Configuration FAILED" >> $TEST_RESULTS_FILE
        exit 1
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
    ansible-playbook tvault-contego-install.yml
    if [ $? -eq 0 ] ; then
        echo -e "\ntrilioVault contego installation task is successfully completed\n" >> $BASE_DIR/master-install.log
	echo "Tvault_Contego_Installation PASSED" >> $TEST_RESULTS_FILE
    else
        echo -e "\ntrilioVault contego installation task is failed\n"  >> $BASE_DIR/master-install.log
	echo "Tvault_Contego_Installation FAILED" >> $TEST_RESULTS_FILE
        exit 1
    fi

    ansible-playbook contego-service-start.yml
    if [ $? -eq 0 ] ; then
        echo -e "\ntrilioVault contego service is successfully started\n" >> $BASE_DIR/master-install.log
	echo "Start_Contego_Service PASSED" >> $TEST_RESULTS_FILE
    else
        echo -e "\ncouldnot start trilioVault contego service\n"  >> $BASE_DIR/master-install.log
	echo "Start_Contego_Service FAILED" >> $TEST_RESULTS_FILE
        exit 1
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
    ansible-playbook tvault-horizon-plugin-install.yml
    if [ $? -eq 0 ] ; then
        echo -e "\ntrilioVault horizon plugin installation task is successfully completed\n" >> $BASE_DIR/master-install.log
	echo "Tvault_Horizon_Plugin_Installation PASSED" >> $TEST_RESULTS_FILE
    else
        echo -e "\ntrilioVault horizon plugin installation task is failed\n"  >> $BASE_DIR/master-install.log
	echo "Tvault_Horizon_Plugin_Installation FAILED" >> $TEST_RESULTS_FILE
        exit 1
    fi
    if [ -d $BASE_DIR/tvault-horizonplugin-install-ansible-scripts/logs ] ; then
        rm -rf $BASE_DIR/logs/tvault-horizonplugin/
        mkdir -p $BASE_DIR/logs/tvault-horizonplugin/
        cd $BASE_DIR/logs/tvault-horizonplugin/
        cp -R $BASE_DIR/tvault-horizonplugin-install-ansible-scripts/logs/* .
    fi
elif [ "$1" == "--reinitialize" ] ; then
###Reinitializing trilioVault controller node
   echo -e "=====Started reinitializing controller node of trilioVault cluster=====\n"
   cd $BASE_DIR/tvault-config-ansible-scripts/
   pwd
   ./configure.sh -r
   if [ $? -eq 0 ] ; then
      echo -e "\nReinitialization is successful\n" >> $BASE_DIR/master-install.log
   else
      echo -e "\nReinitializaion failed\n"  >> $BASE_DIR/master-install.log
   fi
   if [ -f $BASE_DIR/tvault-config-ansible-scripts/results.txt ] ; then
        rm -rf $BASE_DIR/logs/reinitialize/
        mkdir -p $BASE_DIR/logs/reinitialize/
        cd $BASE_DIR/logs/reinitialize/
        cp $BASE_DIR/tvault-config-ansible-scripts/results.txt .
   fi
elif [ "$1" == "--help" ] ; then
####Help document
    echo -e "Usage:\n./master-install.sh --config      To configure trilioVault cluster(Controller & additional nodes)\n./master-install.sh --config-additional-nodes    To configure additional nodes only \n./master-install.sh --contego     To deploy trilioVault contego extension\n./master-install.sh --horizon     To install trilioVault horizon plugin\n./master-install.sh --all         To perform above all thre tasks(config, contego, horizon plugin)\n./master-install.sh --reinitialize     To reinitialize database of controller node\n./master-install.sh --help        To get help"
    exit 0
else
####Invalid option provided
    echo -e "Invalid option provided, please refer help using --help option\n"
    echo -e "Usage:\n./master-install.sh --config      To configure trilioVault cluster(Controller & additional nodes)\n./master-install.sh --config-additional-nodes    To configure additional nodes only \n./master-install.sh --contego     To deploy trilioVault contego extension\n./master-install.sh --horizon     To install trilioVault horizon plugin\n./master-install.sh --all         To perform above all thre tasks(config, contego, horizon plugin)\n./master-install.sh --reinitialize     To reinitialize database of controller node\n./master-install.sh --help        To get help"
    exit 1
fi


echo -e "\nScript results are stored in master-install.log file, detailed logs can be found under logs/ directory\n"
