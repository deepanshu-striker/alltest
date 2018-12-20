%define name tvault-contego
%define version 1.0.146
%define unmangled_version 1.0.146
%define unmangled_version 1.0.146
%define release 1
%define rpm_name %{name}-%{version}-%{release}.x86_64
%define rpm_install_dir $RPM_BUILD_ROOT/opt/contego

Name: tvault-contego
Version: 1.0.146
Release: 1.0
Summary: tvault contego extension for openstack compute.
License: Proprietary software
Group: Development/Libraries
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Prefix: %{_prefix}
BuildArch: noarch
Vendor: TrilioData <support@triliodata.com>
Url: http://www.triliodata.com/
Packager: shyam.biradar@triliodata.com


Requires:openstack-nova-compute,curl,shadow-utils, python-amqplib,python-anyjson,python-boto,python-eventlet,python-kombu,python-lxml,python-routes,python-webob,python-greenlet,python-paste-deploy
Requires:python-paste,python-netaddr,python-suds,python-paramiko,python-pyasn1,python-babel,python-iso8601,python-jsonschema,python-httplib2,python-setuptools,python-keystoneclient,python-six
Requires:python-stevedore,python-oslo-config,python-jinja2,python-bottle,python-swiftclient

%description
This project extends OpenStack's nova (compute) project, in
order to snapshot the instances by tVault.

%install
cp -R %_builddir/usr $RPM_BUILD_ROOT/

%clean
rm -rf $RPM_BUILD_ROOT

%post
export e="qemu-img: EnvFilter, env, root, LC_ALL=, LANG=, qemu-img, root"
if grep -q ^qemu-img.* /usr/share/nova/rootwrap/compute.filters ; then
  sed -i "s/^qemu-img.*$/${e}/g" /usr/share/nova/rootwrap/compute.filters
else
  echo $e >> /usr/share/nova/rootwrap/compute.filters
fi

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
User=nova
ExecStart=/usr/bin/tvault-contego
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload &> /dev/null
systemctl enable tvault-contego.service &> /dev/null

%files -f INSTALLED_FILES
%defattr(-,root,root)
