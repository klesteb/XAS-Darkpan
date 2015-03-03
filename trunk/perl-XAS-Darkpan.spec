Name:           perl-XAS-Darkpan
Version:        0.01
Release:        1%{?dist}
Summary:        A set of processes and modules to manage a local CPAN repository
License:        GPL+ or Artistic
Group:          Development/Libraries
URL:            http://scm.kesteb.us/git/XAS-Darkpan/trunk/
Source0:        XAS-XXXX-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(Module::Build)
BuildRequires:  perl(Test::More)
Requires:       perl(XAS) >= 0.08
Requires        perl(XAS::Model) >= 0.01
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
A set of process and procedure to manage a local CPAN repository

%prep
%setup -q -n XAS-Darkpan-%{version}

%build
%{__perl} Build.PL installdirs=vendor
./Build

%install
rm -rf $RPM_BUILD_ROOT

./Build install destdir=$RPM_BUILD_ROOT create_packlist=0
./Build redhat destdir=$RPM_BUILD_ROOT

find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;
%{_fixperms} $RPM_BUILD_ROOT/*

%check
./Build test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc Changes README
%{perl_vendorlib}/*
%config(noreplace) /etc/xas/darkpan.ini
/usr/share/man/*

%changelog
* Tue Mar 18 2014 "kesteb <kevin@kesteb.us>" 0.01-1
- Created for the v0.01 release.
