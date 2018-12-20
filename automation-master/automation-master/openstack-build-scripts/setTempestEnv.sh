#!/bin/bash -x

BASE_DIR="$(pwd)"
SETUP_NAME=$1

cd $BASE_DIR/../tempest
git checkout etc/tempest.conf etc/accounts.yaml
#source $BASE_DIR/../deployment-scripts/environments/$SETUP_NAME/build.properties
source ../openstack-build-scripts/$SETUP_NAME/build.properties

case $SETUP_NAME in
    Canonical_Newton_V3) source $BASE_DIR/../deployment-scripts/environments/$SETUP_NAME/wlm-auth.sh;;
    *) source $BASE_DIR/../deployment-scripts/environments/$SETUP_NAME/openstack-auth.sh;;
esac

case $SETUP_NAME in
    Ubuntu_Queens_V3) sed -i '/tenant_name/c \  tenant_name: '\'$OS_PROJECT_NAME\' etc/accounts.yaml
                       sed -i '/admin_domain_name =/c admin_domain_name = '$OS_PROJECT_DOMAIN_NAME'' etc/tempest.conf
                       sed -i '/admin_domain_id =/c admin_domain_id = '$OS_PROJECT_DOMAIN_ID'' etc/tempest.conf
                       sed -i '/admin_tenant_name =/c admin_tenant_name = '$OS_PROJECT_NAME'' etc/tempest.conf
                       sed -i '/^tenant_name =/c tenant_name = '$OS_PROJECT_NAME'' etc/tempest.conf
                       sed -i '/auth_version =/c auth_version = v3' etc/tempest.conf
		       sed -i '/api_v2 = /c api_v2 = False' etc/tempest.conf
		       sed -i '/api_v3 = /c api_v3 = True' etc/tempest.conf
		       sed -i '/admin_tenant_id =/c admin_tenant_id = '$admin_tenant_id'' etc/tempest.conf
		       sed -i '/^tenant_id =/c tenant_id = '$admin_tenant_id'' etc/tempest.conf
		       sed -i '/uri_v3 =/c uri_v3 = http://'$controller_node_ip':5000/v3' etc/tempest.conf;;
    Redhat_Queens_V3_Functional) sed -i '/tenant_name/c \  tenant_name: '\'$OS_PROJECT_NAME\' etc/accounts.yaml
                       sed -i '/admin_domain_name =/c admin_domain_name = '$OS_PROJECT_DOMAIN_NAME'' etc/tempest.conf
                       sed -i '/admin_domain_id =/c admin_domain_id = '$OS_PROJECT_DOMAIN_ID'' etc/tempest.conf
                       sed -i '/admin_tenant_name =/c admin_tenant_name = '$OS_PROJECT_NAME'' etc/tempest.conf
                       sed -i '/^tenant_name =/c tenant_name = '$OS_PROJECT_NAME'' etc/tempest.conf
                       sed -i '/auth_version =/c auth_version = v3' etc/tempest.conf
		       sed -i '/api_v2 = /c api_v2 = False' etc/tempest.conf
		       sed -i '/api_v3 = /c api_v3 = True' etc/tempest.conf
		       sed -i '/admin_tenant_id =/c admin_tenant_id = '$admin_tenant_id'' etc/tempest.conf
		       sed -i '/^tenant_id =/c tenant_id = '$admin_tenant_id'' etc/tempest.conf
		       sed -i '/uri_v3 =/c uri_v3 = http://'$controller_node_ip':5000/v3' etc/tempest.conf;;

    Redhat_Queens_V3) sed -i '/tenant_name/c \  tenant_name: '\'$OS_PROJECT_NAME\' etc/accounts.yaml
                       sed -i '/admin_domain_name =/c admin_domain_name = '$OS_PROJECT_DOMAIN_NAME'' etc/tempest.conf
                       sed -i '/admin_domain_id =/c admin_domain_id = '$OS_PROJECT_DOMAIN_ID'' etc/tempest.conf
                       sed -i '/admin_tenant_name =/c admin_tenant_name = '$OS_PROJECT_NAME'' etc/tempest.conf
                       sed -i '/^tenant_name =/c tenant_name = '$OS_PROJECT_NAME'' etc/tempest.conf
                       sed -i '/auth_version =/c auth_version = v3' etc/tempest.conf
		       sed -i '/api_v2 = /c api_v2 = False' etc/tempest.conf
		       sed -i '/api_v3 = /c api_v3 = True' etc/tempest.conf
		       sed -i '/admin_tenant_id =/c admin_tenant_id = '$admin_tenant_id'' etc/tempest.conf
		       sed -i '/^tenant_id =/c tenant_id = '$admin_tenant_id'' etc/tempest.conf
		       sed -i '/uri_v3 =/c uri_v3 = http://'$controller_node_ip':5000/v3' etc/tempest.conf;;
		       
    Redhat_Liberty_V3) sed -i '/tenant_name/c \  tenant_name: '\'$OS_PROJECT_NAME\' etc/accounts.yaml
                       sed -i '/admin_domain_name =/c admin_domain_name = '$OS_PROJECT_DOMAIN_NAME'' etc/tempest.conf
                       sed -i '/admin_domain_id =/c admin_domain_id = '$OS_PROJECT_DOMAIN_ID'' etc/tempest.conf
                       sed -i '/admin_tenant_name =/c admin_tenant_name = '$OS_PROJECT_NAME'' etc/tempest.conf
                       sed -i '/^tenant_name =/c tenant_name = '$OS_PROJECT_NAME'' etc/tempest.conf
                       sed -i '/auth_version =/c auth_version = v3' etc/tempest.conf
                       sed -i '/default_credentials_domain_name =/c default_credentials_domain_name = '$OS_PROJECT_DOMAIN_NAME'' etc/tempest.conf
		       sed -i '/api_v2 = /c api_v2 = False' etc/tempest.conf
		       sed -i '/api_v3 = /c api_v3 = True' etc/tempest.conf
		       sed -i '/admin_tenant_id =/c admin_tenant_id = '$admin_tenant_id'' etc/tempest.conf
		       sed -i '/^tenant_id =/c tenant_id = '$admin_tenant_id'' etc/tempest.conf
		       sed -i '/^default_credentials_domain_name =/c default_credentials_domain_name = '$PROJECT_DOMAIN_NAME'' etc/tempest.conf
                       sed -i '/uri_v3 =/c uri_v3 = http://'$controller_node_ip':5000/v3' etc/tempest.conf;;

    Mirantis_Mitaka_V2_Ceph) sed -i '/disable_ssl_certificate_validation=/c disable_ssl_certificate_validation=True' etc/tempest.conf
                             sed -i '/vm_availability_zone = /c vm_availability_zone = '$vm_availability_zone'' etc/tempest.conf
                             sed -i '/api_v2 = /c api_v2 = True' etc/tempest.conf
                             sed -i '/api_v3 = /c api_v3 = False' etc/tempest.conf
                             sed -i '/tenant_name/c \  tenant_name: '\'$OS_TENANT_NAME\' etc/accounts.yaml
                             sed -i '/admin_tenant_name =/c admin_tenant_name = '$OS_TENANT_NAME'' etc/tempest.conf
                             sed -i '/^tenant_name =/c tenant_name = '$OS_TENANT_NAME'' etc/tempest.conf
		             sed -i '/admin_tenant_id =/c admin_tenant_id = '$admin_tenant_id'' etc/tempest.conf
			     sed -i '/^tenant_id =/c tenant_id = '$admin_tenant_id'' etc/tempest.conf
                             sed -i '/uri =/c uri = http://'$controller_node_ip':5000/v2.0/' etc/tempest.conf
                             sed -i '/insecure = /c insecure = True' etc/tempest.conf;;

    Canonical_Newton_V3) sed -i '/tenant_name/c \  tenant_name: '\'$OS_PROJECT_NAME\' etc/accounts.yaml
                       sed -i '/admin_domain_name =/c admin_domain_name = '$OS_PROJECT_DOMAIN_NAME'' etc/tempest.conf
                       sed -i '/admin_domain_id =/c admin_domain_id = '$OS_DOMAIN_ID'' etc/tempest.conf
                       sed -i '/admin_tenant_name =/c admin_tenant_name = '$OS_PROJECT_NAME'' etc/tempest.conf
                       sed -i '/^tenant_name =/c tenant_name = '$OS_PROJECT_NAME'' etc/tempest.conf
                       sed -i '/auth_version =/c auth_version = v3' etc/tempest.conf
                       sed -i '/default_credentials_domain_name =/c default_credentials_domain_name = '$OS_PROJECT_DOMAIN_NAME'' etc/tempest.conf
                       sed -i '/api_v2 = /c api_v2 = False' etc/tempest.conf
                       sed -i '/api_v3 = /c api_v3 = True' etc/tempest.conf
		       sed -i '/admin_tenant_id =/c admin_tenant_id = '$OS_TENANT_ID'' etc/tempest.conf
    		       sed -i '/^tenant_id =/c tenant_id = '$admin_tenant_id'' etc/tempest.conf
		       sed -i '/region =/c region = '$OS_REGION_NAME'' etc/tempest.conf
                       sed -i '/uri_v3 =/c uri_v3 = http://'$controller_node_ip':5000/v3' etc/tempest.conf;;

    Suse_Cloud7) sed -i '/tenant_name/c \  tenant_name: '\'$OS_PROJECT_NAME\' etc/accounts.yaml
                 sed -i '/admin_domain_name =/c admin_domain_name = '$OS_PROJECT_DOMAIN_NAME'' etc/tempest.conf
                 sed -i '/admin_domain_id =/c admin_domain_id = '$OS_PROJECT_DOMAIN_ID'' etc/tempest.conf
                 sed -i '/admin_tenant_name =/c admin_tenant_name = '$OS_PROJECT_NAME'' etc/tempest.conf
                 sed -i '/^tenant_name =/c tenant_name = '$OS_PROJECT_NAME'' etc/tempest.conf
                 sed -i '/auth_version =/c auth_version = v3' etc/tempest.conf
                 sed -i '/default_credentials_domain_name =/c default_credentials_domain_name = '$OS_PROJECT_DOMAIN_NAME'' etc/tempest.conf
                 sed -i '/api_v2 = /c api_v2 = False' etc/tempest.conf
                 sed -i '/api_v3 = /c api_v3 = True' etc/tempest.conf
                 sed -i '/admin_tenant_id =/c admin_tenant_id = '$admin_tenant_id'' etc/tempest.conf
                 sed -i '/^tenant_id =/c tenant_id = '$admin_tenant_id'' etc/tempest.conf
                 sed -i '/uri_v3 =/c uri_v3 = https://'$controller_node_ip':5000/v3' etc/tempest.conf
		 sed -i '/disable_ssl_certificate_validation=/c disable_ssl_certificate_validation=True' etc/tempest.conf
		 sed -i '/insecure =/c insecure = True' etc/tempest.conf
		 sed -i 's/workloadmgr /workloadmgr --insecure /' tempest/command_argument_string.py;;

    *) sed -i '/tenant_name/c \  tenant_name: '\'$OS_TENANT_NAME\' etc/accounts.yaml
       sed -i '/admin_tenant_name =/c admin_tenant_name = '$OS_TENANT_NAME'' etc/tempest.conf
       sed -i '/^tenant_name =/c tenant_name = '$OS_TENANT_NAME'' etc/tempest.conf
       sed -i '/api_v2 = /c api_v2 = True' etc/tempest.conf
       sed -i '/api_v3 = /c api_v3 = False' etc/tempest.conf
       sed -i '/admin_tenant_id =/c admin_tenant_id = '$admin_tenant_id'' etc/tempest.conf
       sed -i '/^tenant_id =/c tenant_id = '$admin_tenant_id'' etc/tempest.conf
       sed -i '/region =/c region = RegionOne' etc/tempest.conf
       sed -i '/uri =/c uri = http://'$controller_node_ip':5000/v2.0/' etc/tempest.conf;;
