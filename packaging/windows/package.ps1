#Requires -Version 5.1
<#
.SYNOPSIS
    Build and package SparkMusic for Windows x64 with all required DLLs.

.DESCRIPTION
    Configures a Release build (Ninja + MSVC), stages sparkmusic.exe and
    sparkmusic_core.dll through CMake's install rules, runs windeployqt to add
    the Qt 6 runtime (Qt Quick/QML, Multimedia/FFmpeg, platform and image
    plugins), bundles the MSVC runtime, smoke-tests the staged app, then writes
    a portable ZIP and, when Inno Setup is available, a setup executable.

    Run this from a "Developer PowerShell for VS 2022" (cl.exe, cmake, ninja and
    cargo must be on PATH), or in CI with ilammy/msvc-dev-cmd.

.EXAMPLE
    .\packaging\windows\package.ps1

.EXAMPLE
    .\packaging\windows\package.ps1 -Version 0.1.4-beta -QtPrefix C:\Qt\6.8.3\msvc2022_64
#>
[CmdletBinding()]
param(
    # Display version, e.g. 0.1.3-beta. Defaults to the nearest git tag.
    [string]$Version = "",

    # Qt 6 MSVC prefix. Defaults to $env:QT_ROOT_DIR, then `qmake -query`.
    [string]$QtPrefix = $env:QT_ROOT_DIR,

    # Build directory (relative to the repository root).
    [string]$BuildDir = "build-windows",

    # Output directory for ZIP/setup/checksums.
    [string]$DistDir = "dist",

    [string]$Generator = "Ninja",

    [ValidateSet("debug", "release")]
    [string]$CargoProfile = "release",

    # Reuse an existing build tree instead of running cmake configure/build.
    [switch]$SkipBuild,

    # Skip the staged-app smoke test (--version + offscreen screenshot).
    [switch]$SkipSmoke,

    # Do not look for Inno Setup.
    [switch]$NoInstaller,

    # Fail when Inno Setup is missing instead of only producing the ZIP.
    [switch]$RequireInstaller,

    # Explicit path to ISCC.exe. Defaults to $env:ISCC, PATH and the usual
    # "Inno Setup 6" install locations.
    [string]$Iscc = $env:ISCC
)

$ErrorActionPreference = "Stop"

function Fail {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "error: $Message" -ForegroundColor Red

    # GitHub Actions renders ::error:: lines as annotations, which makes a
    # headless CI failure diagnosable without downloading the raw step log.
    if ($env:GITHUB_ACTIONS -eq "true") {
        Write-Host "::error title=Windows package::$Message"
        $build = Get-Variable -Name BuildPath -Scope Script -ErrorAction SilentlyContinue
        if ($build -and (Test-Path $build.Value)) {
            foreach ($name in @("CMakeFiles\CMakeConfigureLog.yaml", "CMakeFiles\CMakeError.log")) {
                $log = Join-Path $build.Value $name
                if (Test-Path $log) {
                    $text = (Get-Content -Path $log -Tail 150) -join " || "
                    Write-Host "::error title=CMake::$text"
                }
            }
        }
    }
    exit 1
}

function Invoke-Native {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )
    Write-Host "> $FilePath $($Arguments -join ' ')" -ForegroundColor DarkGray

    # Capture merged stdout/stderr so a failure can be annotated with the real
    # compiler/linker/Qt error instead of just an exit code.
    $output = & $FilePath @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    $output | ForEach-Object { Write-Host $_ }

    if ($exitCode -ne 0) {
        if ($env:GITHUB_ACTIONS -eq "true") {
            $lines = @($output | ForEach-Object { "$_" })
            $interesting = @($lines | Where-Object {
                $_ -match 'LNK\d+|unresolved external|fatal error|error C\d+|error RC\d+|error :|error:|FAILED:|CMake Error'
            })
            if ($interesting.Count -eq 0) {
                $interesting = @($lines | Select-Object -Last 10)
            } else {
                $interesting = @($interesting | Select-Object -Last 10)
            }
            $tail = ($interesting | ForEach-Object {
                if ($_.Length -gt 500) { $_.Substring(0, 500) + '...' } else { $_ }
            }) -join " || "
            Write-Host "::error title=Command failed::$FilePath :: $tail"
        }
        Fail "$FilePath exited with code $exitCode"
    }
}

