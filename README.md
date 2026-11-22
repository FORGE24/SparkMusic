# SparkMusic

![SparkMusic](branding/wordmark.svg)

[![ci](https://github.com/FORGE24/SparkMusic/actions/workflows/ci.yml/badge.svg)](https://github.com/FORGE24/SparkMusic/actions/workflows/ci.yml)

Three related projects in one repository. They share the same recovered route
catalog: **1,293 endpoints** extracted from the NetEase Cloud Music 9.6.30
Android build.

| Path | Role | Stack | License |
|---|---|---|---|
| [`core/`](core) | Desktop client (STILLE shell) and the Qt-facing core | Rust + cxx-qt + Qt Quick | Apache-2.0 |
| [`api/`](api) | HTTP/JSON service over the catalog | Rust + Axum | Apache-2.0 |
| [`python/`](python) | Reference client + DEX recovery tooling | Python 3.9+ | MIT |

## core + gui — desktop client

`protocol/` holds the request envelopes and the route catalog, shared by `core/`
and `api/` (no duplicated crypto). `core/` speaks eapi/weapi/linuxapi, persists favourites, history,
playlist/lyric caches and the session in SQLite, and exposes a
`SparkMusicClient` QObject as `build/libsparkmusic_core.so`. `gui/` is the Qt
Quick shell (paper/ink themes, login by QR, SMS or cookie) and links that
library dynamically.

```console
$ cmake -S gui -B gui/build -G Ninja \
    -DCMAKE_CXX_COMPILER=/usr/bin/g++ \
    -DCMAKE_PREFIX_PATH=/path/to/qt6      # Qt 6.5+, verified 6.11.2
$ cmake --build gui/build                 # builds core/ too
$ ./gui/build/sparkmusic
$ ./gui/smoke.sh                          # build + tests + headless screenshots
```

The core alone can be built with `cmake -S core -B core/build && cmake --build core/build`.

### Windows

The Windows build is automated end to end and ships every runtime DLL (Qt 6,
Qt Quick/QML, Qt Multimedia/FFmpeg, `sparkmusic_core.dll`, MSVC runtime). From a
**Developer PowerShell for VS 2022**, with Qt 6 MSVC configured in
`QT_ROOT_DIR`:

```powershell
.\packaging\windows\package.ps1 -Version 0.1.3-beta
```

It writes `dist\sparkmusic-<version>-windows-x64.zip` and, when Inno Setup 6 is
installed, `dist\sparkmusic-<version>-windows-x64-setup.exe`. See
[`packaging/windows/README.md`](packaging/windows/README.md) for prerequisites,
DLL checks and the portable/installer layout.

Details: [`core/README.md`](core/README.md) and [`gui/README.md`](gui/README.md).

## api — HTTP service

The same catalog behind plain HTTP/JSON, with a generic `/call/{route}` proxy
and typed endpoints for search, songs, lyrics, playlists, albums and artists.

```console
$ cd api
$ ./cargo.sh run            # 127.0.0.1:8080
$ curl 'http://127.0.0.1:8080/health'
```

Details: [`api/README.md`](api/README.md).

## python — reference client

The original recovery work: DEX parsing tools, the route extractor, and a
class-style client with 1,293 routes, plus documentation of what was recovered
and what was deliberately not (native `xeapi`, attestation).

```console
$ cd python
$ pip install -r requirements.txt
$ python -m unittest discover -s tests -t .
```

`python/extracted/all_strings.txt` (32 MB) is intentionally not committed; it is
regenerated from the APK with `python -I tools/dex_strings.py classes*.dex`.

Details: [`python/README.md`](python/README.md) and [`python/API.md`](python/API.md).

## Licensing

* `core/` and `api/` — **Apache-2.0** (see [`LICENSE`](LICENSE)). Commercial use
  is permitted under that license; the desktop shell links **Qt 6** dynamically,
  so distributing binaries additionally requires compliance with Qt's
  **LGPL-3.0** (or a Qt commercial license).
* `python/` — **MIT**, licensed independently (see [`python/LICENSE`](python/LICENSE)).
* Dependencies keep their own licenses; the full list is in
  [`THIRD_PARTY.md`](THIRD_PARTY.md), and attribution notes are in [`NOTICE`](NOTICE).

Each subproject is licensed on its own terms: nothing in this repository
relicenses a third-party component, and the Python client's MIT terms do not
extend to `core/` or `api/`.

## CI

`.github/workflows/ci.yml` runs these jobs on every push and pull request:

* **protocol + api** — rustfmt check + `cargo test` (no Qt needed)
* **python** — unit tests on Python 3.9 and 3.12
* **core + gui** — Qt 6.8 from `install-qt-action`, `cargo test` for the core,
  then a Ninja build of the shell and two offscreen screenshots uploaded as an
  artifact (the run also asserts `ldd build/sparkmusic` resolves
  `libsparkmusic_core.so.0`)
* **windows** — `.github/workflows/windows.yml` builds the MSVC/Qt 6.8 package,
  runs the staged app offscreen and uploads the ZIP + installer

## Releases

Pushing a `v*` tag builds and publishes installable packages:

```console
$ git tag v0.1.0 && git push origin v0.1.0
```

`.github/workflows/release.yml` builds in two containers plus a Windows runner
and attaches the results to the GitHub Release:

| Job | Base image | Asset |
|---|---|---|
| `deb` | `debian:trixie` (Qt 6.8) | `sparkmusic_<version>-1_amd64.deb` |
| `rpm` | `fedora:44` (Qt 6.11) | `sparkmusic-<version>-1.x86_64.rpm` |
| `windows` | `windows-latest` (Qt 6.8 MSVC) | `sparkmusic-<version>-windows-x64.zip` + `-setup.exe` |

Each Linux job installs its own package inside the container (resolving Qt
dependencies) and checks that `libsparkmusic_core.so.0` resolves. Qt is not
bundled on Linux: the packages depend on the distribution's Qt 6 and link it
dynamically. The Windows package is self-contained and bundles the Qt DLLs,
plugins and MSVC runtime. The packaging recipes and manual commands live in
[`packaging/`](packaging) and [`packaging/windows/`](packaging/windows).
