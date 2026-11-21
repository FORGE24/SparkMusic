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
