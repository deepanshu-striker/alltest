%define name puppet-triliovault
%define version VERSION
%define unmangled_version VERSION
%define unmangled_version VERSION
%define release RELEASE
%define rpm_name %{name}-%{version}-%{release}.x86_64
%define rpm_install_dir $RPM_BUILD_ROOT

Name:       %{name}
Version:    %{version}
Release:    %{release}
Summary:    TrilioVault puppet module
License:    Proprietary software
BuildRoot:  %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Prefix:     %{_prefix}
BuildArch:  noarch
Vendor:     TrilioData <support@trilio.io>
Url:        https://github.com/trilioData/triliovault-cfg-scripts/tree/master/redhat-director-scripts/puppet/trilio
AutoReqProv: no

%description
Installs and configures TrilioVault on OpenStack

%install
install -d -m 0755 $RPM_BUILD_ROOT/usr/share/openstack-puppet/modules/trilio/
cp -R %_builddir/trilio/* $RPM_BUILD_ROOT/usr/share/openstack-puppet/modules/trilio/
exit 0

%post
rm -rf /home/tvault/
mkdir -p /home/tvault/
tar -xzf /usr/share/openstack-puppet/modules/trilio/files/tvault-contego-virtenv.tar.gz --directory /home/tvault/
chown -R nova:nova /home/tvault/
chmod -R 777 /home/tvault

%clean
rm -rf $RPM_BUILD_ROOT


%files -f INSTALLED_FILES
%defattr(-,root,root)
