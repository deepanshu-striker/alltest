
#!/bin/bash -x

echo "tvault version $TVAULT_VERSION"

export VERSION="$TVAULT_VERSION"

echo $VERSION > /tmp/TVAULT_VERSION
cat /tmp/TVAULT_VERSION

#Generate ssh keys for stack and root users

sudo su stack
cd /home/stack/.ssh
rm -f id_rsa*
ssh-keygen -t rsa -N "" -f id_rsa
sudo su root
cd /root/.ssh
rm -f id_rsa*
ssh-keygen -t rsa -N "" -f id_rsa
echo `cat /root/.ssh/id_rsa.pub` > /root/.ssh/authorized_keys
echo `cat /home/stack/.ssh/id_rsa.pub` >> /root/.ssh/authorized_keys

cd /home/stack
./install_pypi.sh
sleep 5s

cd /home/pypi
mkdir -p packages/
chown -R pypi:pypi packages/
service pypi start

mv /opt/tvault-ansible-scripts* /home/pypi/packages/
mv /opt/premitaka/ /home/pypi/packages/
mv /opt/mitaka/ /home/pypi/packages/
mv /opt/newton/ /home/pypi/packages/
mv /opt/queens_ubuntu/ /home/pypi/packages/
mv /opt/queens_redhat/ /home/pypi/packages/
mv /opt/pip-7.1.2.tar.gz /home/pypi/packages/
mv /opt/trilio-redhat-director-scripts* /home/pypi/packages/
apt-get remove --purge python-pip -y
sleep 2s

cd /home/stack
virtualenv myansible --system-site-packages
source myansible/bin/activate

apt-get update -y
apt-get install build-essential -y 

# making sure pip freezes to 9.0.3
pip install pip==9.0.3

pip install /opt/stack/python-keystoneclient
pip install /opt/stack/python-novaclient
pip install /opt/stack/python-neutronclient
pip install /opt/stack/python-glanceclient
pip install /opt/stack/python-cinderclient
pip install /opt/stack/taskflow
pip install paramiko==1.15.2
pip install lockfile==0.10.2
sleep 2s

cd /opt/stack/contego
make clean
cp MANIFEST.in ../

TVAULT_VERSION=`cat /tmp/TVAULT_VERSION`
echo -e "tvault version: $TVAULT_VERSION"

git checkout setup.py
sed -i "s/os\.getenv('VERSION'.*/\'${TVAULT_VERSION}\'/" setup.py
sed -i "s/os\.getenv('TVAULT_PACKAGE'.*/\'tvault-contego-api\'/" setup.py
echo 'exclude contego/*.*
include contego/__init__.py' > MANIFEST.in
python setup.py sdist
cp dist/tvault-contego* /home/pypi/packages/
#mv ../MANIFEST.in .

git checkout setup.py
> MANIFEST.in
sed -i "s/os\.getenv('VERSION'.*/\'${TVAULT_VERSION}\'/" setup.py
sed -i "s/os\.getenv('TVAULT_PACKAGE'.*/\'tvault-contego\'/" setup.py
echo 'exclude contego/nova/api.py' >> MANIFEST.in
python setup.py sdist
cp dist/tvault-contego* /home/pypi/packages/
rm dist/tvault-contego-*
make clean

cd /opt/stack/python-workloadmgrclient
python setup.py sdist
cp dist/python-workloadmgrclient* /home/pypi/packages/
python setup.py develop

cd /opt/stack/horizon-tvault-plugin
python setup.py sdist
cp dist/tvault-horizon* /home/pypi/packages/

cd /opt/stack/workloadmgr/
python setup.py develop
 
pip install /opt/stack/contego

cd /opt/stack/contegoclient
python setup.py develop

cd /opt/stack/dmapi
sed -i '/version = /c version = '${TVAULT_VERSION}'' setup.cfg
python setup.py sdist
cp dist/dmapi-*.tar.gz /home/pypi/packages/

# upgrading pyOpenSSL using easy_install (pip install doesn't work)
python -m easy_install --upgrade pyOpenSSL

# I found out that it was caused by New cryptography 2.0 upgrade. 
# This upgrade will break many packages using pyopenssl (like Sentry, Google Analytics and etc). 
# Just downgrade it to 1.9 will solve the problem.
pip install cryptography==1.9

cd /home/stack

mkdir -p /etc/ansible/group_vars
echo '---
ansible_python_interpreter: /home/stack/myansible/bin/python' >> /etc/ansible/group_vars/all.yaml