function Invoke-StagedApp {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [int]$TimeoutMs = 90000
    )
    $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments `
        -WorkingDirectory $Stage -PassThru
    if (-not $process.WaitForExit($TimeoutMs)) {
        try { $process.Kill() } catch { }
        Fail "$FilePath did not exit within $TimeoutMs ms."
    }
    return $process.ExitCode
}

function Get-DefaultVersion {
    if ($env:SPARKMUSIC_VERSION) {
        return $env:SPARKMUSIC_VERSION
    }
    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($git) {
        $tag = & $git.Source describe --tags --abbrev=0 2>$null
        if ($LASTEXITCODE -eq 0 -and $tag) {
            return $tag.Trim()
        }
    }
    return "0.1.3-beta"
}

function Resolve-QtPrefix {
    param([string]$Candidate)
    if ($Candidate) {
        if (-not (Test-Path (Join-Path $Candidate "bin\windeployqt.exe"))) {
            Fail "'$Candidate' does not contain bin\windeployqt.exe; pass -QtPrefix."
        }
        return (Resolve-Path $Candidate).Path
    }

    $qmake = Get-Command qmake -ErrorAction SilentlyContinue
    if ($qmake) {
        $prefix = & $qmake.Source -query QT_INSTALL_PREFIX
        if ($LASTEXITCODE -eq 0 -and $prefix) {
            $prefix = $prefix.Trim()
            if (Test-Path (Join-Path $prefix "bin\windeployqt.exe")) {
                return (Resolve-Path $prefix).Path
            }
        }
    }

    Fail "Qt 6 MSVC not found. Set QT_ROOT_DIR, pass -QtPrefix, or put qmake on PATH."
}

function Resolve-Iscc {
    param([string]$Candidate)
    if ($Candidate) {
        if (Test-Path $Candidate) { return (Resolve-Path $Candidate).Path }
        Fail "ISCC.exe not found at '$Candidate'."
    }
    $command = Get-Command iscc.exe -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    $roots = @(${env:ProgramFiles(x86)}, $env:ProgramFiles, $env:LOCALAPPDATA)
    foreach ($root in $roots) {
        if (-not $root) { continue }
        $candidate = Join-Path $root "Inno Setup 6\ISCC.exe"
        if (Test-Path $candidate) { return (Resolve-Path $candidate).Path }
    }
    return $null
}

$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $Root

if (-not $Version) {
    $Version = Get-DefaultVersion
}
$Version = ($Version.Trim() -replace '^[vV]', '')
if ($Version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z.]+)*$') {
    Fail "invalid version '$Version' (expected something like 0.1.3-beta)"
}
if ($NoInstaller -and $RequireInstaller) {
    Fail "-NoInstaller and -RequireInstaller are mutually exclusive."
}

$QtPrefix = Resolve-QtPrefix -Candidate $QtPrefix
$Windeployqt = Join-Path $QtPrefix "bin\windeployqt.exe"

foreach ($tool in @("cmake", "cargo")) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Fail "'$tool' is not on PATH. Use a Developer PowerShell for VS 2022."
    }
}
$Cmake = (Get-Command cmake).Source

$BuildPath = [IO.Path]::GetFullPath((Join-Path $Root $BuildDir))
$DistPath = [IO.Path]::GetFullPath((Join-Path $Root $DistDir))
$StageName = "sparkmusic-$Version-windows-x64"
$Stage = Join-Path $BuildPath $StageName

Write-Host "SparkMusic $Version" -ForegroundColor Cyan
Write-Host "  repo:   $Root"
Write-Host "  Qt:     $QtPrefix"
Write-Host "  build:  $BuildPath"
Write-Host "  stage:  $Stage"
Write-Host "  output: $DistPath"

New-Item -ItemType Directory -Force -Path $BuildPath, $DistPath | Out-Null
if (Test-Path $Stage) {
    Remove-Item -Path $Stage -Recurse -Force
}

# ---- build + install -------------------------------------------------------
if (-not $SkipBuild) {
    Invoke-Native -FilePath $Cmake -Arguments @(
        "-S", (Join-Path $Root "gui"),
        "-B", $BuildPath,
        "-G", $Generator,
        "-DCMAKE_BUILD_TYPE=Release",
        "-DCMAKE_PREFIX_PATH=$QtPrefix",
        "-DSPARKMUSIC_VERSION=$Version",
        "-DSPARKMUSIC_CARGO_PROFILE=$CargoProfile"
    )

    Invoke-Native -FilePath $Cmake -Arguments @(
        "--build", $BuildPath, "--config", "Release", "--parallel"
    )
}

Invoke-Native -FilePath $Cmake -Arguments @(
    "--install", $BuildPath, "--config", "Release", "--prefix", $Stage
)

$Exe = Join-Path $Stage "sparkmusic.exe"
$CoreDll = Join-Path $Stage "sparkmusic_core.dll"
foreach ($file in @($Exe, $CoreDll)) {
    if (-not (Test-Path $file)) {
        Fail "missing $file after cmake --install"
    }
}

# ---- Qt runtime ------------------------------------------------------------
$QmlDir = Join-Path $Root "gui\qml"
Invoke-Native -FilePath $Windeployqt -Arguments @(
    "--release", "--no-translations", "--compiler-runtime",
    "--qmldir", $QmlDir, "--dir", $Stage, $Exe
)

# windeployqt picks qwindows.dll by default. Keep the offscreen platform plugin
# as well so the packaged app can be smoke-tested on a headless CI agent.
$PlatformsDir = Join-Path $Stage "platforms"
if (Test-Path $PlatformsDir) {
    $Offscreen = Join-Path $QtPrefix "plugins\platforms\qoffscreen.dll"
    if (Test-Path $Offscreen) {
        Copy-Item -Path $Offscreen -Destination $PlatformsDir -Force
    }
}

# ---- bundled runtime checks ------------------------------------------------
$Required = @(
    "sparkmusic.exe",
    "sparkmusic_core.dll",
    "Qt6Core.dll",
    "Qt6Gui.dll",
    "Qt6Qml.dll",
    "Qt6Quick.dll",
    "Qt6Multimedia.dll",
    "platforms\qwindows.dll",
    "imageformats\qjpeg.dll"
)
foreach ($relative in $Required) {
    if (-not (Test-Path (Join-Path $Stage $relative))) {
        Fail "windeployqt did not produce $relative; the package would be incomplete."
    }
}

$MultimediaPlugins = Get-ChildItem -Path (Join-Path $Stage "multimedia") -Filter *.dll `
    -ErrorAction SilentlyContinue