esac

#Update the required configuration variables
sed -i '/username/c - username: '\'$OS_USERNAME\' etc/accounts.yaml
sed -i '/password/c \  password: '\'$OS_PASSWORD\' etc/accounts.yaml

sed -i '/image_ref =/c image_ref = '$cirros_id'' etc/tempest.conf
sed -i '/admin_password =/c admin_password = '$OS_PASSWORD'' etc/tempest.conf
#sed -i '/alt_password =/c alt_password = '$OS_PASSWORD'' etc/tempest.conf
sed -i '/^password =/c password = '$OS_PASSWORD'' etc/tempest.conf
sed -i '/^username =/c username = '$OS_USERNAME'' etc/tempest.conf
sed -i '/^internal_network_id =/c internal_network_id = '$fixed_network_id'' etc/tempest.conf
sed -i '/admin_username =/c admin_username = '$OS_USERNAME'' etc/tempest.conf
sed -i '/os_tenant_id =/c os_tenant_id = '$services_tenant_id'' etc/tempest.conf
sed -i '/flavor_ref =/c flavor_ref = '$flavor_id'' etc/tempest.conf
sed -i '/test_accounts_file =/c test_accounts_file = '$PWD"/etc/accounts.yaml"'' etc/tempest.conf
sed -i '/login_url =/c login_url = http://'$controller_node_ip'/auth/login/' etc/tempest.conf
sed -i '/dashboard_url =/c dashboard_url = http://'$controller_node_ip'\/' etc/tempest.conf
sed -i '/volume_type_id_1 =/c volume_type_id_1 = '$lvm_volume_type'' etc/tempest.conf
sed -i '/volume_type_id =/c volume_type_id = '$ceph_volume_type'' etc/tempest.conf

sed -i '/tvault_ip =/c tvault_ip = \"'$floating_ip'"' tempest/tvaultconf.py
sed -i '/compute_ip =/c compute_ip = \"'$compute_node_ip'"' tempest/tvaultconf.py
sed -i '/bootfromvol_vol_size =/c bootfromvol_vol_size = 1' tempest/tvaultconf.py

