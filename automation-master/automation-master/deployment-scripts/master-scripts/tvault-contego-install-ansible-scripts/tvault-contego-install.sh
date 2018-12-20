#!/bin/bash

# Translate the OS version values into common nomenclature
# Sets global ``DISTRO`` from the ``os_*`` values
declare DISTRO

TVAULT_CONTEGO_CONF=/etc/tvault-contego/tvault-contego.conf

function GetOpenStackRelease {
    NOVA_VERSION=`nova-manage version | awk -F. '{print $1}'`

    if [[ "$NOVA_VERSION" -eq "2015" ]]; then
        export OPEN_STACK_RELEASE="premitaka"
    elif [[ "$NOVA_VERSION" -eq "12" ]]; then
        export OPEN_STACK_RELEASE="premitaka"
    else
        export OPEN_STACK_RELEASE="mitaka"
    fi
}

GetOpenStackRelease

# GetOSVersion
function GetOSVersion {

    # Figure out which vendor we are
    if [[ -x "`which sw_vers 2>/dev/null`" ]]; then
        # OS/X
        os_VENDOR=`sw_vers -productName`
        os_RELEASE=`sw_vers -productVersion`
        os_UPDATE=${os_RELEASE##*.}
        os_RELEASE=${os_RELEASE%.*}
        os_PACKAGE=""
        if [[ "$os_RELEASE" =~ "10.7" ]]; then
            os_CODENAME="lion"
        elif [[ "$os_RELEASE" =~ "10.6" ]]; then
            os_CODENAME="snow leopard"
        elif [[ "$os_RELEASE" =~ "10.5" ]]; then
            os_CODENAME="leopard"
        elif [[ "$os_RELEASE" =~ "10.4" ]]; then
            os_CODENAME="tiger"
        elif [[ "$os_RELEASE" =~ "10.3" ]]; then
            os_CODENAME="panther"
        else
            os_CODENAME=""
        fi
    elif [[ -x $(which lsb_release 2>/dev/null) ]]; then
        os_VENDOR=$(lsb_release -i -s)
        os_RELEASE=$(lsb_release -r -s)
        os_UPDATE=""
        os_PACKAGE="rpm"
        if [[ "Debian,Ubuntu,LinuxMint" =~ $os_VENDOR ]]; then
            os_PACKAGE="deb"
        elif [[ "SUSE LINUX" =~ $os_VENDOR ]]; then
            lsb_release -d -s | grep -q openSUSE
            if [[ $? -eq 0 ]]; then
                os_VENDOR="openSUSE"
            fi
        elif [[ $os_VENDOR == "openSUSE project" ]]; then
            os_VENDOR="openSUSE"
        elif [[ $os_VENDOR =~ Red.*Hat ]]; then
            os_VENDOR="Red Hat"
        fi
        os_CODENAME=$(lsb_release -c -s)
    elif [[ -r /etc/redhat-release ]]; then
        # Red Hat Enterprise Linux Server release 5.5 (Tikanga)
        # Red Hat Enterprise Linux Server release 7.0 Beta (Maipo)
        # CentOS release 5.5 (Final)
        # CentOS Linux release 6.0 (Final)
        # Fedora release 16 (Verne)
        # XenServer release 6.2.0-70446c (xenenterprise)
        # Oracle Linux release 7
        os_CODENAME=""
        for r in "Red Hat" CentOS Fedora XenServer; do
            os_VENDOR=$r
            if [[ -n "`grep \"$r\" /etc/redhat-release`" ]]; then
                ver=`sed -e 's/^.* \([0-9].*\) (\(.*\)).*$/\1\|\2/' /etc/redhat-release`
                os_CODENAME=${ver#*|}
                os_RELEASE=${ver%|*}
                os_UPDATE=${os_RELEASE##*.}
                os_RELEASE=${os_RELEASE%.*}
                break
            fi
            os_VENDOR=""
        done
        if [ "$os_VENDOR" = "Red Hat" ] && [[ -r /etc/oracle-release ]]; then
            os_VENDOR=OracleLinux
        fi
        os_PACKAGE="rpm"
    elif [[ -r /etc/SuSE-release ]]; then
        for r in openSUSE "SUSE Linux"; do
            if [[ "$r" = "SUSE Linux" ]]; then
                os_VENDOR="SUSE LINUX"
            else
                os_VENDOR=$r
            fi

            if [[ -n "`grep \"$r\" /etc/SuSE-release`" ]]; then
                os_CODENAME=`grep "CODENAME = " /etc/SuSE-release | sed 's:.* = ::g'`
                os_RELEASE=`grep "VERSION = " /etc/SuSE-release | sed 's:.* = ::g'`
                os_UPDATE=`grep "PATCHLEVEL = " /etc/SuSE-release | sed 's:.* = ::g'`
                break
            fi
            os_VENDOR=""
        done
        os_PACKAGE="rpm"
    # If lsb_release is not installed, we should be able to detect Debian OS
    elif [[ -f /etc/debian_version ]] && [[ $(cat /proc/version) =~ "Debian" ]]; then
        os_VENDOR="Debian"
        os_PACKAGE="deb"
        os_CODENAME=$(awk '/VERSION=/' /etc/os-release | sed 's/VERSION=//' | sed -r 's/\"|\(|\)//g' | awk '{print $2}')
        os_RELEASE=$(awk '/VERSION_ID=/' /etc/os-release | sed 's/VERSION_ID=//' | sed 's/\"//g')
    fi
    export os_VENDOR os_RELEASE os_UPDATE os_PACKAGE os_CODENAME
}

function GetDistro {
    GetOSVersion
    if [[ "$os_VENDOR" =~ (Ubuntu) || "$os_VENDOR" =~ (Debian) ]]; then
        # 'Everyone' refers to Ubuntu / Debian releases by the code name adjective
        DISTRO=$os_CODENAME
    elif [[ "$os_VENDOR" =~ (Fedora) ]]; then
        # For Fedora, just use 'f' and the release
        DISTRO="f$os_RELEASE"
    elif [[ "$os_VENDOR" =~ (openSUSE) ]]; then
        DISTRO="opensuse-$os_RELEASE"
    elif [[ "$os_VENDOR" =~ (SUSE LINUX) ]]; then
        # For SLE, also use the service pack
        if [[ -z "$os_UPDATE" ]]; then
            DISTRO="sle${os_RELEASE}"
        else
            DISTRO="sle${os_RELEASE}sp${os_UPDATE}"
        fi
    elif [[ "$os_VENDOR" =~ (Red Hat) || \
        "$os_VENDOR" =~ (CentOS) || \
        "$os_VENDOR" =~ (OracleLinux) ]]; then
        # Drop the . release as we assume it's compatible
        DISTRO="rhel${os_RELEASE::1}"
    elif [[ "$os_VENDOR" =~ (XenServer) ]]; then
        DISTRO="xs$os_RELEASE"
    else
        # Catch-all for now is Vendor + Release + Update
        DISTRO="$os_VENDOR-$os_RELEASE.$os_UPDATE"
    fi
    export DISTRO
}

# Utility function for checking machine architecture
# is_arch arch-type
function is_arch {
    [[ "$(uname -m)" == "$1" ]]
}

# Determine if current distribution is an Oracle distribution
# is_oraclelinux
function is_oraclelinux {
    if [[ -z "$os_VENDOR" ]]; then
        GetOSVersion
    fi

    [ "$os_VENDOR" = "OracleLinux" ]
}


# Determine if current distribution is a Fedora-based distribution
# (Fedora, RHEL, CentOS, etc).
# is_fedora
function is_fedora {
    if [[ -z "$os_VENDOR" ]]; then
        GetOSVersion
    fi

    [ "$os_VENDOR" = "Fedora" ] || [ "$os_VENDOR" = "Red Hat" ] || \
        [ "$os_VENDOR" = "CentOS" ] || [ "$os_VENDOR" = "OracleLinux" ]
}


# Determine if current distribution is a SUSE-based distribution
# (openSUSE, SLE).
# is_suse
function is_suse {
    if [[ -z "$os_VENDOR" ]]; then
        GetOSVersion
    fi

    [ "$os_VENDOR" = "openSUSE" ] || [ "$os_VENDOR" = "SUSE LINUX" ]
}


# Determine if current distribution is an Ubuntu-based distribution
# It will also detect non-Ubuntu but Debian-based distros
# is_ubuntu
function is_ubuntu {
    if [[ -z "$os_PACKAGE" ]]; then
        GetOSVersion
    fi
    [ "$os_PACKAGE" = "deb" ]
}

# Exit after outputting a message about the distribution not being supported.
# exit_distro_not_supported [optional-string-telling-what-is-missing]
function exit_distro_not_supported {
    if [[ -z "$DISTRO" ]]; then
        GetDistro
    fi

    if [ $# -gt 0 ]; then
        die $LINENO "Support for $DISTRO is incomplete: no support for $@"
    else
        die $LINENO "Support for $DISTRO is incomplete."
    fi
}

# Set an option in an INI file
function ini_get_option() {
    local xtrace=$(set +o | grep xtrace)
    set +o xtrace
    local file=$1
    local section=$2
    local option=$3
    local remove=$4
    local line
    line=$(sed -ne "/^\[$section\]/,/^\[.*\]/ { /^$option[ \t]*=/ p; }" "$file")
    $xtrace
    echo "$line"
    if [ "$remove" = "yes" ] && [ ! -z "$line" ]; then
        grep -v "$line" "$file" > "$file.bak"
        mv "$file.bak" "$file"
    fi
}

# Determinate is the given option present in the INI file
# ini_has_option config-file section option
function ini_has_option() {
    local xtrace=$(set +o | grep xtrace)
    set +o xtrace
    local file=$1
    local section=$2
    local option=$3
    local line

    line=$(sed -ne "/^\[$section\]/,/^\[.*\]/ { /^$option[ \t]*=/ p; }" "$file")
    $xtrace
    [ -n "$line" ]
}

# iniset config-file section option value
function iniset() {
    local file=$1
    local section=$2
    local option=$3
    local value=$4
    if ! grep -q "^\[$section\]" "$file"; then
        # Add section at the end
        echo -e "\n[$section]" >>"$file"
    fi
    if ! ini_has_option "$file" "$section" "$option"; then
        # Add it
        sed -i -e "/^\[$section\]/ a\\
$option = $value
" "$file"
    else
        # Replace it
        sed -i -e "/^\[$section\]/,/^\[.*\]/ s|^\($option[ \t]*=[ \t]*\).*$|\1$value|" "$file"
    fi
}

# Set a multiple line option in an INI file
# iniset_multiline config-file section option value1 value2 valu3 ...
function iniset_multiline() {
    local file=$1
    local section=$2
    local option=$3
    shift 3
    local values
    for v in $@; do
        # The later sed command inserts each new value in the line next to
        # the section identifier, which causes the values to be inserted in
        # the reverse order. Do a reverse here to keep the original order.
        values="$v ${values}"
    done
    if ! grep -q "^\[$section\]" "$file"; then
        # Add section at the end
        echo -e "\n[$section]" >>"$file"
    else
        # Remove old values
        sed -i -e "/^\[$section\]/,/^\[.*\]/ { /^$option[ \t]*=/ d; }" "$file"
    fi
    # Add new ones
    for v in $values; do
        sed -i -e "/^\[$section\]/ a\\
$option = $v
" "$file"
    done
}


function cretae_tvault_swift_service_wily() {
cat > /etc/systemd/system/tvault-swift.service <<-EOF
[Unit]
Description=Tvault swift
After=tvault-contego.service

[Service]
User=$TVAULT_CONTEGO_EXT_USER
Group=$TVAULT_CONTEGO_EXT_USER

Type=simple
ExecStart=$TVAULT_CONTEGO_EXT_PYTHON $TVAULT_CONTEGO_EXT_SWIFT --config-file=$TVAULT_CONTEGO_CONF
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
}

function create_tvault_swift_service_init() {
cat > /etc/init/tvault-swift.conf <<-EOF
description "TrilioVault Swift"
author "TrilioData <info@triliodata.com>"
start on (filesystem and net-device-up IFACE!=lo)
stop on runlevel [016]
respawn
chdir /var/run
pre-start script
    if [ ! -d /var/run/$TVAULT_CONTEGO_EXT_USER ]; then
        mkdir /var/run/$TVAULT_CONTEGO_EXT_USER
        chown root:$TVAULT_CONTEGO_EXT_USER /var/run/$TVAULT_CONTEGO_EXT_USER
    fi
    if [ ! -d /var/lock/$TVAULT_CONTEGO_EXT_USER ]; then
        mkdir -p /var/lock/$TVAULT_CONTEGO_EXT_USER
        chown root:$TVAULT_CONTEGO_EXT_USER /var/lock/$TVAULT_CONTEGO_EXT_USER
    fi
    if [ -f /var/log/nova/tvault-contego.log ]; then
       chown $TVAULT_CONTEGO_EXT_USER:$TVAULT_CONTEGO_EXT_USER /var/log/nova/tvault-contego.log
    fi
end script
script
    exec start-stop-daemon --start --chuid $TVAULT_CONTEGO_EXT_USER --exec $TVAULT_CONTEGO_EXT_PYTHON $TVAULT_CONTEGO_EXT_SWIFT -- --config-file=$TVAULT_CONTEGO_CONF
end script
EOF
}

function create_tvault_swift_service_initd() {
cat > /etc/init.d/tvault-swift <<-EOF
#!/bin/sh
#
# tvault-swift  OpenStack Nova Compute Extension
#
# chkconfig:   - 98 02
# description: OpenStack Nova Compute Extension To Snapshot Virtual\
#               machines.
### BEGIN INIT INFO
# Provides:
# Required-Start: \$remote_fs \$network \$syslog
# Required-Stop: \$remote_fs \$syslog
# Default-Stop: 0 1 6
# Short-Description: OpenStack Nova Compute Extension
# Description: OpenStack Nova Compute Extension To Snapshot Virtual
#               machines.
### END INIT INFO
. /etc/rc.d/init.d/functions
prog=tvault-swift
exec=$TVAULT_CONTEGO_EXT_PYTHON $TVAULT_CONTEGO_EXT_SWIFT
pidfile="/var/run/$TVAULT_CONTEGO_EXT_USER/\$prog.pid"
configfiles="--config-file=$TVAULT_CONTEGO_CONF"
[ -e /etc/sysconfig/\$prog ] && . /etc/sysconfig/\$prog
lockfile=/var/lock/subsys/\$prog
start() {
    [ -x \$exec ] || exit 5
    [ -f \$config ] || exit 6
    echo -n \$"Starting \$prog: "
    daemon --user $TVAULT_CONTEGO_EXT_USER --pidfile \$pidfile "\$exec \$configfiles &>/dev/null & echo \\\$! > \$pidfile"
    retval=\$?
    echo
    [ \$retval -eq 0 ] && touch \$lockfile
    return \$retval
}
stop() {
    echo -n \$"Stopping \$prog: "
    killproc -p \$pidfile \$prog
    retval=\$?
    echo
    [ \$retval -eq 0 ] && rm -f \$lockfile
    return \$retval
}
restart() {
    stop
    start
}
reload() {
    restart
}
force_reload() {
    restart
}
rh_status() {
    status -p \$pidfile \$prog
}
rh_status_q() {
    rh_status >/dev/null 2>&1
}
case "\$1" in
    start)
        rh_status_q && exit 0
        \$1
        ;;
    stop)
        rh_status_q || exit 0
        \$1
        ;;
    restart)
        \$1
        ;;
    reload)
        rh_status_q || exit 7
        \$1
        ;;
    force-reload)
        force_reload
        ;;
    status)
        rh_status
        ;;
    condrestart|try-restart)
        rh_status_q || exit 0
        restart
        ;;
    *)
        echo \$"Usage: \$0 {start|stop|status|restart|condrestart|try-restart|reload|force-reload}"
        exit 2
