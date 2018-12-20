#!/bin/bash -x

sudo su
sed -i '/^PermitRootLogin/c PermitRootLogin yes' /etc/ssh/sshd_config
sed -i '/^PasswordAuthentication/c PasswordAuthentication yes' /etc/ssh/sshd_config
echo 'StrictHostKeyChecking no' >> /etc/ssh/ssh_config
echo 'AllowUsers root stack' >> /etc/ssh/sshd_config
service ssh restart
echo -e "52T8FVYZJse\n52T8FVYZJse" | passwd root

apt-add-repository -y ppa:ansible/ansible-2.6
apt-get update
apt-get install -y ansible
apt-get remove --purge open-vm-tools -y
apt-get upgrade -y
apt-get install -y ubuntu-server open-vm-tools
apt-get install -y python-dev gcc openssl libffi-dev libssl-dev libxml2-dev libxslt-dev lib32z1-dev
apt-get install -y rabbitmq-server
update-rc.d rabbitmq-server defaults
apt-get install -y rpcbind nfs-common python-mysqldb
apt-get install -y apache2
sed -i '/Listen 80/c NameVirtualHost *:3001\nListen 3001' /etc/apache2/ports.conf
service apache2 restart
updatedb
sed -i '/library /c library\        = \/opt\/stack\/workloadmgr\/workloadmgr\/tvault-config\/openstack-ansible-modules\/' /etc/ansible/ansible.cfg

apt-get install -y qemu-kvm libvirt-bin virtinst bridge-utils cpu-checker libguestfs-tools python-guestfs swig
apt-get install -y python-virtualenv

groupadd -g 162 nova
useradd -u 162 -g 162 nova
mkdir /home/nova
cd /home/nova
libguestfs-make-fixed-appliance .
chmod 766 /home/nova
chown -R nova:nova /home/nova
usermod -a -G kvm nova
usermod -a -G libvirtd nova
chmod 644 /boot/vmlinuz*
echo 'user = "nova"
group = "nova"
security_driver = "none"' >> /etc/libvirt/qemu.conf
service libvirt-bin restart
sleep 2s

useradd stack
mkdir /home/stack
chown -R stack:stack /home/stack

echo 'stack ALL=(ALL) NOPASSWD: ALL
nova ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
echo -e "52T8FVYZJse\n52T8FVYZJse" | passwd stack

apt-get remove --purge python-requests -y
apt-get install ntp -y
apt-mark manual python-openssl python-libvirt

#Install grafana
echo "deb https://packagecloud.io/grafana/stable/debian/ stretch main" >> /etc/apt/sources.list
curl https://packagecloud.io/gpg.key | sudo apt-key add -
apt-get update
apt-get install grafana

#install collectd and influxdb
apt-get install -y collectd
apt-get install -y influxdb
sleep 2m

rm -f /etc/influxdb/influxdb.conf
rm -f /etc/collectd/collectd.conf
