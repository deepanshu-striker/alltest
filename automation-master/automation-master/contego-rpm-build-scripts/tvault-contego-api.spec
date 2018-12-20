%define name tvault-contego-api
%define version 1.0.146
%define unmangled_version 1.0.146
%define unmangled_version 1.0.146
%define release 1
%define rpm_name %{name}-%{version}-%{release}.x86_64
%define rpm_install_dir $RPM_BUILD_ROOT/opt/contego

Name: tvault-contego-api
Version: 1.0.146
Release: 1.0
Summary: tvault contego extension for openstack compute api
License: Proprietary software
Group: Development/Libraries
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Prefix: %{_prefix}
BuildArch: noarch
Vendor: TrilioData <support@triliodata.com>
Url: http://www.triliodata.com/
Packager: shyam.biradar@triliodata.com


Requires:python-webob,python-oslo-config 

%description
This project extends OpenStack's nova (compute) project, in
order to snapshot the instances by tVault.

%install
cp -R %_builddir/usr $RPM_BUILD_ROOT/

%clean
rm -rf $RPM_BUILD_ROOT

%post
export e="osapi_compute_extension=nova.api.openstack.compute.contrib.standard_extensions"
export f="osapi_compute_extension=contego.nova.osapi.contego_extension.contego_extension"
sed -i "/\[DEFAULT\]/a $e" /etc/nova/nova.conf
sed -i "/\[DEFAULT\]/a $f" /etc/nova/nova.conf

systemctl restart openstack-nova-api.service


%files -f INSTALLED_FILES
%defattr(-,root,root)
