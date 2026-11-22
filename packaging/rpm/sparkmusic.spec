%global debug_package %{nil}
%global _hardened_build 1

Name:           sparkmusic
Version:        0.1.2
Release:        1%{?dist}
Summary:        Qt Quick desktop client for the NetEase Cloud Music API

License:        Apache-2.0 AND OFL-1.1
URL:            https://github.com/FORGE24/SparkMusic
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  cmake >= 3.21
BuildRequires:  ninja-build
BuildRequires:  gcc-c++
BuildRequires:  rust >= 1.85
BuildRequires:  cargo
BuildRequires:  qt6-qtbase-devel
BuildRequires:  qt6-qtdeclarative-devel
BuildRequires:  qt6-qtmultimedia-devel
BuildRequires:  desktop-file-utils

Requires:       qt6-qtbase >= 6.5
Requires:       qt6-qtdeclarative
Requires:       qt6-qtmultimedia

%description
SparkMusic is a minimal desktop client for the NetEase Cloud Music API.

The Rust core implements the eapi/weapi/linuxapi request envelopes and carries
the 1,293-route catalog recovered from the 9.6.30 Android build. The Qt 6 /
Qt Quick shell ("STILLE") offers paper and ink themes, QR / SMS / cookie login,
lyrics, and a SQLite store for favourites, play history and caches.

The package ships only the executable and libsparkmusic_core.so.0; Qt is a
runtime dependency and is linked dynamically. No audio or artwork is bundled,
and the client is not affiliated with NetEase.

%prep
%autosetup -n %{name}-%{version}

%build
export CCACHE_DISABLE=1
cmake -S gui -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=%{_prefix} \
  -DSPARKMUSIC_LIBDIR=%{_lib} \
  -DCMAKE_CXX_COMPILER=g++
cmake --build build --verbose

%install
DESTDIR=%{buildroot} cmake --install build --strip
# Runtime package: drop the unversioned linker symlink and the copies of the
# license files installed under share/doc (handled by %license/%doc below).
rm -f %{buildroot}%{_libdir}/libsparkmusic_core.so
rm -rf %{buildroot}%{_datadir}/doc/sparkmusic

%check
LD_LIBRARY_PATH=%{buildroot}%{_libdir} %{buildroot}%{_bindir}/sparkmusic --version \
  | grep -q 'sparkmusic %{version}'
desktop-file-validate %{buildroot}%{_datadir}/applications/sparkmusic.desktop

%files
%{_bindir}/sparkmusic
%{_libdir}/libsparkmusic_core.so.0
%{_libdir}/libsparkmusic_core.so.0.*
%{_datadir}/applications/sparkmusic.desktop
%{_datadir}/icons/hicolor/512x512/apps/sparkmusic.png
%license LICENSE
%doc NOTICE THIRD_PARTY.md

%changelog
* Sat Nov 22 2026 FORGE24 <CHENshidi2021@outlook.com> - 0.1.2-1
- Initial package: Qt Quick shell, Rust core, QR/SMS/cookie login, SQLite
  favourites and history.
