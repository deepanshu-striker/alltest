#!/bin/bash
metos=`echo $1`
metos2=`echo $2`
####################
TVAULT_V=2.3.23.tar.gz
#####################

if [ "$metos" == "--auto" ];then
        source tvault-horizon-plugin-install.answer

elif [ "$metos" == "--help" ];then
        echo
        echo "1. ./tvault-horizon-plugin-install.sh --auto : install tvault-horizon-plugin using tvault-horizon-plugin-install.answers file."
        echo
        echo "2. ./tvault-horizon-plugin-install.sh        : install tvault-horizon-plugin in interactive way."
        echo
        echo "3. ./tvault-horizon-plugin-install.sh --help : tvault-horizon-plugin installation help."
        echo
        echo "4. ./tvault-horizon-plugin-install.sh --uninstall : uninstall tvault-horizon-plugin."
        echo
        echo "5. ./tvault-horizon-plugin-install.sh --uninstall --auto: uninstall tvault-horizon-plugin using tvault-horizon-plugin-install.answers file"
        echo
        exit 1
fi

if [ "$metos" == "--auto" ];then
        source tvault-horizon-plugin-install.answer
elif [ "$metos" == "--uninstall" ];then
        if [ -d /usr/share/openstack-dashboard/openstack_dashboard/local/enabled ];then
             HORIZON=/usr/share/openstack-dashboard
        else
            if [ "$metos2" == "--auto" ];then
                source tvault-horizon-plugin-install.answer
                HORIZON=$HORIZON_PATH
            else
                echo -n "Please specify path to openstack_dashboard folder : "; read HORIZON
            fi
        fi

        cd $HORIZON
        find $HORIZON -name "tvault_panel_group.py*" -exec rm -f {} \;
        find $HORIZON -name "tvault_admin_panel_group.py*" -exec rm -f {} \;
        find $HORIZON -name "tvault_panel.py*" -exec rm -f {} \;
        find $HORIZON -name "tvault_settings_panel.py*" -exec rm -f {} \;
        find $HORIZON -name "tvault_admin_panel.py*" -exec rm -f {} \;
        find $HORIZON -name "tvault_filter.py*" -exec rm -f {} \;

        cat > /tmp/sync_static.py <<-EOF
import settings
import os
import subprocess
root = settings.openstack_dashboard.settings.STATIC_ROOT+os.sep+"dashboards"
subprocess.call("rm -rf  "+root, shell=True)
EOF

        ./manage.py shell < /tmp/sync_static.py &> /dev/null
        rm -rf /tmp/sync_static.py
        cd -

        PIP_INS=`pip --version || true`
        if [[ $PIP_INS == pip* ]];then
           echo "uninstalling packages"
           echo "PIP already installed"
           pip uninstall tvault-horizon-plugin -y
           pip uninstall python-workloadmgrclient -y
        else
             echo "uninstalling packages"
             easy_install --no-deps pip  &> /dev/null
             if [ $? -ne 0 ];then
                if [ "$metos2" == "" ];then
                    while true;do
                    echo -n  "Enter your Tvault appliance IP address : ";read TVAULTAPP
                    if echo "$TVAULTAPP" | egrep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
                    then
                    VALID_IP_ADDRESS="$(echo $TVAULTAPP | awk -F'.' '$1 <=255 && $2 <= 255 && $3 <= 255 && $4 <= 255')"
                    if [ -z "$VALID_IP_ADDRESS" ]
                    then
                    echo "Please specify valid Tvault appliance IP address"
                    continue
                    else
                    echo
                    break
                    fi
                    else
                    echo "Please specify valid Tvault appliance IP address"
                    continue
                    fi
                    done
                fi
                easy_install --no-deps http://$TVAULTAPP:8081/packages/pip-7.1.2.tar.gz &> /dev/null
                if [ $? -eq 0 ]; then
                   echo "Installing pip-7.1.2.tar.gz"
                else
                    echo "Errror : easy_install http://$TVAULTAPP:8081/packages/pip-7.1.2.tar.gz"
                    exit 1
                fi
                pip uninstall tvault-horizon-plugin -y
                pip uninstall python-workloadmgrclient -y
             else
                 pip uninstall tvault-horizon-plugin -y
                 pip uninstall python-workloadmgrclient -y
             fi
             pip uninstall pip -y
        fi

        if [ "$metos2" == "--auto" ];then
           service $WebServer restart
        else
            if [ -d /etc/apache2 ];then
            service apache2 restart
            elif [ -d /etc/httpd ];then
            service httpd restart
            else
            echo -n "Please specify your WebServer service name";read WebServer
            service $WebServer restart
            fi
        fi

        echo "Uninstall completed"
        exit 0