esac
exit \$?
EOF
chmod +x /etc/init.d/tvault-swift
}

function create_tvault_swift_service_systemd() {
cat > /usr/lib/systemd/system/tvault-swift.service <<-EOF
[Unit]
Description=TrilioVault Swift
After=tvault-contego.service
[Service]
Environment=LIBGUESTFS_ATTACH_METHOD=appliance
Type=simple
TimeoutStartSec=0
Restart=always
User=$TVAULT_CONTEGO_EXT_USER
ExecStart=$TVAULT_CONTEGO_EXT_PYTHON $TVAULT_CONTEGO_EXT_SWIFT --config-file=$TVAULT_CONTEGO_CONF
[Install]
WantedBy=multi-user.target
EOF
}

function cretae_tvault_contego_service_wily() {
cat > /etc/systemd/system/tvault-contego.service <<-EOF
[Unit]
Description=Tvault contego
After=openstack-nova-compute.service

[Service]
User=$TVAULT_CONTEGO_EXT_USER
Group=$TVAULT_CONTEGO_EXT_USER

Type=simple
ExecStart=$TVAULT_CONTEGO_EXT_PYTHON $TVAULT_CONTEGO_EXT_BIN $CONFIG_FILES
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
}

### Upstart ###
function create_tvault_contego_service_init() {
cat > /etc/init/tvault-contego.conf <<-EOF
description "TrilioVault Contego - Openstack Nova Compute Extension"
author "TrilioData <info@triliodata.com>"
start on (filesystem and net-device-up IFACE!=lo)
stop on runlevel [016]
respawn
chdir /var/run
pre-start script
    if [ ! -d /var/run/$TVAULT_CONTEGO_EXT_USER ]; then
        mkdir /var/run/$TVAULT_CONTEGO_EXT_USER
        chown root:$TVAULT_CONTEGO_EXT_USER /var/run/$TVAULT_CONTEGO_EXT_USER
    fi
    if [ ! -d /var/lock/$TVAULT_CONTEGO_EXT_USER ]; then
        mkdir -p /var/lock/$TVAULT_CONTEGO_EXT_USER
        chown root:$TVAULT_CONTEGO_EXT_USER /var/lock/$TVAULT_CONTEGO_EXT_USER
    fi
    if [ -f /var/log/nova/tvault-contego.log ]; then
       chown $TVAULT_CONTEGO_EXT_USER:$TVAULT_CONTEGO_EXT_USER /var/log/nova/tvault-contego.log
    fi
end script
script
    exec start-stop-daemon --start --chuid $TVAULT_CONTEGO_EXT_USER --exec $TVAULT_CONTEGO_EXT_PYTHON $TVAULT_CONTEGO_EXT_BIN -- $CONFIG_FILES
end script
EOF
}


