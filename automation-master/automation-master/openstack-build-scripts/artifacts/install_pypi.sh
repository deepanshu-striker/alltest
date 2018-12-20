#!/bin/bash

PYPI_USER=pypi
PYPI_HOME=/home/$PYPI_USER
PYPI_VENV=/home/pypi/env
PYPI_REPO=/data/pypi/repo
PYPI_PASSWORD=/data/pypi/repo.htaccess

adduser pypi --disabled-password --gecos PYPI --home $PYPI_HOME

apt-get update
apt-get install apache2-utils

#install of dev tools
apt-get install -y python-virtualenv python-dev gcc

cd /
sudo -u $PYPI_USER bash -c "virtualenv $PYPI_VENV; . $PYPI_VENV/bin/activate; easy_install pip==9.0.3; pip list; pip install pypiserver passlib"

sudo bash -c "virtualenv $PYPI_VENV; . $PYPI_VENV/bin/activate; pip install twisted; pip list"
chown -R $PYPI_USER:$PYPI_USER $PYPI_VENV/lib/python2.7/site-packages/
chmod 655 $PYPI_VENV/lib/python2.7/site-packages/*.py

# make repo directory
mkdir -p $PYPI_REPO
chown -R $PYPI_USER $PYPI_REPO

# make password file for uploads
touch $PYPI_PASSWORD
chmod 700 $PYPI_PASSWORD
chown $PYPI_USER $PYPI_PASSWORD

# remove dev env
#apt-get remove --purge python-virtualenv
#apt-get autoremove --purge

#systemd script
cat > /etc/systemd/system/pypi.service <<-EOF
# /etc/systemd/system/pypi.service
[Unit]
Description=pypi
After=pypi.service

[Service]
User=pypi
Group=pypi
Type=simple
ExecStart=/home/pypi/env/bin/pypi-server --interface 0.0.0.0 --port 8081 --server twisted --disable-fallback --passwords /data/pypi/repo.htaccess /home/pypi/packages
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable pypi.service