elif [ "$metos" == "" ];then
while true;do
echo -n  "Enter your Tvault appliance IP address : ";read TVAULTAPP
if echo "$TVAULTAPP" | egrep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
        then
                VALID_IP_ADDRESS="$(echo $TVAULTAPP | awk -F'.' '$1 <=255 && $2 <= 255 && $3 <= 255 && $4 <= 255')"
                if [ -z "$VALID_IP_ADDRESS" ]
                then
                echo "Please specify valid Tvault appliance IP address"
                continue
                else
                echo
                break
                fi
   else
    echo "Please specify valid Tvault appliance IP address"
    continue
fi
done
fi

###installing packages main##
PIP_INS=`pip --version || true`
if [[ $PIP_INS == pip* ]];then
        echo "installing packages"
        echo "PIP already installed"
        pip install --no-deps http://$TVAULTAPP:8081/packages/python-workloadmgrclient-$TVAULT_V &> /dev/null
        if [ $? -eq 0 ]; then
                echo "Installing python-workloadmgrclient-$TVAULT_V"
        else
                echo "Errror : pip install http://$TVAULTAPP:8081/packages/python-workloadmgrclient-$TVAULT_V"
                exit 1
        fi
        pip install --no-deps http://$TVAULTAPP:8081/packages/tvault-horizon-plugin-$TVAULT_V &> /dev/null
        if [ $? -eq 0 ]; then
                echo "Installing tvault-horizon-plugin-$TVAULT_V"
        else
                echo "Errror : pip install  http://$TVAULTAPP:8081/packages/tvault-horizon-plugin-$TVAULT_V"
                exit 1
        fi
else
        echo "installing packages"
        easy_install --no-deps pip  &> /dev/null
        if [ $? -ne 0 ];then
        easy_install --no-deps http://$TVAULTAPP:8081/packages/pip-7.1.2.tar.gz &> /dev/null
        if [ $? -eq 0 ]; then
                echo "Installing pip-7.1.2.tar.gz"
        else
                echo "Errror : easy_install http://$TVAULTAPP:8081/packages/pip-7.1.2.tar.gz"
                exit 1
        fi
        fi
        pip install --no-deps http://$TVAULTAPP:8081/packages/python-workloadmgrclient-$TVAULT_V &> /dev/null
        if [ $? -eq 0 ]; then
                echo "Installing python-workloadmgrclient-$TVAULT_V"
        else
                echo "Errror : pip install http://$TVAULTAPP:8081/packages/python-workloadmgrclient-$TVAULT_V"
                pip uninstall pip -y
                exit 1
        fi
        pip install --no-deps http://$TVAULTAPP:8081/packages/tvault-horizon-plugin-$TVAULT_V &> /dev/null
        if [ $? -eq 0 ]; then
                echo "Installing tvault-horizon-plugin-$TVAULT_V"
        else
                echo "Errror : pip install  http://$TVAULTAPP:8081/packages/tvault-horizon-plugin-$TVAULT_V"
                pip uninstall pip -y
                exit 1
        fi
        pip uninstall pip -y
fi

########


###write tvault_panel.py and tvault_panel_group.py
if [ -d /usr/share/openstack-dashboard/openstack_dashboard/local/enabled ];then
HORIZON=/usr/share/openstack-dashboard
else
        if [ "$metos" == "--auto" ];then
        HORIZON=$HORIZON_PATH
        else
        echo -n "Please specify path to openstack_dashboard folder : "; read HORIZON
        fi