### Initd ###
function create_tvault_contego_service_initd() {
cat > /etc/init.d/tvault-contego <<-EOF
#!/bin/sh
#
# tvault-contego  OpenStack Nova Compute Extension
#
# chkconfig:   - 98 02
# description: OpenStack Nova Compute Extension To Snapshot Virtual\
#               machines.
### BEGIN INIT INFO
# Provides:
# Required-Start: \$remote_fs \$network \$syslog
# Required-Stop: \$remote_fs \$syslog
# Default-Stop: 0 1 6
# Short-Description: OpenStack Nova Compute Extension
# Description: OpenStack Nova Compute Extension To Snapshot Virtual
#               machines.
### END INIT INFO
. /etc/rc.d/init.d/functions
prog=tvault-contego
exec=$TVAULT_CONTEGO_EXT_PYTHON $TVAULT_CONTEGO_EXT_BIN
pidfile="/var/run/$TVAULT_CONTEGO_EXT_USER/\$prog.pid"
configfiles="$CONFIG_FILES"
[ -e /etc/sysconfig/\$prog ] && . /etc/sysconfig/\$prog
lockfile=/var/lock/subsys/\$prog
start() {
    [ -x \$exec ] || exit 5
    [ -f \$config ] || exit 6
    echo -n \$"Starting \$prog: "
    daemon --user $TVAULT_CONTEGO_EXT_USER --pidfile \$pidfile "\$exec \$configfiles &>/dev/null & echo \\\$! > \$pidfile"
    retval=\$?
    echo
    [ \$retval -eq 0 ] && touch \$lockfile
    return \$retval
}
stop() {
    echo -n \$"Stopping \$prog: "
    killproc -p \$pidfile \$prog
    retval=\$?
    echo
    [ \$retval -eq 0 ] && rm -f \$lockfile
    return \$retval
}
restart() {
    stop
    start
}
reload() {
    restart
}
force_reload() {
    restart
}
rh_status() {
    status -p \$pidfile \$prog
}
rh_status_q() {
    rh_status >/dev/null 2>&1
}
case "\$1" in
    start)
        rh_status_q && exit 0
        \$1
        ;;
    stop)
        rh_status_q || exit 0
        \$1
        ;;
    restart)
        \$1
        ;;
    reload)
        rh_status_q || exit 7
        \$1
        ;;
    force-reload)
        force_reload
        ;;
    status)
        rh_status
        ;;
    condrestart|try-restart)
        rh_status_q || exit 0
        restart
        ;;
    *)
        echo \$"Usage: \$0 {start|stop|status|restart|condrestart|try-restart|reload|force-reload}"
        exit 2
esac
exit \$?
EOF
chmod +x /etc/init.d/tvault-contego
}



### Systemd ###
function create_tvault_contego_service_systemd() {
cat > /usr/lib/systemd/system/tvault-contego.service <<-EOF
[Unit]
Description=TrilioVault Contego - Openstack Nova Compute Extension
After=openstack-nova-compute.service
[Service]
Environment=LIBGUESTFS_ATTACH_METHOD=appliance
Type=notify
NotifyAccess=all
TimeoutStartSec=0
Restart=always
User=$TVAULT_CONTEGO_EXT_USER
ExecStart=$TVAULT_CONTEGO_EXT_PYTHON $TVAULT_CONTEGO_EXT_BIN $CONFIG_FILES
[Install]
WantedBy=multi-user.target
EOF
}

###Function for mount backend#####

