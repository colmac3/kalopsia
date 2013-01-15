Name:          Kalopsia
Version:       1.0
Release:       11
Summary:       Kalopsia RPM file for rails projects
Group:         rails/rtml
License:       Ingenico License
URL:           http://github.com/sinisterchipmunk/rtml.git
Source:        %{name}-%{version}.tar.gz
BuildRoot:     %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch:     noarch
Requires:      ruby-enterprise-rubygem-SyslogLogger              >= 1.4.0-2
Requires:      ruby-enterprise-rubygem-pg
Requires:      ruby-enterprise-rubygem-rails
Requires:      ruby-enterprise-rubygem-passenger-selinux
Requires:      ruby-enterprise-rubygem-hpricot

%description
Ruby on Rails Kalopsia payment application.


# definitions
%define _appdir /usr/local/Ingenico
%define _railsdir %{_appdir}/%{name}
%define _etcconfig %{_sysconfdir}/ingenico/kalopsia/config
%define _current %{_appdir}/%{name}
%define _rakefile %{_current}/Rakefile
%define _rake /opt/ruby-enterprise/bin/rake -f %{_rakefile} RAILS_ENV=production

%prep
%setup -q

%install
%{__mkdir} -p %{buildroot}/%{_railsdir}
%{__cp} -aR rails/* %{buildroot}/%{_railsdir}

%{__mkdir} -p %{buildroot}/%{_etcconfig}
%{__mkdir} -p %{buildroot}/%{_etcconfig}/environments
%{__cp} %{buildroot}/%{_railsdir}/config/database.yml %{buildroot}/%{_etcconfig}/database.yml
%{__cp} %{buildroot}/%{_railsdir}/config/environments/production.rb %{buildroot}/%{_etcconfig}/environments/production.rb
%{__cp} %{buildroot}/%{_railsdir}/config/environments/development.rb %{buildroot}/%{_etcconfig}/environments/development.rb
%{__cp} %{buildroot}/%{_railsdir}/config/environments/test.rb %{buildroot}/%{_etcconfig}/environments/test.rb
rm %{buildroot}/%{_railsdir}/config/database.yml
/bin/ln -fs %{_etcconfig}/database.yml %{buildroot}/%{_railsdir}/config/database.yml
/bin/ln -fs %{_etcconfig}/environments/production.rb %{buildroot}/%{_railsdir}/config/environments/production.rb
/bin/ln -fs %{_etcconfig}/environments/development.rb %{buildroot}/%{_railsdir}/config/environments/development.rb
/bin/ln -fs %{_etcconfig}/environments/test.rb %{buildroot}/%{_railsdir}/config/environments/test.rb

%files
%defattr(-,root,root,-)
%{_railsdir}

%defattr(-,root,root,-)
%config(noreplace) %{_etcconfig}/database.yml
%config(noreplace) %{_etcconfig}/environments/production.rb
%config(noreplace) %{_etcconfig}/environments/development.rb
%config(noreplace) %{_etcconfig}/environments/test.rb

%clean
rm -rf %{buildroot}

# pre-installation
%pre

# post-installation
%post

# pre-uninstallation
%preun

# post-uninstallation
%postun

# changelog
%changelog