apt-get install -y python-apt

cp -r /usr/lib/python2.7/dist-packages/aptsources/ myansible/lib/python2.7/site-packages/
cp -r /usr/lib/python2.7/dist-packages/apt_pkg.x86_64-linux-gnu.so myansible/lib/python2.7/site-packages
cp -r /usr/lib/python2.7/dist-packages/apt_inst.x86_64-linux-gnu.so myansible/lib/python2.7/site-packages/
cp -r /usr/lib/python2.7/dist-packages/apt myansible/lib/python2.7/site-packages/
cp -r /usr/lib/python2.7/dist-packages/python_apt-1.1.0.b1_ubuntu0.16.04.2.egg-info myansible/lib/python2.7/site-packages/
echo '[triliovault-nodes]
localhost' >> /etc/ansible/hosts
apt-get install -y libmysqlclient-dev
pip install shade
pip install MySQL-python
pip install python-keystoneclient==1.3.4
pip install mysql-connector==2.1.4
pip install boto3
cd /opt/stack/workloadmgr/workloadmgr/tvault-config/ansible-play
ansible-playbook test.yml --tags build_image
ansible-playbook wlm.yml --tags build_image

# install pyOpenSSL==0.15.1
pip install pyOpenSSL==0.15.1

mkdir /var/log/workloadmgr
mkdir -p /var/run/workloadmgr
chown -R nova:nova /var/run/workloadmgr
mkdir -p /var/log/workloadmgr
chown -R nova:nova /var/log/workloadmgr
mkdir -p /var/lock/workloadmgr
chown -R nova:nova /var/lock/workloadmgr
mkdir -p /var/cache/workloadmgr
chown -R nova:nova /var/cache/workloadmgr
touch /var/log/workloadmgr/tvault-config.log
mkdir -p /opt/stack/data

pip install bottle
pip install M2Crypto==0.25.1
pip install configobj==4.7.2
pip install bottle-cork
pip install IPy==0.83
pip install pymongo==3.0.3
pip install keystonemiddleware==1.5.3
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
pip install requests==2.7.0
pip install stevedore==1.3.0
pip install Beaker
pip install retrying==1.3.3
pip install alembic==0.6.3
pip install networkx==1.10
pip install openstacksdk==0.16
pip install pbr==0.11.1
pip install requests==2.7.0
pip install stevedore==1.3.0
pip install python-igraph
pip uninstall pyOpenSSL -y
sleep 5s

deactivate

apt install python-pip -y
easy_install pip==9.0.3 
pip uninstall pyOpenSSL -y
apt-get remove --purge python-pip -y
rm -f /usr/local/bin/pip

ls -l /etc/systemd/system
systemctl daemon-reload
systemctl enable tvault-config.service
systemctl enable grafana-server.service

rm -rf /var/log/grafana/*

service rabbitmq-server stop
sh -c "echo manual > /etc/init/wlm-workloads.override"
sh -c "echo manual > /etc/init/wlm-scheduler.override"
sh -c "echo manual > /etc/init/wlm-api.override"
sh -c "echo manual > /etc/init/rabbitmq-server.override"
rm -rf /var/log/workloadmgr/*
rm -rf /var/cache/workloadmgr/*
rm -rf /opt/stack/data/wlm/snapshots
rm -rf /opt/stack/data/logs
rm -rf /tmp/tvaultlogs
rm -f /etc/tvault-config/tvault-config.conf

echo "Cleaning dirs/files created during build_rpms script"
BASE_DIR="/opt/rpm"
cd /
rm -rf $BASE_DIR
rm -rf ~/rpmbuild
rm -f ~/.rpmmacros

cd /opt/stack/workloadmgr/workloadmgr/tvault-config; /home/stack/myansible/bin/python recreate_conf.py
#/sbin/shutdown -h now

sed -i '/TimeoutStartSec=/c TimeoutStartSec=15sec' /lib/systemd/system/networking.service
systemctl daemon-reload

sed -i '/\/dev\/vdb/d' /etc/fstab
sed -i '/\/dev\/vdc/d' /etc/fstab

echo 'datasource_list: [ NoCloud, ConfigDrive, OpenStack ]' | tee /etc/cloud/cloud.cfg.d/90_dpkg.cfg
dpkg-reconfigure -f noninteractive cloud-init

apt-get -y autoremove
apt-get autoclean