function create_contego_conf_nfs() {

NFS_OP="$NFS_OPTIONS"
if [ "$NFS_OPTIONS" == "" ]; then
   NFS_OP="nolock"
fi

cat > $TVAULT_CONTEGO_CONF <<-EOF
[DEFAULT]
vault_storage_nfs_export = $NFS_SHARES
vault_storage_nfs_options = $NFS_OP
vault_storage_type = nfs
vault_data_directory_old = /var/triliovault
vault_data_directory = /var/triliovault-mounts
log_file = /var/log/nova/tvault-contego.log
debug = False
verbose = True
max_uploads_pending = 3
EOF

if [ ! -d $VAULT_DATA_DIR ]; then
   mkdir -p "$VAULT_DATA_DIR"
   chown nova:"$TVAULT_CONTEGO_EXT_USER" "$VAULT_DATA_DIR"
else
    rm -rf $VAULT_DATA_DIR/*
    chown $TVAULT_CONTEGO_EXT_USER:$TVAULT_CONTEGO_EXT_USER $VAULT_DATA_DIR
fi

}

function create_contego_conf_swift() {
cat > $TVAULT_CONTEGO_CONF <<-EOF
[DEFAULT]
vault_storage_type = swift-s
vault_storage_nfs_export = TrilioVault
vault_data_directory_old = $VAULT_DATA_DIR_OLD
vault_data_directory = $VAULT_DATA_DIR
log_file = /var/log/nova/tvault-contego.log
debug = False
verbose = True
max_uploads_pending = 3
vault_swift_auth_url = $VAULT_SWIFT_AUTH_URL
vault_swift_username = $VAULT_SWIFT_USERNAME
vault_swift_password = $VAULT_SWIFT_PASSWORD
vault_swift_auth_version = $VAULT_SWIFT_AUTH_VERSION
vault_swift_domain_id = $VAULT_SWIFT_DOMAIN_ID
vault_swift_tenant = $VAULT_SWIFT_TENANT
EOF

if [ ! -d $VAULT_DATA_DIR ]; then
   mkdir -p $VAULT_DATA_DIR
   chown $TVAULT_CONTEGO_EXT_USER:$TVAULT_CONTEGO_EXT_USER $VAULT_DATA_DIR
else
    rm -rf $VAULT_DATA_DIR/*
    chown $TVAULT_CONTEGO_EXT_USER:$TVAULT_CONTEGO_EXT_USER $VAULT_DATA_DIR
fi

if [ ! -d $VAULT_DATA_DIR_OLD ]; then
   mkdir -p $VAULT_DATA_DIR_OLD
   chown $TVAULT_CONTEGO_EXT_USER:$TVAULT_CONTEGO_EXT_USER $VAULT_DATA_DIR_OLD
else
     rm -rf $VAULT_DATA_DIR_OLD/*
     chown $TVAULT_CONTEGO_EXT_USER:$TVAULT_CONTEGO_EXT_USER $VAULT_DATA_DIR_OLD
fi

}
##############

function create_contego_logrotate() {
cat > /etc/logrotate.d/tvault-contego <<-EOF
/var/log/nova/tvault-contego.log {
    daily
        missingok
        notifempty
        copytruncate
        size=25M
        rotate 3
        compress
}
EOF
}

function is_nova_read_writable() {
    SHARES_ARRAY=(${NFS_SHARES//,/ })
    for key in "${!SHARES_ARRAY[@]}"
    do
         NFS_SHARE=${SHARES_ARRAY[$key]}
         MOUNT_POINT=`cat /proc/mounts | grep "$NFS_SHARE " | awk '{print $2}'`
         if [[ ! -z $MOUNT_POINT ]] ; then
            if sudo -u nova [ -w $MOUNT_POINT -a -r $MOUNT_POINT ] ; then
                continue
            else
               echo "nova user does not have read or/and write permissions on mount point $MOUNT_POINT, $NFS_SHARE"
               return 1
            fi
         fi
    done

return 0

}

function contego_uninstall() {
    TVAULT_IP="$1"
    PIP_INS=`pip --version || true`
    if [[ $PIP_INS == pip* ]];then
       CONTEGO_VERSION_INSTALLED=`pip freeze | grep tvault-contego || true`
       if [[  "$CONTEGO_VERSION_INSTALLED" == tvault-contego==* ]]; then
          contego_stop
          pip uninstall tvault-contego -y
       fi
    else
       easy_install --no-deps http://$TVAULT_IP:8081/packages/pip-7.1.2.tar.gz
       CONTEGO_VERSION_INSTALLED=`pip freeze | grep tvault-contego || true`
       if [[  "$CONTEGO_VERSION_INSTALLED" == tvault-contego==* ]]; then
          contego_stop
          pip uninstall tvault-contego -y
       fi
       pip uninstall pip -y
    fi
    if [ -d "$TVAULT_CONTEGO_VIRTENV" ] ; then
       contego_stop
    fi
    swift_stop 
    rm -rf $TVAULT_CONTEGO_VIRTENV
    rm -rf /etc/logrotate.d/tvault-contego
    DIR=$(dirname "${TVAULT_CONTEGO_CONF}")
    rm -rf "${DIR}"
    rm -rf /var/log/nova/tvault-contego*
    GetDistro
    if [[ "$DISTRO" == "rhel7" ]]; then
        rm -f /usr/lib/systemd/system/tvault-contego.service
        systemctl daemon-reload
    elif is_ubuntu; then
        if [[ "$DISTRO" == "wily" ]]; then
           rm -f /etc/systemd/system/tvault-contego.service
           systemctl daemon-reload
        else
             rm -f /etc/init/tvault-contego.conf 
        fi
    elif is_fedora; then
        rm -f /etc/init.d/tvault-contego
    else
        exit_distro_not_supported "uninstalling tvault-contego"
    fi

    GetDistro
    if [[ "$DISTRO" == "rhel7" ]]; then
        rm -f /usr/lib/systemd/system/tvault-swift.service
        systemctl daemon-reload
    elif is_ubuntu; then
        if [[ "$DISTRO" == "wily" ]]; then
           rm -f /etc/systemd/system/tvault-swift.service
           systemctl daemon-reload
        else
            rm -f /etc/init/tvault-swift.conf
        fi
    elif is_fedora; then
        rm -f /etc/init.d/tvault-swift
    else
        exit_distro_not_supported "uninstalling tvault-swift"
    fi

}

function contego_api_uninstall() {
   TVAULT_IP="$1"
   PIP_INS=`pip --version || true`
   if [[ $PIP_INS == pip* ]];then
       CONTEGO_API_VERSION_INSTALLED=`pip freeze | grep tvault-contego || true`
       if [[  "$CONTEGO_API_VERSION_INSTALLED" == tvault-contego-api==* ]]; then
          pip uninstall tvault-contego-api -y
       fi
       if [[  "$CONTEGO_API_VERSION_INSTALLED" == tvault-contego==* ]]; then
          pip uninstall tvault-contego -y
       fi
   else
       easy_install --no-deps http://$TVAULT_IP:8081/packages/pip-7.1.2.tar.gz
       CONTEGO_API_VERSION_INSTALLED=`pip freeze | grep tvault-contego || true`
       if [[  "$CONTEGO_API_VERSION_INSTALLED" == tvault-contego-api==* ]]; then
          pip uninstall tvault-contego-api -y
       fi
       if [[  "$CONTEGO_API_VERSION_INSTALLED" == tvault-contego==* ]]; then
          pip uninstall tvault-contego -y
       fi
       pip uninstall pip -y
   fi
   ini_get_option "$NOVA_CONF_FILE" "DEFAULT" "osapi_compute_extension" "yes"
   GetDistro
   if [[ "$DISTRO" == "rhel7" ]]; then
        echo "restarting nova-api"
        systemctl restart openstack-nova-api.service
   elif is_ubuntu; then
        echo "restarting nova-api"
        service nova-api restart
   elif is_fedora; then
        echo "restarting nova-api"
        service openstack-nova-api restart
   fi


}

#Function to start contego service 
function contego_start() {
   GetDistro
   is_running=`ps -ef | grep tvault-contego | grep -v grep | wc -l`
   if [ $is_running -lt 3 ]; then
      echo -e "starting tvault-contego service\n"
      if [[ "$DISTRO" == "rhel7" ]]; then
        systemctl daemon-reload
        systemctl start tvault-contego.service
      elif is_ubuntu; then
        sudo service tvault-contego start
      elif is_fedora; then
        service tvault-contego start
      else
        echo "Distribution not supported, exiting \n"
        exit 1
      fi
   fi
}
##Function to stop contego service
function contego_stop() {
  GetDistro
      echo -e "stopping tvault-contego service\n"
      if [[ "$DISTRO" == "rhel7" ]]; then
	    systemctl status tvault-contego | grep "active (running)"
            if [[ $? -eq 0 ]]; then
               systemctl stop tvault-contego.service
            fi
      elif is_ubuntu; then
	    sudo service tvault-contego status | grep "start/running"
	    if [[ $? -eq 0 ]]; then
               sudo service tvault-contego stop
            fi
      elif is_fedora; then
	    service tvault-contego status | grep "running"
	    if [[ $? -eq 0 ]]; then
               service tvault-contego stop
	    fi
      else
        echo "Distribution not supported, exiting \n"
        exit 1
      fi
}

function swift_start() {
   GetDistro
   is_running=`ps -ef | grep tvault-swift | grep -v grep | wc -l`
   if [ $is_running -lt 3 ]; then
      echo -e "starting tvault-swift service\n"
      if [[ "$DISTRO" == "rhel7" ]]; then
        systemctl daemon-reload
        systemctl start tvault-swift.service
      elif is_ubuntu; then
           service tvault-swift start
      elif is_fedora; then
        service tvault-swift start
      else
        echo "Distribution not supported, exiting \n"
        exit 1
      fi
   fi
}

function swift_stop() {
  GetDistro
      echo -e "stopping tvault-swift service\n"
      if [[ "$DISTRO" == "rhel7" ]]; then
            systemctl status tvault-swift | grep "active (running)"
            if [[ $? -eq 0 ]]; then
               systemctl stop tvault-swift.service
               systemctl daemon-reload
            fi
      elif is_ubuntu; then
            service tvault-swift status | grep "start/running"
            if [[ $? -eq 0 ]]; then
               service tvault-swift stop
            fi
      elif is_fedora; then
            service tvault-swift status | grep "running"
            if [[ $? -eq 0 ]]; then
               service tvault-swift stop
            fi
      else
        echo "Distribution not supported, exiting \n"
        exit 1
      fi
}

###MAIN BLOCK

meto=`echo $1`
if [ -n "$2" ]; then
  auto=`echo $2`
fi

####### Nova Configuration Files ########################################
NOVA_CONF_FILE=/etc/nova/nova.conf
#Nova distribution specific configuration file path
NOVA_DIST_CONF_FILE=/usr/share/nova/nova-dist.conf
###############################
TVAULT_CONTEGO_EXT_USER=nova
VAULT_DATA_DIR=/var/triliovault-mounts
VAULT_DATA_DIR_OLD=/var/triliovault
TVAULT_CONTEGO_VERSION=2.3.23
declare TVAULT_CONTEGO_VIRTENV
TVAULT_CONTEGO_VIRTENV=/home/tvault
TVAULT_CONTEGO_VIRTENV_PATH="$TVAULT_CONTEGO_VIRTENV/.virtenv"
###############################


if [ "$meto" == "--help" ];then
    echo -e "1. ./tvault-contego-install.sh --install --file <Answers file path> : install tvault-contego using answers file.\n"
    echo -e "2. ./tvault-contego-install.sh --install : install tvault-contego in interactive way.\n"
    echo -e "3. ./tvault-contego-install.sh --help : tvault-contego installation help.\n"
    echo -e "4. ./tvault-contego-install.sh --uninstall : uninstall tvault-contego. \n"
    echo -e "5. ./tvault-contego-install.sh --uninstall --file <Answers file path> : uninstall tvault-contego using answers file.\n" 
    echo -e "6. ./tvault-contego-install.sh --start : Starts tvault-contego service and enables start-on-boot \n"
    echo -e "7. ./tvault-contego-install.sh --stop : Stops tvault-contego service and disables start-on-boot \n"
    echo -e "8. ./tvault-contego-install.sh --add <new nfsshare>: Adds a new share and restars tvault-contego service\n"
    exit 1
elif [ "$meto" == "--install" -a "$auto" == "--file" ];then
###configuration file
    if [ -z "$3" ]; then
       echo -e "Please provide path of tvault contego answers file\nYou can refer help using --help option\n"
       exit 1
    fi
    answers_file=`echo $3`
    if [ ! -f $answers_file ]; then
       echo -e "Answers file path that you provided does not exists\nPlease provide correct path.\n"
       exit 1
    fi
    source $answers_file
    if echo "$IP_ADDRESS" | egrep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
        then
                VALID_IP_ADDRESS="$(echo $IP_ADDRESS | awk -F'.' '$1 <=255 && $2 <= 255 && $3 <= 255 && $4 <= 255')"
                if [ -z "$VALID_IP_ADDRESS" ]
                then
                    echo "Please specify valid Tvault appliance IP address"
                    exit 1
                fi
    fi

    if [ "$controller" = True ] ; then
        TVAULT_CONTEGO_API="True";TVAULT_CONTEGO_EXT="False"

    elif [ "$compute" = True ]; then
        TVAULT_CONTEGO_EXT="True";TVAULT_CONTEGO_API="False"
        if ! type "showmount" > /dev/null; then
          echo "Error: Please install nfs-common package"
          exit 0
        fi
    fi
elif [ "$meto" == "--install" ];then
    while true;do
        echo -n  "Enter your Tvault appliance IP : ";read IP_ADDRESS
        if echo "$IP_ADDRESS" | egrep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
        then
                VALID_IP_ADDRESS="$(echo $IP_ADDRESS | awk -F'.' '$1 <=255 && $2 <= 255 && $3 <= 255 && $4 <= 255')"
                if [ -z "$VALID_IP_ADDRESS" ]
                then
                    echo "Please specify valid Tvault appliance IP address"
                    continue
                else
                    echo "Tvault appliance IP : $IP_ADDRESS"
                    break
                fi
        else
                echo "Please specify valid Tvault appliance IP address"
                continue
        fi
    done
    echo -e "\nSelect the node which you are using (1/2) :"
    while true;do
        echo "1. Controller"
        echo "2. Compute"
        echo -n "Option : " ; read opt
        if [ "$opt" == 1 ]; then
            TVAULT_CONTEGO_API="True";TVAULT_CONTEGO_EXT="False"
            break
        elif [ "$opt" == 2 ]; then
            TVAULT_CONTEGO_EXT="True";TVAULT_CONTEGO_API="False"
            if ! type "showmount" > /dev/null; then
               echo "Error: Please install nfs-common package"
               exit 0
            fi
            break
        else
            echo -e "\nPlease select valid option (1/2) :"
            continue
        fi
    done
    echo -e "\n"
    if [[ "$TVAULT_CONTEGO_EXT" == "True" ]]; then
        echo "Select compute filter file path (1/2/3):"
        while true;do
            echo "1. RHEL based [Default: /usr/share/nova/rootwrap/compute.filters]"
            echo "2. Debian Based [Default: /etc/nova/rootwrap.d/compute.filters]"
            echo "3. Other"
            echo -n "Choice : " ; read value
            if [ "$value" == 1 ]; then
                NOVA_COMPUTE_FILTERS_FILE="/usr/share/nova/rootwrap/compute.filters"
                break
            elif [ "$value" == 2 ]; then
                NOVA_COMPUTE_FILTERS_FILE="/etc/nova/rootwrap.d/compute.filters"
                break
            elif [ "$value" == 3 ]; then
                while true;do
                     echo -n "Enter Enter NOVA_COMPUTE_FILTERS_FILE path : "; read NOVA_COMPUTE_FILTERS_FILE
                     if [ -z  $NOVA_COMPUTE_FILTERS_FILE ];then
                        echo
                        echo "No path specified, please specify valid path"
                        continue
                     elif [ -f  $NOVA_COMPUTE_FILTERS_FILE ];then
                        echo -e "\n"
                        break
                     else
                        continue
                     fi
                done
                break
             fi
        done
      fi
	########Collect details about nfs or swift storage###
	if [[ "$TVAULT_CONTEGO_EXT" == "True" ]]; then
            found_total=0
            echo "Select the type of backup media (1/2) :"
	    while true;do
	    echo "1. NFS"
	    echo "2. Swift"
	    echo -n "Option : " ; read optmed
            if [ "$optmed" == 1 ]; then
               while true;do
                     echo -n "Enter NFS shares (Format: [IP:/path/to/nfs_share,IP:/path/to/nfs_share,...]): "; read NFS_SHARES
                     echo
                     nfsip=$(echo "$NFS_SHARES" | awk -F':' '{print $1 }')
                     if [[ ! -z $nfsip ]];then
                        NFS=True
                        string="$NFS_SHARES"
                        set -f
                        array=(${string//,/ })
                        for i in "${!array[@]}"
                            do
                              NFS_SHARE_PATH="${array[i]}"
                              nfsip=$(echo "$NFS_SHARE_PATH" | awk -F':' '{print $1 }')
                              nfspath=$(echo "$NFS_SHARE_PATH" | awk -F':' '{print $2 }')
                              if [[ ! -z $nfsip || ! -z $nfspath ]];then
                                 out=`rpcinfo -T tcp $nfsip 100005 3`
                                 if [[ $? -eq 0 ]];then
                                    out=`showmount -e $nfsip --no-headers`
                                    exports=(${out// / })
                                    found=0
                                    for j in "${!exports[@]}"
                                        do
                                           if [[ "${exports[j]}" == "$nfspath" ]];then
                                              found=1
                                              let "found_total++"
                                              break
                                           fi
                                        done
                                    if [[ $found -eq 0 ]];then
                                       echo "$nfspath @ $nfsip is NOT in the export lists"
                                       continue
                                    fi
                                 else
                                     echo "Cannot find mountd @ $nfsip"
                                     continue
                                 fi
                              else
                                  echo "$NFS_SHARE_PATH is not a valid NFS path specified. Please specify nfs share path"
                                  continue
                              fi
                            done
                            break
	             else
	                 echo "$NFS_SHARES path not specified. Please specify nfs share path"
	             fi
               done
               if [[ "$found_total" != "${#array[@]}" ]];then
                   echo "Please correct NFS lists to continue installing"
                   exit 1
               fi
               echo -n "Enter NFS share options, If enter blank then will take default options (Format: [nolock,rw]): "; read NFS_OPTIONS
               echo
            elif [ "$optmed" == 2 ]; then
		  echo "Selected Swift as backup media."
		  Swift=True
                  echo "Select the type of swift (1/2) :"
                  while true;do
                  echo "1. KEYSTONE V2"
                  echo "2. KEYSTONE V3"
                  echo "3. TEMPAUTH"
                  echo -n "Option : " ; read optmed1
                  if [ "$optmed1" == 1 ]; then
	             while true;do
                           VAULT_SWIFT_AUTH_VERSION="KEYSTONEV2"
                           VAULT_SWIFT_AUTH_URL=$(ini_get_option $NOVA_CONF_FILE keystone_authtoken auth_url) 
                           IFS==
                           set $VAULT_SWIFT_AUTH_URL
                           VAULT_SWIFT_AUTH_URL=$(tr -d ' ' <<< "$2")
                           VAULT_SWIFT_AUTH_URL="${VAULT_SWIFT_AUTH_URL}/v2.0"
                           VAULT_SWIFT_TENANT=$(ini_get_option $NOVA_CONF_FILE keystone_authtoken project_name)
                           set $VAULT_SWIFT_TENANT
                           VAULT_SWIFT_TENANT=$(tr -d ' ' <<< "$2")
                           VAULT_SWIFT_USERNAME="triliovault"
                           VAULT_SWIFT_PASSWORD="52T8FVYZJse"
                           VAULT_SWIFT_DOMAIN_ID=""
                           break
                     done
                  elif [ "$optmed1" == 2 ]; then
                       while true;do
                             VAULT_SWIFT_AUTH_VERSION="KEYSTONEV3"
                             VAULT_SWIFT_AUTH_URL=$(ini_get_option $NOVA_CONF_FILE keystone_authtoken auth_url)
                             IFS==
                             set $VAULT_SWIFT_AUTH_URL
                             VAULT_SWIFT_AUTH_URL=$(tr -d ' ' <<< "$2")
                             VAULT_SWIFT_AUTH_URL="${VAULT_SWIFT_AUTH_URL}/v3"
                             VAULT_SWIFT_TENANT=$(ini_get_option $NOVA_CONF_FILE keystone_authtoken project_name)
                             set $VAULT_SWIFT_TENANT
                             VAULT_SWIFT_TENANT=$(tr -d ' ' <<< "$2")
                             VAULT_SWIFT_USERNAME="triliovault"
                             VAULT_SWIFT_PASSWORD="52T8FVYZJse"
                             VAULT_SWIFT_DOMAIN_ID=$(ini_get_option $NOVA_CONF_FILE keystone_authtoken user_domain_id)
                             set $VAULT_SWIFT_DOMAIN_ID
                             VAULT_SWIFT_DOMAIN_ID=$(tr -d ' ' <<< "$2")
                             break
                       done
                  elif [ "$optmed1" == 3 ]; then
                       while true;do
                             VAULT_SWIFT_AUTH_VERSION="TEMPAUTH"
                             echo -n "Enter swift auth url: "; read VAULT_SWIFT_AUTH_URL
                             echo
                             echo -n "Enter swift username: "; read VAULT_SWIFT_USERNAME
                             echo
                             echo -n "Enter swift password: "; read VAULT_SWIFT_PASSWORD
                             echo
                             status=$(curl -i -o /dev/null --silent --write-out '%{http_code}\n' -H "X-Auth-User: $VAULT_SWIFT_USERNAME" -H \
                                     "X-Auth-Key: $VAULT_SWIFT_PASSWORD" $VAULT_SWIFT_AUTH_URL)
                             if [ "$status" != 200 ] && [ "$status" != 201 ]; then
                                echo "Please enter correct swift credentials"
                                exit 1
                             fi
                             VAULT_SWIFT_TENANT=""
                             VAULT_SWIFT_DOMAIN_ID=""
                             break
                       done
                  else
                      continue
                  fi
                  break
                  done
	    else
	    	continue
            fi
	       break
	    done
        fi
elif [ "$meto" == "--start" ]; then
     contego_start
     if [ "$NFS" = True ]; then 
        is_nova_read_writable
     fi
     if [ "$Swift" = True ]; then
        swift_start
     fi
     exit $?
elif [ "$meto" == "--stop" ];then
     contego_stop
     if [ "$Swift" = True ]; then
        swift_stop
     fi
     exit $?
elif [ "$meto" == "--uninstall" -a "$auto" == "--file" ];then
###configuration file
    if [ -z "$3" ]; then
       echo -e "Please provide path of tvault contego answers file\nYou can refer help using --help option\n"
       exit 1
    fi
    answers_file=`echo $3`
    if [ ! -f $answers_file ]; then
       echo -e "Answers file path that you provided does not exists\nPlease provide correct path.\n"
       exit 1
    fi
    source $answers_file
    if echo "$IP_ADDRESS" | egrep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
        then
                VALID_IP_ADDRESS="$(echo $IP_ADDRESS | awk -F'.' '$1 <=255 && $2 <= 255 && $3 <= 255 && $4 <= 255')"
                if [ -z "$VALID_IP_ADDRESS" ]
                then
                    echo "Please specify valid Tvault appliance IP address"
                    exit 1
                fi
    fi

    if [ "$controller" = True ] ; then
        TVAULT_CONTEGO_API="True";TVAULT_CONTEGO_EXT="False"

    elif [ "$compute" = True ]; then
        TVAULT_CONTEGO_EXT="True";TVAULT_CONTEGO_API="False"
    fi
    if [[ "$TVAULT_CONTEGO_EXT" == "True" ]]; then
       contego_uninstall $IP_ADDRESS
    elif [[ "$TVAULT_CONTEGO_API" == "True" ]]; then
       contego_api_uninstall $IP_ADDRESS
    fi
    echo -e "Uninstall completed\n"
    exit 0
elif [ "$meto" == "--uninstall" ];then
    while true;do
        echo -n  "Enter your Tvault appliance IP : ";read IP_ADDRESS
        if echo "$IP_ADDRESS" | egrep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
        then
                VALID_IP_ADDRESS="$(echo $IP_ADDRESS | awk -F'.' '$1 <=255 && $2 <= 255 && $3 <= 255 && $4 <= 255')"
                if [ -z "$VALID_IP_ADDRESS" ]
                then
                    echo "Please specify valid Tvault appliance IP address"
                    continue
                else
                    echo "Tvault appliance IP : $IP_ADDRESS"
                    break
                fi
        else
                echo "Please specify valid Tvault appliance IP address"
                continue
        fi
    done
    echo -e "\nSelect the node type (1/2) :"
    while true;do
        echo "1. Controller"
        echo "2. Compute"
        echo -n "Option : " ; read opt
        if [ "$opt" == 1 ]; then
            TVAULT_CONTEGO_API="True";TVAULT_CONTEGO_EXT="False"
            break
        elif [ "$opt" == 2 ]; then
            TVAULT_CONTEGO_EXT="True";TVAULT_CONTEGO_API="False"
            break
        else
            echo -e "\nPlease select valid option (1/2) :"
            continue
        fi
    done
    echo -e "\n"
    if [[ "$TVAULT_CONTEGO_EXT" == "True" ]]; then
       contego_uninstall $IP_ADDRESS
    elif [[ "$TVAULT_CONTEGO_API" == "True" ]]; then
       contego_api_uninstall $IP_ADDRESS
    fi
    echo -e "Uninstall completed\n"
    exit 0
elif [ "$meto" == "--add" ];then
    if [ -z "$auto" ]; then
       echo -e "Please provide nfs share to add\n"
       exit 1
    fi
    NFS_SHARE_PATH="$auto"
    nfsip=$(echo "$NFS_SHARE_PATH" | awk -F':' '{print $1 }')
    nfspath=$(echo "$NFS_SHARE_PATH" | awk -F':' '{print $2 }')
    if [[ ! -z $nfsip || ! -z $nfspath ]];then
        out=`rpcinfo -T tcp $nfsip 100005 3`
        if [[ $? -eq 0 ]];then
            out=`showmount -e $nfsip --no-headers`
            exports=(${out// / })
            found=0
            for j in "${!exports[@]}"
            do
                if [[ "${exports[j]}" == "$nfspath" ]];then
                    found=1
                    break
                fi
            done
            if [[ $found -eq 0 ]];then
                echo "$nfspath @ $nfsip is NOT in the export lists. Please check the nfsshare name and try again"
                exit 1
            fi
        else
            echo "Cannot find mountd @ $nfsip. Please check the nfsshare name and try again"
            exit 1
        fi
    else
       echo "$NFS_SHARE_PATH is not a valid NFS path specified. Please specify nfs share path"
       exit 1
    fi
    # make sure that nfs share is valid
    exports=$(ini_get_option $TVAULT_CONTEGO_CONF DEFAULT vault_storage_nfs_export)
    if [[ ${exports} == *"${auto}"* ]];then
       echo "$auto is already part of nfs shares"
       exit 1
    fi
    str=$exports
    IFS==
    set $str
    exps=$(tr -d ' ' <<< "$2")
    exps=$exps,$auto
    iniset $TVAULT_CONTEGO_CONF DEFAULT vault_storage_nfs_export $exps
    contego_stop
    contego_start
else
    echo -e "Invalid option provided, Please refer help of this script using --help option \n"
    echo -e "1. ./tvault-contego-install.sh --install --file <Answers file path> : install tvault-contego using answers file.\n"
    echo -e "2. ./tvault-contego-install.sh --install : install tvault-contego in interactive way.\n"
    echo -e "3. ./tvault-contego-install.sh --help : tvault-contego installation help.\n"
    echo -e "4. ./tvault-contego-install.sh --uninstall : uninstall tvault-contego. \n"
    echo -e "5. ./tvault-contego-install.sh --uninstall --file <Answers file path> : uninstall tvault-contego using answers file.\n"
    echo -e "6. ./tvault-contego-install.sh --start : Starts tvault-contego service and enables start-on-boot \n"
    echo -e "7. ./tvault-contego-install.sh --stop : Stops tvault-contego service and disables start-on-boot \n"
    exit 1
fi

#####check version of virsh greater than 1.2.8
if [[ "$TVAULT_CONTEGO_EXT" == "True" ]]; then
    virsh_v=$(`echo virsh\ -v`)
        #echo $virsh_v
        diga=`echo "$virsh_v" | awk -F'.' '{print $1 "" }'`
        digb=`echo "$virsh_v" | awk -F'.' '{print $2 "" }'`
        digc=`echo "$virsh_v" | awk -F'.' '{print $3 "" }'`

	if [ $diga -eq 1 ];then
        	if [ $digb -eq 2 ];then
                	   if [ $digc -gt 7 ];then
                        	echo "Virsh version found $virsh_v :condition satisfied"
	                   elif [ $digc -le 7 ];then
	                        echo "ERROR :virsh version found $virsh_v which is below expected 1.2.8, please upgrade virsh and try again."
       	                 	exit 1
       	        	    fi
      		elif [[ $digb -le 2 ]]; then
            		     echo "ERROR :virsh version found $virsh_v which is below expected 1.2.8, please upgrade virsh and try again."
               		     exit 1
       elif [ $digb -gt 2 ];then
  			   echo "Virsh version found $virsh_v :condition satisfied"
                fi
       elif [ $diga -gt 1 ];then
          	echo "Virsh version found $virsh_v :condition satisfied"
       fi
fi

######

######add nova to sudoers
if [[ "$TVAULT_CONTEGO_EXT" == "True" ]]; then
grep -q -F "nova ALL=(ALL) NOPASSWD: ALL" /etc/sudoers || echo "nova ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi
####

####### IP Address of Trilio Vault Appliance ############################
TVAULT_APPLIANCE_NODE=$IP_ADDRESS

#Nova compute.filters file path
#Uncomment following line as per the OS distribution, you can edit the path as per your nova configuration
###For RHEL systems
#NOVA_COMPUTE_FILTERS_FILE=/usr/share/nova/rootwrap/compute.filters

###For Debian systems
#NOVA_COMPUTE_FILTERS_FILE=/etc/nova/rootwrap.d/compute.filters

####### OpenStack Controller Node: Set TVAULT_CONTEGO_API as True #######
#TVAULT_CONTEGO_API=$valone

####### OpenStack Compute Node: Set TVAULT_CONTEGO_API as True ##########
#TVAULT_CONTEGO_EXT=$valtwo
#TVAULT_CONTEGO_EXT_USER=nova

#VAULT_STORAGE_TYPE=nfs
#VAULT_DATA_DIR=/var/triliovault-mounts

####### MISC ############################################################
#Uncomment following line as per the OS distribution
####For RHEL systems
#TVAULT_CONTEGO_EXT_BIN=/usr/bin/tvault-contego

###For Debian systems
#TVAULT_CONTEGO_EXT_BIN=/usr/local/bin/tvault-contego

# Distro Functions
# ================

# Determine OS Vendor, Release and Update
# Tested with OS/X, Ubuntu, RedHat, CentOS, Fedora
# Returns results in global variables:
# ``os_VENDOR`` - vendor name: ``Ubuntu``, ``Fedora``, etc
# ``os_RELEASE`` - major release: ``14.04`` (Ubuntu), ``20`` (Fedora)
# ``os_UPDATE`` - update: ex. the ``5`` in ``RHEL6.5``
# ``os_PACKAGE`` - package type: ``deb`` or ``rpm``
# ``os_CODENAME`` - vendor's codename for release: ``snow leopard``, ``trusty``
os_VENDOR=""
os_RELEASE=""
os_UPDATE=""
os_PACKAGE=""
os_CODENAME=""



##Install block

if [ ! -f $NOVA_CONF_FILE ]; then
    echo "Nova configuration file '"$NOVA_CONF_FILE"' not found."
    exit 1
fi

if [[ "$TVAULT_CONTEGO_EXT" == "True" ]]; then
    if [ ! -f $NOVA_COMPUTE_FILTERS_FILE ]; then
        echo "Nova compute filters file '"$NOVA_COMPUTE_FILTERS_FILE"' not found."
        exit 1
    fi
fi

############



####if ceentos check qemu-img-rhev,qemu-kvm-common,qemu-kvm-rhev

if [[ "$TVAULT_CONTEGO_EXT" == "True" ]]; then
        #chos=$(echo `lsb_release -i -s`)
        GetOSVersion
        if [[ "$os_VENDOR" == "CentOS" ]] || [[ "$os_VENDOR" == "Red Hat" ]];then
                paka=$(echo `rpm -qa qemu-img-rhev | wc -l`)
                pakb=$(echo `rpm -qa qemu-kvm-common-rhev | wc -l`)
                pakc=$(echo `rpm -qa qemu-kvm-rhev | wc -l`)
                pakd=$(echo `rpm -qa qemu-kvm-tools-rhev | wc -l`)
                        if [[ $paka -gt 0  &&  $pakb -gt 0 &&  $pakc -gt 0 ]];then
                        echo -n
                        else
                        echo "ERROR :please make sure you have install qemu-img-rhev,qemu-kvm-common,qemu-kvm-rhev  package"
                        exit 1
                        fi

        fi
fi

###Add nova user to qemu, disk and kvm##
if [[ "$TVAULT_CONTEGO_EXT" == "True" ]]; then
GetOSVersion
        if [[ "$os_VENDOR" == "CentOS" ]] || [[ "$os_VENDOR" == "Red Hat" ]];then
                usermod -a -G disk $TVAULT_CONTEGO_EXT_USER
                usermod -a -G kvm $TVAULT_CONTEGO_EXT_USER
                usermod -a -G qemu $TVAULT_CONTEGO_EXT_USER

        elif [[ "$os_VENDOR" == "Ubuntu" ]];then
                usermod -a -G  kvm $TVAULT_CONTEGO_EXT_USER
                usermod -a -G disk $TVAULT_CONTEGO_EXT_USER
        fi
fi

############

if [[ "$TVAULT_CONTEGO_EXT" == "True" ]]; then

   if [[ -z "$NFS_SHARES" ]];then 
       if [[ "$NFS" == "True" ]]; then
        echo "NFS_SHARES are not defined, please define it in answers file"
        exit 0
       fi
   fi
   if [[ "$Swift" == "True" ]]; then
      NFS=False
      if [[ -z $VAULT_SWIFT_AUTH_VERSION ]]; then
         echo "Please define swift auth version"
         exit 0
      fi
      if [[ "$VAULT_SWIFT_AUTH_VERSION" == "KEYSTONEV2" ]]; then
         VAULT_SWIFT_AUTH_VERSION="KEYSTONE"
         VAULT_SWIFT_AUTH_URL=$(ini_get_option $NOVA_CONF_FILE keystone_authtoken auth_url)
         IFS==
         set $VAULT_SWIFT_AUTH_URL
         VAULT_SWIFT_AUTH_URL=$(tr -d ' ' <<< "$2")
         VAULT_SWIFT_AUTH_URL="${VAULT_SWIFT_AUTH_URL}/v2.0"
         VAULT_SWIFT_TENANT=$(ini_get_option $NOVA_CONF_FILE keystone_authtoken project_name)
         set $VAULT_SWIFT_TENANT
         VAULT_SWIFT_TENANT=$(tr -d ' ' <<< "$2")
         VAULT_SWIFT_USERNAME="triliovault"
         VAULT_SWIFT_PASSWORD="52T8FVYZJse"
         VAULT_SWIFT_DOMAIN_ID=""
      elif [[ "$VAULT_SWIFT_AUTH_VERSION" == "KEYSTONEV3" ]]; then
           VAULT_SWIFT_AUTH_VERSION="KEYSTONE"
           VAULT_SWIFT_AUTH_URL=$(ini_get_option $NOVA_CONF_FILE keystone_authtoken auth_url)
           IFS==
           set $VAULT_SWIFT_AUTH_URL
           VAULT_SWIFT_AUTH_URL=$(tr -d ' ' <<< "$2")
           VAULT_SWIFT_AUTH_URL="${VAULT_SWIFT_AUTH_URL}/v3"
           VAULT_SWIFT_TENANT=$(ini_get_option $NOVA_CONF_FILE keystone_authtoken project_name)
           set $VAULT_SWIFT_TENANT
           VAULT_SWIFT_TENANT=$(tr -d ' ' <<< "$2")
           VAULT_SWIFT_USERNAME="triliovault"
           VAULT_SWIFT_PASSWORD="52T8FVYZJse"
           VAULT_SWIFT_DOMAIN_ID=$(ini_get_option $NOVA_CONF_FILE keystone_authtoken user_domain_id)
           set $VAULT_SWIFT_DOMAIN_ID
           VAULT_SWIFT_DOMAIN_ID=$(tr -d ' ' <<< "$2")
      elif [[ "$VAULT_SWIFT_AUTH_VERSION" == "TEMPAUTH" ]]; then
           status=$(curl -i -o /dev/null --silent --write-out '%{http_code}\n' -H "X-Auth-User: $VAULT_SWIFT_USERNAME" -H \
                                     "X-Auth-Key: $VAULT_SWIFT_PASSWORD" $VAULT_SWIFT_AUTH_URL)
           if [ "$status" != 200 ] && [ "$status" != 201 ]; then
              echo "Please enter correct swift credentials"
              exit 0
           fi
      else
          echo "Please specify correct value for auth version"
          exit 0
      fi
   fi
   PIP_INS=`pip --version || true`
   if [[ $PIP_INS == pip* ]];then
       CONTEGO_VERSION_INSTALLED=`pip freeze | grep tvault-contego== || true`
       if [[  $CONTEGO_VERSION_INSTALLED == tvault-contego* ]]; then
          pip uninstall tvault-contego -y
          exit 0
       fi
   else
       easy_install --no-deps http://$TVAULT_APPLIANCE_NODE:8081/packages/pip-7.1.2.tar.gz
       CONTEGO_VERSION_INSTALLED=`pip freeze | grep tvault-contego== || true`
       if [[  $CONTEGO_VERSION_INSTALLED == tvault-contego* ]]; then
          pip uninstall tvault-contego -y
          exit 0
       fi
       pip uninstall pip -y
   fi
   mkdir -p "$TVAULT_CONTEGO_VIRTENV"
   cd $TVAULT_CONTEGO_VIRTENV
   curl -O http://$TVAULT_APPLIANCE_NODE:8081/packages/$OPEN_STACK_RELEASE/tvault-contego-virtenv.tar.gz
   if [ -d .virtenv ]; then
       source .virtenv/bin/activate
       CONTEGO_VERSION_INSTALLED=`pip freeze | grep tvault-contego | grep ^tvault- | cut -d'=' -f3 || true`
       deactivate
       if [ "$TVAULT_CONTEGO_VERSION" == "$CONTEGO_VERSION_INSTALLED" ]; then
          rm -rf tvault-contego-virtenv.tar.gz
          echo -e "Latest Tvault-contego package is already installed, exiting\n"
          exit 0
       fi
   fi
   tar -zxf tvault-contego-virtenv.tar.gz
   rm -rf tvault-contego-virtenv.tar.gz
   source .virtenv/bin/activate
   pip install http://$TVAULT_APPLIANCE_NODE:8081/packages/tvault-contego-$TVAULT_CONTEGO_VERSION.tar.gz
   deactivate
   cd -
   chown -R "$TVAULT_CONTEGO_EXT_USER":"$TVAULT_CONTEGO_EXT_USER" "$TVAULT_CONTEGO_VIRTENV"
   if [[ ! -d /var/log/nova ]]; then
        mkdir -p /var/log/nova
        chown nova:nova /var/log/nova
   fi
fi

if [[ "$TVAULT_CONTEGO_API" == "True" ]]; then
   echo "installing packages"
   export TVAULT_PACKAGE=tvault-contego-api
   PIP_INS=`pip --version || true`
   if [[ $PIP_INS == pip* ]];then
       CONTEGO_VERSION_INSTALLED=`pip freeze | grep tvault-contego== || true`
       if [[ $CONTEGO_VERSION_INSTALLED == tvault* ]]; then
          pip uninstall tvault-contego -y
       fi
       CONTEGO_API_VERSION_INSTALLED=`pip freeze | grep tvault-contego-api | grep ^tvault- | cut -d'=' -f3 || true`
       if [ "$TVAULT_CONTEGO_VERSION" == "$CONTEGO_API_VERSION_INSTALLED" ]; then
          echo -e "Latest tvault-contego-api package is already installed, exiting\n"
          exit 0
       fi
      echo "installing packages"
      echo "PIP already installed"
      pip install --no-deps http://$TVAULT_APPLIANCE_NODE:8081/packages/tvault-contego-api-$TVAULT_CONTEGO_VERSION.tar.gz
   else
       echo "installing packages"
       easy_install --no-deps http://$TVAULT_APPLIANCE_NODE:8081/packages/pip-7.1.2.tar.gz
       CONTEGO_VERSION_INSTALLED=`pip freeze | grep tvault-contego== || true`
       if [[ $CONTEGO_VERSION_INSTALLED == tvault* ]]; then
          pip uninstall tvault-contego -y
       fi
       CONTEGO_API_VERSION_INSTALLED=`pip freeze | grep tvault-contego-api | grep ^tvault- | cut -d'=' -f3 || true`
       if [ "$TVAULT_CONTEGO_VERSION" == "$CONTEGO_API_VERSION_INSTALLED" ]; then
          echo -e "Latest tvault-contego-api package is already installed, exiting\n"
          exit 0
       fi
       pip install --no-deps http://$TVAULT_APPLIANCE_NODE:8081/packages/tvault-contego-api-$TVAULT_CONTEGO_VERSION.tar.gz
       pip uninstall pip -y
   fi
   unset TVAULT_PACKAGE
fi

TVAULT_CONTEGO_EXT_BIN="$TVAULT_CONTEGO_VIRTENV_PATH/bin/tvault-contego"
TVAULT_CONTEGO_EXT_PYTHON="$TVAULT_CONTEGO_VIRTENV_PATH/bin/python"
TVAULT_CONTEGO_EXT_SWIFT="$TVAULT_CONTEGO_VIRTENV_PATH/lib/python2.7/site-packages/contego/nova/extension/driver/vaultfuse.py"

if [[ "$TVAULT_CONTEGO_EXT" == "True" ]]; then
    if [ ! -f $TVAULT_CONTEGO_EXT_BIN ]; then
        echo "nova extension tvault contego binary file '"$TVAULT_CONTEGO_EXT_BIN"' not found."
        exit 1
    fi
fi

if [[ "$TVAULT_CONTEGO_API" == "True" ]]; then
    echo "configuring nova api extension"
    iniset_multiline $NOVA_CONF_FILE DEFAULT osapi_compute_extension nova.api.openstack.compute.contrib.standard_extensions contego.nova.osapi.contego_extension.contego_extension
    GetDistro
    if [[ "$DISTRO" == "rhel7" ]]; then
        echo "restarting nova-api"
        systemctl restart openstack-nova-api.service
    elif is_ubuntu; then
        echo "restarting nova-api"
        service nova-api restart
    elif is_fedora; then
        echo "restarting nova-api"
        service openstack-nova-api restart
    fi
fi

if [[ "$TVAULT_CONTEGO_EXT" == "True" ]]; then
    echo "configuring nova compute extension"
    iniset $NOVA_CONF_FILE DEFAULT compute_driver libvirt.LibvirtDriver
    grep -q -F 'qemu-img: EnvFilter, env, root, LC_ALL=, LANG=, qemu-img, root' $NOVA_COMPUTE_FILTERS_FILE || echo 'qemu-img: EnvFilter, env, root, LC_ALL=, LANG=, qemu-img, root' >> $NOVA_COMPUTE_FILTERS_FILE
    grep -q -F 'rm: CommandFilter, rm, root' $NOVA_COMPUTE_FILTERS_FILE || echo 'rm: CommandFilter, rm, root' >> $NOVA_COMPUTE_FILTERS_FILE


    if [ ! -f $TVAULT_CONTEGO_CONF ]; then
        echo "creating contego.conf"
        mkdir -p /etc/tvault-contego
    fi
    if [ "$NFS" = True ]; then
        create_contego_conf_nfs
        echo "Snapshot will be stored in $VAULT_DATA_DIR"
    elif [ "$Swift" = True ]; then
         create_contego_conf_swift
    fi

    create_contego_logrotate

    CONFIG_FILES=""
    for file in $NOVA_DIST_CONF_FILE $NOVA_CONF_FILE $TVAULT_CONTEGO_CONF ; do
        test -r $file && CONFIG_FILES="$CONFIG_FILES --config-file=$file"
    done

    GetDistro
    if [[ "$DISTRO" == "rhel7" ]]; then
        echo "installing nova extension tvault-contego on RHEL 7 or CentOS 7"
        create_tvault_contego_service_systemd
        systemctl daemon-reload
        systemctl enable tvault-contego.service
    elif is_ubuntu; then
        echo "installing nova extension tvault-contego on" $DISTRO
        if [[ "$os_CODENAME" == "wily" ]]; then
            cretae_tvault_contego_service_wily
            systemctl daemon-reload
            systemctl enable tvault-contego.service
        else
            create_tvault_contego_service_init
        fi
    elif is_fedora; then
        echo "installing nova extension tvault-contego on" $DISTRO
        create_tvault_contego_service_initd
        chkconfig tvault-contego on
    else
        exit_distro_not_supported "installing tvault-contego"
    fi

    if [ "$Swift" = True ]; then
       GetDistro
       if [[ "$DISTRO" == "rhel7" ]]; then
          echo "installing tvault-swift on RHEL 7 or CentOS 7"
          create_tvault_swift_service_systemd
          systemctl daemon-reload
          systemctl enable tvault-swift.service
       elif is_ubuntu; then
            echo "installing tvault-swift on" $DISTRO
            if [[ "$os_CODENAME" == "wily" ]]; then
               cretae_tvault_swift_service_wily
               systemctl daemon-reload
               systemctl enable tvault-swift.service
            else
                create_tvault_swift_service_init
            fi
       elif is_fedora; then
            echo "installing tvault-swift on" $DISTRO
            create_tvault_swift_service_initd
            chkconfig tvault-swift on
       else
            exit_distro_not_supported "installing tvault-swift"
       fi
    fi

    if [ "$NFS" = True ]; then 
       is_nova_read_writable
       if [ $? -ne 0 ]; then
           echo -e "Snapshot storage directory($VAULT_DATA_DIR) does not have write access to nova user\n \
                    Please assign read, write access to nova user on directory $VAULT_DATA_DIR "
           exit 1
       fi
    fi

    contego_stop
    echo "Install complete."
    exit 0
fi
