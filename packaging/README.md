# Packaging

`nfpm.yaml` turns an install tree into a `.deb` and a `.rpm` from the same
recipe (no `rpmbuild`/`dpkg-deb` needed).

```console
$ cmake -S gui -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
$ cmake --build build
$ DESTDIR=$PWD/staging cmake --install build
$ VERSION=0.1.0 ARCH=amd64 nfpm package -f packaging/nfpm.yaml -p deb -t dist/
$ VERSION=0.1.0 ARCH=amd64 nfpm package -f packaging/nfpm.yaml -p rpm -t dist/
```

The package installs:

| Path | Content |
|---|---|
| `/usr/bin/sparkmusic` | Qt Quick shell (`RUNPATH=$ORIGIN/../lib`) |
| `/usr/lib/libsparkmusic_core.so.0` | Rust core (soname) |
| `/usr/share/applications/sparkmusic.desktop` | launcher entry |
| `/usr/share/icons/hicolor/512x512/apps/sparkmusic.png` | icon |
| `/usr/share/doc/sparkmusic/{LICENSE,NOTICE}` | licensing |

Qt is **not** bundled: the packages depend on the distribution's Qt 6 (>= 6.5)
and link it dynamically, which also satisfies Qt's LGPL-3.0 relinking
requirement. `maint script` hooks are not used; no daemon or service is
installed.

`.github/workflows/release.yml` builds inside `debian:trixie` and `fedora:44`,
installs the resulting package in that container as a dependency check, then
publishes the files to the GitHub Release for the pushed `v*` tag.

## Portable directory (no package)

For a raw build that runs from its own folder:

```console
$ cmake -S gui -B portablebuild -G Ninja \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/
$ cmake --build portablebuild
$ DESTDIR=/path/sparkmusic-v<version>-linux-glibc \
    cmake --install portablebuild --strip
$ /path/.../bin/sparkmusic --version
```

The layout is `bin/sparkmusic` (RUNPATH `$ORIGIN/../lib`), `lib/libsparkmusic_core.so.0`,
desktop entry and icon under `share/`, plus `LICENSE`/`NOTICE`/`THIRD_PARTY.md`.
No database is shipped: the app writes to `$XDG_DATA_HOME/sparkmusic/`
(default `~/.local/share/sparkmusic/`), so the folder stays clean and can be
deleted without losing that data.

## Windows (portable ZIP + installer)

Windows has a separate, self-contained recipe because Qt is **bundled** there:
`packaging/windows/package.ps1` builds with MSVC + Ninja, stages the CMake
install tree, runs `windeployqt` for the Qt DLLs/plugins/FFmpeg, checks the DLL
set, smoke-tests the staged app offscreen and writes:

```console
PS> .\packaging\windows\package.ps1 -Version 0.1.3-beta
   -> dist\sparkmusic-0.1.3-beta-windows-x64.zip
   -> dist\sparkmusic-0.1.3-beta-windows-x64-setup.exe   (Inno Setup 6)
   -> dist\SHA256SUMS-windows.txt
```

The ZIP contains `sparkmusic.exe`, `sparkmusic_core.dll`, Qt 6 + Multimedia +
FFmpeg DLLs, `platforms\qwindows.dll` and the MSVC runtime, so it runs without a
Qt or Visual C++ installation. See [`windows/README.md`](windows/README.md) for
prerequisites and the full DLL inventory. `.github/workflows/windows-package.yml`
runs it in CI and on release tags.

## Copr / Packit

`packaging/rpm/sparkmusic.spec` builds the RPM on Fedora 43–45, rawhide and
RHEL 10 (the versions there ship Qt 6.9–6.11 and Rust ≥ 1.96, both above the
cxx-qt floor of Qt 6.5 / Rust 1.85). `%{_libdir}` is honoured through
`-DSPARKMUSIC_LIBDIR=%{_lib}`, so the core lands in `/usr/lib64` on those
distributions.

`packit.yaml` points Packit at the spec and at a Copr project named
`SparkMusic`; every GitHub release (`v*` tag) creates a Copr build for the
targets listed there.

```console
$ packaging/rpm/version.sh          # v0.1.2-beta -> 0.1.2
$ packaging/rpm/archive.sh          # sparkmusic-0.1.2.tar.gz for %autosetup
$ rpmbuild -ba --nodeps packaging/rpm/sparkmusic.spec
```

Copr needs network access during the build (Cargo fetches crates.io);
enable "Enable internet access during builds" in the project settings.
