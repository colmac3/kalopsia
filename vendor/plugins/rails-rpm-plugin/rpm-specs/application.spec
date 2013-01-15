Name:           Kalopsia
Version:        1.0
Release:        0
Summary:        Kalopsia RMP file for rails projects
Group:          rails/rtml
License:        Ingenico License
URL:            http://github.com/sinisterchipmunc/rtml.git
Source:        %{name}-%{version}.tar.gz
BuildRoot:     %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch:      noarch
# TODO: required packages
# Requires:

%description
Ruby on Rails Kalopsia payment application.


# definitions
%define _appdir /usr/local/Ingenico
%define _railsdir %{_appdir}/%{name}/%{version}
%define _httpdconfig %{_sysconfdir}/httpd/conf.d
%define _etcconfig %{_sysconfdir}/ingenico/kalopsia/config


%prep
%setup -q

%install
%{__mkdir} -p %{buildroot}/%{_railsdir}
%{__cp} -aR rails/* %{buildroot}/%{_railsdir}

%{__mkdir} -p %{buildroot}/%{_httpdconfig}
%{__cp} -aR rails/vendor/plugins/rails-rpm-plugin/system-files/application.conf %{buildroot}/%{_httpdconfig}/%{name}.conf
%{__cp} -aR %{buildroot}/%{_httpdconfig}/%{name}.conf %{_httpdconfig}

%{__mkdir} -p %{buildroot}/%{_etcconfig}
/bin/mv %{buildroot}/%{_appdir}/%{name}/%{version}/config/database.yml %{buildroot}/%{_etcconfig}

%{__mkdir} -p %{buildroot}/%{_appdir}/%{name}/shared

/bin/ln -fs %{_railsdir} %{buildroot}/%{_appdir}/%{name}/current
/bin/ln -fs %{_etcconfig}/database.yml %{buildroot}/%{_appdir}/%{name}/%{version}/config/database.yml

%files
%defattr(-,root,root,-)
%{_railsdir}
%{_appdir}/%{name}/current
%{_appdir}/%{name}/shared

%defattr(-,root,root,-)
%config %{_httpdconfig}/%{name}.conf
%config %{_etcconfig}/database.yml


%clean
rm -rf %{buildroot}

%pre

%post


%changelog