if (-not $MultimediaPlugins) {
    Fail "no Qt Multimedia backend plugin in '$Stage\multimedia'; audio would not work."
}
$FfmpegPlugin = $MultimediaPlugins | Where-Object { $_.Name -like "*ffmpeg*" }
$Avcodec = Get-ChildItem -Path $Stage -Filter "avcodec-*.dll" -ErrorAction SilentlyContinue
if ($FfmpegPlugin -and -not $Avcodec) {
    Fail "windeployqt deployed $($FfmpegPlugin[0].Name) but not the FFmpeg runtime (avcodec-*.dll)."
}
if (-not $Avcodec) {
    Write-Warning "No FFmpeg DLLs deployed; check the Qt Multimedia backend if audio is silent."
}

# windeployqt normally copies these. Fall back to the VC redist / System32 so a
# machine without the Developer environment still gets a self-contained folder.
foreach ($runtime in @("vcruntime140.dll", "vcruntime140_1.dll", "msvcp140.dll")) {
    if (Test-Path (Join-Path $Stage $runtime)) { continue }
    $candidates = @()
    if ($env:VCToolsRedistDir) {
        $crtRoot = Join-Path $env:VCToolsRedistDir "x64"
        $crtDirs = Get-ChildItem -Path $crtRoot -Directory -Filter "Microsoft.VC*.CRT" `
            -ErrorAction SilentlyContinue
        foreach ($crtDir in $crtDirs) {
            $candidates += (Join-Path $crtDir.FullName $runtime)
        }
    }
    if ($env:SystemRoot) {
        $candidates += (Join-Path $env:SystemRoot "System32\$runtime")
    }
    $found = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($found) {
        Copy-Item -Path $found -Destination $Stage -Force
    }
}
foreach ($runtime in @("vcruntime140.dll", "msvcp140.dll")) {
    if (-not (Test-Path (Join-Path $Stage $runtime))) {
        Fail "MSVC runtime $runtime is missing; install the VC++ x64 redistributable or run from a Developer prompt."
    }
}

# Qt's LGPL terms: ship the license texts and keep Qt as replaceable DLLs.
$QtLicenses = Join-Path $QtPrefix "LICENSES"
if (Test-Path $QtLicenses) {
    $LicenseTarget = Join-Path $Stage "licenses\qt"
    New-Item -ItemType Directory -Force -Path $LicenseTarget | Out-Null
    Copy-Item -Path (Join-Path $QtLicenses "*") -Destination $LicenseTarget -Recurse -Force
}

$Readme = @"
SparkMusic $Version - portable Windows x64 build
=================================================

Run sparkmusic.exe.

All runtime DLLs are in this folder: sparkmusic_core.dll, the Qt 6 libraries
(Core, Gui, Qml, Quick, Multimedia and their FFmpeg/plugin DLLs) and the MSVC
runtime. Keep the folder together; do not move the executable out on its own.

User data (favourites, history, session cookie, caches) is stored in:
  %LOCALAPPDATA%\sparkmusic\sparkmusic.db

Licenses: LICENSE, NOTICE, THIRD_PARTY.md and licenses\qt\.
Qt is bundled as unmodified DLLs under LGPL-3.0; you may replace those DLLs
with compatible builds.
"@
Set-Content -Path (Join-Path $Stage "README.txt") -Value $Readme -Encoding UTF8

# ---- smoke test ------------------------------------------------------------
if (-not $SkipSmoke) {
    Write-Host "smoke: --version + offscreen screenshot" -ForegroundColor Cyan
    $OldQpa = $env:QT_QPA_PLATFORM
    try {
        $env:QT_QPA_PLATFORM = "offscreen"

        if ((Invoke-StagedApp -FilePath $Exe -Arguments @("--version") -TimeoutMs 30000) -ne 0) {
            Fail "staged sparkmusic.exe --version failed (a DLL is probably missing)."
        }

        $TempDir = [IO.Path]::GetTempPath()
        if (-not $TempDir) { $TempDir = $Stage }
        $Shot = Join-Path $TempDir ("sparkmusic-smoke-{0}.png" -f $PID)
        $ShotArgs = @("--screenshot", ('"{0}"' -f $Shot), "--view", "login", "--delay", "2500")
        if ((Invoke-StagedApp -FilePath $Exe -Arguments $ShotArgs) -ne 0) {
            Fail "staged offscreen screenshot failed; Qt/QML DLLs are incomplete."
        }
        if (-not (Test-Path $Shot) -or (Get-Item $Shot).Length -lt 1000) {
            Fail "staged offscreen screenshot was not written."
        }
        Remove-Item -Path $Shot -Force -ErrorAction SilentlyContinue
        Write-Host "smoke: ok" -ForegroundColor Green
    } finally {
        if ($null -eq $OldQpa) {
            Remove-Item Env:\QT_QPA_PLATFORM -ErrorAction SilentlyContinue
        } else {
            $env:QT_QPA_PLATFORM = $OldQpa
        }
    }
}

# ---- portable ZIP ----------------------------------------------------------
$ZipPath = Join-Path $DistPath "$StageName.zip"
if (Test-Path $ZipPath) {
    Remove-Item -Path $ZipPath -Force
}
Write-Host "zip: $ZipPath" -ForegroundColor Cyan
Compress-Archive -Path $Stage -DestinationPath $ZipPath -CompressionLevel Optimal

# ---- Inno Setup installer --------------------------------------------------
$Artifacts = @($ZipPath)
if (-not $NoInstaller) {
    $IsccPath = Resolve-Iscc -Candidate $Iscc
    if (-not $IsccPath) {
        if ($RequireInstaller) {
            Fail "Inno Setup (ISCC.exe) not found; install it or pass -Iscc."
        }
        Write-Warning "Inno Setup not found; skipping the setup executable (portable ZIP is ready)."
    } else {
        $NumericVersion = "0.1.3"
        if ($Version -match '^([0-9]+\.[0-9]+\.[0-9]+)') {
            $NumericVersion = $Matches[1]
        }
        Invoke-Native -FilePath $IsccPath -Arguments @(
            "/DMyAppVersion=$NumericVersion",
            "/DMyAppDisplayVersion=$Version",
            "/DStageDir=$Stage",
            "/DOutputDir=$DistPath",
            "/DMyAppIcon=$(Join-Path $Root 'gui\sparkmusic.ico')",
            (Join-Path $Root "packaging\windows\sparkmusic.iss")
        )

        $Setup = Join-Path $DistPath "$StageName-setup.exe"
        if (-not (Test-Path $Setup)) {
            Fail "ISCC completed but $Setup was not created."
        }
        $Artifacts += $Setup
    }
}

# ---- checksums -------------------------------------------------------------
$ChecksumPath = Join-Path $DistPath "SHA256SUMS-windows.txt"
$Lines = foreach ($artifact in $Artifacts) {
    $hash = (Get-FileHash -Path $artifact -Algorithm SHA256).Hash.ToLowerInvariant()
    "{0}  {1}" -f $hash, (Split-Path -Leaf $artifact)
}
Set-Content -Path $ChecksumPath -Value $Lines -Encoding ASCII
$Artifacts += $ChecksumPath

Write-Host ""
Write-Host "artifacts:" -ForegroundColor Green
foreach ($artifact in $Artifacts) {
    $size = "{0:N1} MB" -f ((Get-Item $artifact).Length / 1MB)
    Write-Host ("  {0}  ({1})" -f $artifact, $size)
}
