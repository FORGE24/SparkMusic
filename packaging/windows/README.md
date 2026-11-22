# Windows build & packaging

`package.ps1` is the single entry point for a self-contained Windows x64 build.
It compiles the Qt Quick shell and the Rust core, stages CMake's install tree,
adds every Qt/MSVC DLL with `windeployqt`, verifies the DLL set, runs the staged
application headlessly, and writes:

| Output | Contents |
|---|---|
| `dist/sparkmusic-<version>-windows-x64.zip` | portable folder: `sparkmusic.exe`, `sparkmusic_core.dll`, Qt 6 DLLs + plugins, FFmpeg DLLs, MSVC runtime, licenses |
| `dist/sparkmusic-<version>-windows-x64-setup.exe` | Inno Setup installer around the same folder (when ISCC is available) |
| `dist/SHA256SUMS-windows.txt` | checksums for the artifacts |

The unpacked folder lives at `build-windows/sparkmusic-<version>-windows-x64/`.

## Prerequisites

* Windows 10/11 x64
* Visual Studio 2022 with **Desktop development with C++** (MSVC x64 + Windows SDK)
* Qt 6.5+ for **MSVC 2022 64-bit**, including **Qt Multimedia** (Qt 6.8.3 is
  what CI uses; 6.11 also works)
* Rust 1.85+ with the `x86_64-pc-windows-msvc` target (`rustup default stable-msvc`)
* CMake 3.21+ and Ninja on `PATH`
* Inno Setup 6 (optional, for the setup executable)

Open **Developer PowerShell for VS 2022** so `cl.exe`, `link.exe`, `cmake`,
`ninja` and `cargo` are on `PATH`, then:

```powershell
# Qt is found through QT_ROOT_DIR, an explicit prefix, or qmake on PATH.
$env:QT_ROOT_DIR = "C:\Qt\6.8.3\msvc2022_64"

.\packaging\windows\package.ps1
# or pin the version and paths:
.\packaging\windows\package.ps1 `
    -Version 0.1.4-beta `
    -QtPrefix C:\Qt\6.8.3\msvc2022_64 `
    -BuildDir build-windows
```

If Inno Setup is installed in a non-standard place, pass `-Iscc` or set `ISCC`.
Use `-NoInstaller` to produce only the ZIP; `-RequireInstaller` turns a missing
ISCC into an error (CI uses this). `-SkipBuild` reuses an existing build tree;
`-SkipSmoke` skips the offscreen run.

## What is actually in the package

`package.ps1` never copies `build/` by hand. It runs:

```powershell
cmake -S gui -B build-windows -G Ninja `
      -DCMAKE_BUILD_TYPE=Release `
      -DCMAKE_PREFIX_PATH=$env:QT_ROOT_DIR `
      -DSPARKMUSIC_VERSION=0.1.3-beta `
      -DSPARKMUSIC_CARGO_PROFILE=release
cmake --build build-windows
cmake --install build-windows --prefix build-windows\sparkmusic-0.1.3-beta-windows-x64
windeployqt --release --no-translations --compiler-runtime `
             --qmldir gui\qml --dir <stage> <stage>\sparkmusic.exe
```

`windeployqt` contributes:

* `Qt6Core.dll`, `Qt6Gui.dll`, `Qt6Qml.dll`, `Qt6Quick.dll`,
  `Qt6Multimedia.dll` and the other Qt libraries the executable imports
* `platforms\qwindows.dll` (plus `qoffscreen.dll` for the smoke test)
* the plugin folders the deployed modules need, including
  `imageformats\*.dll` (JPEG covers) and `multimedia\*.dll`
* the FFmpeg runtime (`avcodec-*.dll`, `avformat-*.dll`, `avutil-*.dll`,
  `swresample-*.dll`, `swscale-*.dll`) used by Qt Multimedia
* the MSVC runtime (`vcruntime140.dll`, `vcruntime140_1.dll`, `msvcp140.dll`)

The script then checks that the executable, `sparkmusic_core.dll`, the Qt
libraries, `platforms\qwindows.dll`, `imageformats\qjpeg.dll` and a multimedia
backend plugin exist, and fails the build if any are missing.

## The core DLL

`core/` is built as `sparkmusic_core.dll`; the executable imports it. CXX-Qt's
generated C++ class has no `__declspec(dllimport)` annotations, so exporting the
class itself across a Windows DLL boundary is fragile (vtable and static
metaobject are data symbols). Instead the DLL exports a two-function C API
(`core/include/sparkmusic/core_api.h`):

```cpp
QObject *sparkmusic_client_create();
void     sparkmusic_client_destroy(QObject *client);
```

The GUI owns the QObject through that API and reaches its `Q_INVOKABLE`s via
QML/metainvocation. On Linux the same API is compiled in and exported normally,
so the design is identical on both platforms. `SPARKMUSIC_CARGO_PROFILE=release`
builds the Rust half without debug assertions for the package.

## Qt licensing

Qt is bundled as unmodified DLLs, which keeps the LGPL-3.0 relinking route open.
The stage includes `LICENSE`, `NOTICE`, `THIRD_PARTY.md` and the Qt `LICENSES`
folder (when the Qt installation ships one). Commercial distribution should
review Qt's obligations or use a Qt commercial license.

## CI

`.github/workflows/windows.yml` runs this script on `windows-latest` for pushes
and pull requests. `.github/workflows/release.yml` does the same for a `v*` tag,
installs Inno Setup, and attaches the ZIP/setup/checksums to the GitHub Release
next to the deb/rpm assets.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Qt 6 MSVC not found` | Set `QT_ROOT_DIR`/`-QtPrefix` to the `msvc2022_64` kit (not MinGW). |
| `cl.exe`/`ninja` not found | Start Developer PowerShell for VS 2022, or use `ilammy/msvc-dev-cmd` in CI. |
| `cargo` builds Linux/mingw objects | `rustup default stable-msvc`; the target must be `x86_64-pc-windows-msvc`. |
| Missing `Qt6Multimedia.dll` | Install the Qt Multimedia module in Qt Maintenance Tool. |
| No `multimedia` plugin | Reinstall Qt Multimedia; the FFmpeg backend ships with it. |
| Installer not produced | Install Inno Setup 6 or pass `-Iscc C:\...\ISCC.exe`; use `-NoInstaller` to skip. |
| App starts without audio | Check `avcodec-*.dll` and `multimedia\*` next to the exe; don't split the folder. |
