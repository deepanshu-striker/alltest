%define name tvault-contego
%define version VERSION
%define unmangled_version VERSION
%define unmangled_version VERSION
%define release RELEASE
%define rpm_name %{name}-%{version}-%{release}.x86_64
%define rpm_install_dir $RPM_BUILD_ROOT

Name: tvault-contego
Version: %{version}
Release: %{release}
Summary: tvault contego extension for openstack compute.
License: Proprietary software
Group: Development/Libraries
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Prefix: %{_prefix}
BuildArch: noarch
Vendor: TrilioData <support@triliodata.com>
Url: http://www.triliodata.com/


Requires:puppet-triliovault == %{version}

%description
This project extends OpenStack's nova (compute) project, in
order to snapshot the instances by tVault.


%pre
rm -rf /home/tvault/
mkdir -p /home/tvault/
tar -xzf /usr/share/openstack-puppet/modules/trilio/files/tvault-contego-virtenv.tar.gz --directory /home/tvault/
chown -R nova:nova /home/tvault/
chmod -R 777 /home/tvault/

%install
cp -R %_builddir/home $RPM_BUILD_ROOT/

%postun
if [ $1 -eq 0 ]; then
   rm -rf /home/tvault/
fi

%clean
echo NOOP

%files -f INSTALLED_FILES
%defattr(-,root,root)
