#!/bin/bash

BASE_DIR="$(pwd)"

rm -f ${BASE_DIR}/results.txt

ansible-playbook create_configure_vars_file.yml -i ${BASE_DIR}/hosts

if [ $? -ne 0 ] ; then
   exit 1
fi

chmod +x ${BASE_DIR}/vars/tvault-config.answers
source ${BASE_DIR}/vars/tvault-config.answers

if [ $? -ne 0 ] ; then
   exit 1
fi

##Initialize configured nodes
for node in $configured_additional_nodes; do
    array+=($node)
done

if [ "$1" == "--help" -o "$1" == "-h" ] ; then
   echo -e "Usage:\n   ./configure.sh -c|--controller-node      To configure trilioVault cluster's controller node\n   ./configure.sh -a|--additional-nodes     To configure trilioVault cluster's additional nodes. Please note that, before configuring additional nodes\n                                            you need to configure controller node\n   ./configure.sh -a -f                     To reconfigure trilioVault cluster's additional nodes\n   ./configure.sh -r|--reinitialize         To reinitialize controller node\n   ./configure.sh -h|--help                 To get help"
   exit 0
elif [ "$1" == "-a" -a  "$2" == "-f" ] ; then
     if [ -n "$additional_nodes_list" ]; then
        array=()
        for additional_node_ip in $additional_nodes_list; do
                additional_node_host_name="tvault-${additional_node_ip}"
                ansible-playbook $BASE_DIR/site.yml  --vault-password-file ${BASE_DIR}/vars/vault_pass.txt -e "nodetype=additional node_ip=$input guest_name=$additional_node_host_name floating_ipaddress=${additional_node_ip}" -i ${BASE_DIR}/hosts
                if [ $? -eq 0 ] ; then
                    echo -e "Successfully configured trilioVault additional node $additional_node_ip \n" >> ${BASE_DIR}/results.txt
                    array+=($additional_node_ip)
                else
                   echo -e "Failed to configure trilioVault additional node $additional_node_ip\n" >> ${BASE_DIR}/results.txt
                fi

        done
     else
        echo -e "Error: \n  Parameter 'additional_nodes_list' is not set, please set it in vars/tvault-config.answers file" >> ${BASE_DIR}/results.txt
        echo -e "=====RESULTS====================================================================\n"
        cat ${BASE_DIR}/results.txt
        echo -e "================================================================================\n"
        exit 1
     fi
elif [ "$1" == "-a" -o  "$1" == "--additional-nodes" ] ; then
     if [ -n "$additional_nodes_list" ]; then
        for additional_node_ip in $additional_nodes_list; do
            flag=1
            for configured_node in $configured_additional_nodes; do
                if [ "$configured_node" == "$additional_node_ip" ] ; then
                   flag=0
                   break
                fi
            done
            if [ $flag -eq 1 ] ; then
                additional_node_host_name="tvault-${additional_node_ip}"
                ansible-playbook $BASE_DIR/site.yml  --vault-password-file ${BASE_DIR}/vars/vault_pass.txt -e "nodetype=additional node_ip=$input guest_name=$additional_node_host_name floating_ipaddress=${additional_node_ip}" -i ${BASE_DIR}/hosts
                if [ $? -eq 0 ] ; then
                    echo -e "Successfully configured trilioVault additional node $additional_node_ip \n" >> ${BASE_DIR}/results.txt
                    array+=($additional_node_ip)
                else
                   echo -e "Failed to configure trilioVault additional node $additional_node_ip\n" >> ${BASE_DIR}/results.txt
                fi
            else
                echo -e "Already configured additional node: $additional_node_ip , so skipping it.\nIf you want to reconfigure it please use "./configure.sh -a -f" command\n" >> ${BASE_DIR}/results.txt
            fi

        done
     else
        echo -e "Error: \n  Parameter 'additional_nodes_list' is not set, please set it in vars/tvault-config.answers file" >> ${BASE_DIR}/results.txt
        echo -e "=====RESULTS====================================================================\n"
        cat ${BASE_DIR}/results.txt
        echo -e "================================================================================\n"
        exit 1
     fi
elif [ "$1" == "-c" -o  "$1" == "--controller-node" ] ; then
     if [ -n "$controller_node_ip" ]; then
        ansible-playbook $BASE_DIR/site.yml --vault-password-file ${BASE_DIR}/vars/vault_pass.txt -e "floating_ipaddress=${controller_node_ip} nodetype=controller" -i ${BASE_DIR}/hosts
        if [ $? -eq 0 ] ; then
            echo -e "Successfully configured trilioVault controller node $controller_node_ip \n" >> ${BASE_DIR}/results.txt
            echo -e "Please note that you need to reconfigure additional nodes, if you have already configured any\n" >> ${BASE_DIR}/results.txt
        else
            echo -e "Failed to configure trilioVault controller node $controller_node_ip, exiting...\n" >> ${BASE_DIR}/results.txt
            echo -e "=====RESULTS====================================================================\n"
            cat ${BASE_DIR}/results.txt
            echo -e "================================================================================\n"
            exit 1
        fi
     else
        echo -e "Error: \n   Parameter 'controller_node_ip' is not set, please set it in vars/tvault-config.answers file" >> ${BASE_DIR}/results.txt
        echo -e "=====RESULTS====================================================================\n"
        cat ${BASE_DIR}/results.txt
        echo -e "================================================================================\n"
        exit 1
     fi
elif [ "$1" == "-r" -o  "$1" == "--reinitialize" ] ; then
     if [ -n "$controller_node_ip" ]; then
        ansible-playbook $BASE_DIR/reinitialize.yml --vault-password-file ${BASE_DIR}/vars/vault_pass.txt -e "floating_ipaddress=${controller_node_ip}" -i ${BASE_DIR}/hosts
        if [ $? -eq 0 ] ; then
            echo -e "Successfully reinitialized trilioVault controller node $controller_node_ip \n" >> ${BASE_DIR}/results.txt
        else
            echo -e "Failed to reinitialize trilioVault controller node $controller_node_ip, exiting...\n" >> ${BASE_DIR}/results.txt
            echo -e "=====RESULTS====================================================================\n"
            cat ${BASE_DIR}/results.txt
            echo -e "================================================================================\n"
            exit 1
        fi
     else
        echo -e "Error: \n   Parameter 'controller_node_ip' is not set, please set it in vars/tvault-config.answers file" >> ${BASE_DIR}/results.txt
        echo -e "=====RESULTS====================================================================\n"
        cat ${BASE_DIR}/results.txt
        echo -e "================================================================================\n"
        exit 1
     fi
else 
     echo -e "Error: \n   Invalid option provided to script, please check help using --help option"
     exit 1 
fi

echo -e "=====RESULTS====================================================================\n"
cat ${BASE_DIR}/results.txt
echo -e "================================================================================\n"


line="configured_additional_nodes=\"${array[@]}\""
sed -i "/^configured_additional_nodes*/c$line" ${BASE_DIR}/vars/tvault-config.answers


##Cleanup
rm -f ${BASE_DIR}/vars/configure_vars.yml
rm -f ${BASE_DIR}/cookie.txt
if grep -q Failed "${BASE_DIR}/results.txt"; then
    exit 1
fi