fi
cat > $HORIZON/openstack_dashboard/local/enabled/tvault_panel_group.py <<-EOF
from django.utils.translation import ugettext_lazy as _
# The slug of the panel group to be added to HORIZON_CONFIG. Required.
PANEL_GROUP = 'backups'
# The display name of the PANEL_GROUP. Required.
PANEL_GROUP_NAME = _('Backups')
# The slug of the dashboard the PANEL_GROUP associated with. Required.
PANEL_GROUP_DASHBOARD = 'project'
EOF
cat > $HORIZON/openstack_dashboard/local/enabled/tvault_admin_panel_group.py <<-EOF
from django.utils.translation import ugettext_lazy as _
# The slug of the panel group to be added to HORIZON_CONFIG. Required.
PANEL_GROUP = 'backups-admin'
# The display name of the PANEL_GROUP. Required.
PANEL_GROUP_NAME = _('Backups-Admin')
# The slug of the dashboard the PANEL_GROUP associated with. Required.
PANEL_GROUP_DASHBOARD = 'admin'
EOF
cat > $HORIZON/openstack_dashboard/local/enabled/tvault_panel.py <<-EOF
# The slug of the panel to be added to HORIZON_CONFIG. Required.
PANEL = 'workloads'
# The slug of the dashboard the PANEL associated with. Required.
PANEL_DASHBOARD = 'project'
# The slug of the panel group the PANEL is associated with.
PANEL_GROUP = 'backups'
# Python panel class of the PANEL to be added.
ADD_PANEL = ('dashboards.workloads.panel.Workloads')
DISABLED = False
EOF
cat > $HORIZON/openstack_dashboard/local/enabled/tvault_settings_panel.py <<-EOF
# The slug of the panel to be added to HORIZON_CONFIG. Required.
PANEL = 'settings'
# The slug of the dashboard the PANEL associated with. Required.
PANEL_DASHBOARD = 'project'
# The slug of the panel group the PANEL is associated with.
PANEL_GROUP = 'backups'
# Python panel class of the PANEL to be added.
ADD_PANEL = ('dashboards.settings.panel.Settings')
DISABLED = False
EOF
cat > $HORIZON/openstack_dashboard/local/enabled/tvault_admin_panel.py <<-EOF
# The slug of the panel to be added to HORIZON_CONFIG. Required.
PANEL = 'workloads_admin'
# The slug of the dashboard the PANEL associated with. Required.
PANEL_DASHBOARD = 'admin'
# The slug of the panel group the PANEL is associated with.
PANEL_GROUP = 'backups-admin'
# Python panel class of the PANEL to be added.
ADD_PANEL = ('dashboards.workloads_admin.panel.Workloads_admin')
ADD_INSTALLED_APPS = ['dashboards']
DISABLED = False
EOF
cat > $HORIZON/openstack_dashboard/templatetags/tvault_filter.py <<-EOF
from django import template
from openstack_dashboard import api
from openstack_dashboard import policy

register = template.Library()

@register.filter(name='getusername')
def get_user_name(user_id, request):
    user_name = user_id
    if policy.check((("identity", "identity:get_user"),), request):
        try:
            user = api.keystone.user_get(request, user_id)
            if user:
                user_name = user.username
        except Exception:
            pass
    else:
        LOG.debug("Insufficient privilege level to view user information.")
    return user_name

@register.filter(name='getprojectname')
def get_project_name(project_id, request):
    project_name = project_id
    try:
        project_info = api.keystone.tenant_get(request, project_id, admin = True)
        if project_info:
            project_name = project_info.name
    except Exception:
        pass
    return project_name
EOF

######
if [ "$metos" == "--auto" ];then
service $WebServer restart
elif [ "$metos" == "" ];then
        if [ -d /etc/apache2 ];then
        service apache2 restart
        elif [ -d /etc/httpd ];then
        service httpd restart
        else
        echo -n "Please specify your WebServer service name";read WebServer
        service $WebServer restart
        fi
fi

cat > /tmp/sync_static.py <<-EOF
import settings
import subprocess
ls = settings.openstack_dashboard.settings.INSTALLED_APPS
data = ""
for app in ls:
    if app != 'dashboards':
       data += "-i "+str(app)+" "

subprocess.call("./manage.py collectstatic --noinput "+data, shell=True)
EOF

cd $HORIZON
./manage.py shell < /tmp/sync_static.py &> /dev/null
rm -rf /tmp/sync_static.py
cd -
