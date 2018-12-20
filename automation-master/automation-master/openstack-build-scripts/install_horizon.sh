#!/bin/bash

echo -n  "Enter your OpenStack Controller IP address : ";read openstack_controller_ip
if echo "$openstack_controller_ip" | egrep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
then
    VALID_IP_ADDRESS="$(echo $openstack_controller_ip | awk -F'.' '$1 <=255 && $2 <= 255 && $3 <= 255 && $4 <= 255')"
    if [ -z "$VALID_IP_ADDRESS" ]
    then
        echo "Invalid OpenStack Controller IP address provided, exiting\n"
        exit 1
    fi
else
    echo "Invalid OpenStack Controller IP address provided, exiting\n"
    exit 2
fi

cd /opt/stack
git clone -b trilio_old https://github.com/TrilioBuild/horizon.git
if [ $? -ne 0 ]
then
    echo "unable to download horizon code from github, please check if github is resolvable from your trilioVault"
    exit 1
fi

cd /opt/stack/horizon
python setup.py develop
if [ $? -ne 0 ] 
then
    echo "ignoring horizon error"
    continue
fi

pip install /opt/stack/horizon
pip install keystoneauth1==2.6.0
pip install oslo.cache==1.7.0
pip install oslo.log==1.6.0
pip install oslo.i18n==1.5.0
pip install oslo.messaging==1.8.3
pip install oslo.middleware==1.0.0
pip install oslo.policy==0.11.0
pip install oslo.serialization==1.4.0
pip install oslo.utils==1.4.2
pip install oslo.context==0.2.0
pip install WebOb==1.2.3
pip install oslo.config==1.9.3
pip install pbr==0.11.1
pip install django-compressor==1.4
pip install django-openstack-auth==1.2.0
pip install requests==2.7.0
pip install stevedore==1.3.0

cd /opt/stack/horizon
cp openstack_dashboard/local/local_settings.py.example openstack_dashboard/local/local_settings.py

sed -i "/HORIZON_CONFIG = /a \    'customization_module': 'dashboards.overrides'," openstack_dashboard/local/local_settings.py

sed -i "/Specify a regular/i ##TVault configuration\nSTATICFILES_FINDERS = (\n        'compressor.finders.CompressorFinder', \n        'django.contrib.staticfiles.finders.AppDirectoriesFinder', \n         'django.contrib.staticfiles.finders.FileSystemFinder',\n)\n\nSTATICFILES_DIRS = (\n          '/opt/stack/horizon-tvault-plugin/dashboards/static',\n)" openstack_dashboard/local/local_settings.py

sed -i '/OPENSTACK_HOST = /c OPENSTACK_HOST = "'$openstack_controller_ip'"' openstack_dashboard/local/local_settings.py

cat > /etc/apache2/sites-available/horizon.conf <<-EOF
VirtualHost *:3001>
    WSGIScriptAlias / /opt/stack/horizon/openstack_dashboard/wsgi/django.wsgi
    WSGIDaemonProcess horizon user=stack group=stack processes=3 threads=10 home=/opt/stack/horizon
    WSGIApplicationGroup %{GLOBAL}

    SetEnv APACHE_RUN_USER stack
    SetEnv APACHE_RUN_GROUP stack
    WSGIProcessGroup horizon

    DocumentRoot /opt/stack/horizon/.blackhole/
    Alias /media /opt/stack/horizon/openstack_dashboard/static

    <Directory />
        Options FollowSymLinks
        AllowOverride None
    </Directory>

    <Directory /opt/stack/horizon/>
        Options Indexes FollowSymLinks MultiViews
        Require all granted
        AllowOverride None
        Order allow,deny
        allow from all
    </Directory>

    ErrorLog /var/log/apache2/horizon_error.log
    LogLevel warn
    CustomLog /var/log/apache2/horizon_access.log combined
</VirtualHost>

WSGISocketPrefix /var/run/apache2
EOF

cd /opt/stack/horizon-tvault-plugin
python setup.py develop

a2enmod rewrite
service apache2 restart

echo -e "\n\nHorizon dashboard installed successfully. Please run the below command to use horizon dashboard.\ncd /opt/stack/horizon \npython manage.py runserver 0.0.0.0:8082 \n\nYou can now access the dashboard using URL <Tvault IP>:8082 \n\n"
