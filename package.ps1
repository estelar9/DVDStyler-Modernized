# DVDStyler Windows Packaging Script (Full Hybrid Strategy)
# Usage: .\package.ps1 [-SkipBuild] [-ZipOnly]
# Automatically collects DLLs from MSYS2 and Tools from MSYS2 or official Install.
# If Inno Setup is found, creates an installer .exe.

param(
    [switch]$SkipBuild,
    [switch]$ZipOnly
)

$ErrorActionPreference = "Stop"
$ROOT = $PSScriptRoot
$MSYS2_ROOT = if ($env:MSYS2_ROOT) { $env:MSYS2_ROOT } else { "C:\msys64" }
$UCRT = "$MSYS2_ROOT\ucrt64\bin"
$USR_BIN = "$MSYS2_ROOT\usr\bin"
$SRC = Join-Path $ROOT "src"
$VERSION = "3.3b4"

# Summary Data
$summaryTools = @()

# Fallback paths for official tools
$OFFICIAL_BIN = "C:\Program Files\DVDStyler\bin"
$OFFICIAL_BIN_X86 = "C:\Program Files (x86)\DVDStyler\bin"

# Search for Inno Setup compiler
$ISCC = Get-Command iscc.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Definition
if (-not $ISCC) {
    if (Test-Path "C:\Program Files (x86)\Inno Setup 6\ISCC.exe") { $ISCC = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" }
}

Write-Host "`n====================================================" -ForegroundColor Cyan
Write-Host "    DVDStyler Packaging System (Professional)    " -ForegroundColor Cyan
Write-Host "====================================================`n" -ForegroundColor Cyan
Write-Host "Version    : $VERSION"
Write-Host "Build      : $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Write-Host "Source     : $SRC"
Write-Host "UCRT64     : $UCRT"
if ($ISCC) { Write-Host "Inno Setup : $ISCC" -ForegroundColor Green } else { Write-Host "Inno Setup : NOT FOUND (Portable ZIP only)" -ForegroundColor Red }

if (-not (Test-Path $MSYS2_ROOT)) {
    Write-Host "`n[FATAL] MSYS2 not found at $MSYS2_ROOT" -ForegroundColor Red
    Write-Host "Please install MSYS2 from https://www.msys2.org/ and ensure it's at $MSYS2_ROOT" -ForegroundColor Cyan
    exit 1
}

if (-not (Test-Path $UCRT)) {
    Write-Host "`n[FATAL] UCRT64 environment not found at $UCRT" -ForegroundColor Red
    Write-Host "Please open MSYS2 and run the following command to install the required toolchain:" -ForegroundColor Cyan
    Write-Host "pacman -S --needed base-devel mingw-w64-ucrt-x86_64-toolchain mingw-w64-ucrt-x86_64-wxwidgets3.2-msw mingw-w64-ucrt-x86_64-ffmpeg mingw-w64-ucrt-x86_64-libsvg mingw-w64-ucrt-x86_64-wxsvg" -ForegroundColor White
    exit 1
}

# -----------------------------------------------------------------------
# 1. COMPILATION
if (-not $SkipBuild) {
    Write-Host "`n[1/4] Starting Compilation Process..." -ForegroundColor Yellow
    $msys2sh = "$USR_BIN\bash.exe"
    if (Test-Path $msys2sh) {
        $drive = $SRC.Substring(0, 1).ToLower()
        $rest = $SRC.Substring(2).Replace("\", "/")
        $makePath = "/$drive$rest"
        Write-Host "  Invoking 'make' in $makePath..."
        & $msys2sh -lc "cd '$makePath' && make -j16"
        if ($LASTEXITCODE -ne 0) { Write-Error "Compilation failed. Check terminal logs for errors." }
        Write-Host "  Compilation successful!" -ForegroundColor Green
    }
}

$exe = Join-Path $SRC "dvdstyler.exe"
if (-not (Test-Path $exe)) { Write-Error "dvdstyler.exe not found in $SRC. Please build the project first." }

# -----------------------------------------------------------------------
# 2. RUNTIME COLLECTION (Full MSYS2 UCRT64)
Write-Host "`n[2/4] Harvesting Runtime Libraries (DLLs)..." -ForegroundColor Yellow
Write-Host "  Purging stale libraries from staging area..."
Get-ChildItem $SRC -Filter "*.dll" -File | Remove-Item -Force -ErrorAction SilentlyContinue

Write-Host "  Bundling all UCRT64 DLLs..." -ForegroundColor Cyan
Copy-Item "$UCRT\*.dll" $SRC -Force -ErrorAction SilentlyContinue
$dllCount = (Get-ChildItem $SRC -Filter "*.dll").Count
Write-Host "  OK: Bundled $dllCount runtime libraries." -ForegroundColor Green

# -----------------------------------------------------------------------
# 3. EXTERNAL TOOLS (Hybrid Fallback)
Write-Host "`n[3/4] Harvesting Authoring Tools..." -ForegroundColor Yellow
$toolsList = @("ffmpeg.exe", "ffprobe.exe", "mplex.exe", "dvdauthor.exe", "mkisofs.exe", "spumux.exe")

foreach ($t in $toolsList) {
    $src_tool = $null
    
    # 1. Tester UCRT64
    if (Test-Path (Join-Path $UCRT $t)) { $src_tool = Join-Path $UCRT $t }
    # 2. Tester MSYS USR_BIN
    elseif (Test-Path (Join-Path $USR_BIN $t)) { $src_tool = Join-Path $USR_BIN $t }
    # 3. Tester Installation Officielle (Fallback de secours)
    elseif (Test-Path (Join-Path $OFFICIAL_BIN $t)) { $src_tool = Join-Path $OFFICIAL_BIN $t }
    elseif (Test-Path (Join-Path $OFFICIAL_BIN_X86 $t)) { $src_tool = Join-Path $OFFICIAL_BIN_X86 $t }

    if ($src_tool) {
        Copy-Item $src_tool $SRC -Force
        $toolDir = Split-Path $src_tool -Parent
        $location = Split-Path $toolDir -Leaf
        Write-Host "  OK : $t (Found in $location)" -ForegroundColor Green
        
        $summaryTools += [PSCustomObject]@{ Tool = $t; Source = $location; Status = "OK" }

        # Legacy DLL sidecar collection
        if ($src_tool -like "*Program Files*") {
            $legacyDlls = 0
            Get-ChildItem $toolDir -Filter "*.dll" | ForEach-Object {
                $dest = Join-Path $SRC $_.Name
                if (-not (Test-Path $dest)) {
                    Copy-Item $_.FullName $dest -Force
                    $legacyDlls++
                }
            }
            if ($legacyDlls -gt 0) { Write-Host "     + Bundled $legacyDlls legacy compatibility DLL(s)" -ForegroundColor Gray }
        }
    }
    else {
        Write-Host "  !! Tool $t NOT FOUND" -ForegroundColor Red
        $summaryTools += [PSCustomObject]@{ Tool = $t; Source = "MISSING"; Status = "FAILED" }
        if ($t -eq "mplex.exe" -or $t -eq "dvdauthor.exe") {
            Write-Warning "Critical tool $t is missing. DVD creation will fail."
        }
    }
}

# Fonts config
$fontsConf = "$MSYS2_ROOT\ucrt64\etc\fonts\fonts.conf"
if (Test-Path $fontsConf) { Copy-Item $fontsConf $SRC -Force }

# -----------------------------------------------------------------------
# 4. PACKAGING
Write-Host "`n[4/4] Creating Distribution Packages..." -ForegroundColor Yellow

$zipName = "DVDStyler-$VERSION-portable.zip"
$zipPath = Join-Path $ROOT $zipName
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

$tempDir = Join-Path $env:TEMP "dvdstyler-pkg-$VERSION"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir | Out-Null
$pkgDir = Join-Path $tempDir "DVDStyler-$VERSION"
$binDir = Join-Path $pkgDir "bin"
New-Item -ItemType Directory -Path $binDir -Force | Out-Null

Write-Host "  Staging portable directory..." -ForegroundColor Cyan
Get-ChildItem "$SRC\*" -Include *.exe, *.dll, fonts.conf, *.bat, *.rtf, *.pdf, *.xml -File | Copy-Item -Destination $binDir -Force

$folders = @("backgrounds", "buttons", "objects", "templates", "transitions", "data", "docs", "locale")
foreach ($f in $folders) {
    $fpath = Join-Path $ROOT $f
    if (Test-Path $fpath) { Copy-Item $fpath $pkgDir -Recurse -Force }
}

Write-Host "  Compressing Portable ZIP..."
Compress-Archive -Path "$pkgDir" -DestinationPath $zipPath -Force
$zipSize = [math]::Round((Get-Item $zipPath).Length / 1MB, 1)

# Inno Setup compilation
$installerStatus = "Not built"
if ($ISCC -and -not $ZipOnly) {
    Write-Host "  Compiling Professional Installer (Inno Setup)..." -ForegroundColor Cyan
    $issFile = Join-Path $ROOT "installer\DVDStyler.iss"
    if (Test-Path $issFile) {
        & $ISCC $issFile
        if ($LASTEXITCODE -eq 0) {
            $installerStatus = "SUCCESS"
        }
        else {
            $installerStatus = "FAILED (Code $LASTEXITCODE)"
        }
    }
}

# Cleanup
Remove-Item $tempDir -Recurse -Force

# FINAL SUMMARY
Write-Host "`n====================================================" -ForegroundColor Cyan
Write-Host "                BUILD COMPLETED                      " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "`nAuthoring Tools Summary:"
$summaryTools | Format-Table -AutoSize

Write-Host "Package Status:"
Write-Host "  Portable ZIP : $zipName ($zipSize MB)" -ForegroundColor Green
$statusColor = if ($installerStatus -eq "SUCCESS") { "Green" } else { "Yellow" }
Write-Host "  Installer EXE: $installerStatus" -ForegroundColor $statusColor
Write-Host "`nReady for distribution!`n" -ForegroundColor Cyan
