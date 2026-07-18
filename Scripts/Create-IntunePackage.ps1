# Create-IntunePackage.ps1
# Builds a .intunewin package for an app under Apps\<AppName>\Source, verifies it,
# saves it (versioned) into Apps\<AppName>\Output, and cleans the large installer
# binary out of Source once the build is confirmed good.
#
# Usage:
#   .\Scripts\Create-IntunePackage.ps1
#   .\Scripts\Create-IntunePackage.ps1 -AppName Python314
#   .\Scripts\Create-IntunePackage.ps1 -AppName Python314 -Version 3.14.1 -SetupFile install.cmd
#   .\Scripts\Create-IntunePackage.ps1 -AppName Python314 -SkipSourceCleanup

param(
    [Parameter(Mandatory=$false)]
    [string]$AppName,

    [Parameter(Mandatory=$false)]
    [string]$Version,

    [Parameter(Mandatory=$false)]
    [string]$SetupFile = "install.cmd",

    [Parameter(Mandatory=$false)]
    [int]$LargeFileThresholdMB = 5,

    [switch]$SkipSourceCleanup
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }
$appsRoot = Join-Path $root "Apps"
$toolPath = Join-Path $root "Tools\IntuneWinAppUtil.exe"

Write-Host "Creating Intune Win32 Package" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

# 1. Pick the app --------------------------------------------------------
if (-not $AppName) {
    $availableApps = Get-ChildItem -Path $appsRoot -Directory | Select-Object -ExpandProperty Name
    if ($availableApps.Count -eq 0) {
        Write-Host "No apps found under Apps\!" -ForegroundColor Red
        exit 1
    }
    Write-Host "Available apps:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $availableApps.Count; $i++) {
        Write-Host "  $($i + 1). $($availableApps[$i])" -ForegroundColor Gray
    }
    $selection = Read-Host "`nSelect app number (1-$($availableApps.Count))"
    try {
        $selectedIndex = [int]$selection - 1
        if ($selectedIndex -ge 0 -and $selectedIndex -lt $availableApps.Count) {
            $AppName = $availableApps[$selectedIndex]
        } else {
            throw "Invalid selection"
        }
    } catch {
        Write-Host "Invalid selection. Exiting." -ForegroundColor Red
        exit 1
    }
}

$sourceFolder = Join-Path $appsRoot "$AppName\Source"
$outputFolder = Join-Path $appsRoot "$AppName\Output"

if (-not (Test-Path $sourceFolder)) {
    Write-Host "Source folder not found: $sourceFolder" -ForegroundColor Red
    Write-Host "Drop the installer + install.cmd/uninstall.cmd/detect.ps1 there first." -ForegroundColor Yellow
    exit 1
}
New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null

Write-Host "Selected app: $AppName" -ForegroundColor Green
Write-Host "Source: $sourceFolder" -ForegroundColor Cyan
Write-Host "Output: $outputFolder" -ForegroundColor Cyan

# 2. Sanity checks before building ---------------------------------------
if (-not (Test-Path $toolPath)) {
    Write-Host "IntuneWinAppUtil.exe not found at $toolPath" -ForegroundColor Red
    Write-Host "Download it from https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool and place it in Tools\." -ForegroundColor Yellow
    exit 1
}

$setupPath = Join-Path $sourceFolder $SetupFile
if (-not (Test-Path $setupPath)) {
    Write-Host "Setup file '$SetupFile' not found in $sourceFolder" -ForegroundColor Red
    exit 1
}

# 3. Build the package -----------------------------------------------------
if (-not $Version) { $Version = Get-Date -Format "yyyy-MM-dd" }
$packageName = "${AppName}_${Version}.intunewin"
$finalOutputPath = Join-Path $outputFolder $packageName

Write-Host "`nBuilding package..." -ForegroundColor Yellow
& $toolPath -c $sourceFolder -s $SetupFile -o $outputFolder -q

if ($LASTEXITCODE -ne 0) {
    Write-Host "IntuneWinAppUtil failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit 1
}

$genericPath = Join-Path $outputFolder ([System.IO.Path]::GetFileNameWithoutExtension($SetupFile) + ".intunewin")
if (-not (Test-Path $genericPath)) {
    Write-Host "Expected output '$genericPath' was not created." -ForegroundColor Red
    exit 1
}
if (Test-Path $finalOutputPath) {
    Write-Host "A package named '$packageName' already exists. Bumping with a time suffix." -ForegroundColor Yellow
    $packageName = "${AppName}_${Version}_$(Get-Date -Format 'HHmmss').intunewin"
    $finalOutputPath = Join-Path $outputFolder $packageName
}
Move-Item $genericPath $finalOutputPath

# 4. Verify the build before trusting it -----------------------------------
Write-Host "`nVerifying package..." -ForegroundColor Yellow
$fileInfo = Get-Item $finalOutputPath
$fs = [System.IO.File]::OpenRead($finalOutputPath)
$header = New-Object byte[] 2
$fs.Read($header, 0, 2) | Out-Null
$fs.Close()
$isZip = ($header[0] -eq 0x50 -and $header[1] -eq 0x4B)   # "PK" zip header
$sizeOk = $fileInfo.Length -gt 100KB

if (-not $isZip -or -not $sizeOk) {
    Write-Host "VERIFICATION FAILED: package does not look like a valid .intunewin (zip header: $isZip, size: $($fileInfo.Length) bytes)" -ForegroundColor Red
    Write-Host "Not touching Source\ files. Investigate before retrying." -ForegroundColor Red
    exit 1
}

$sizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
Write-Host "Verified: $packageName ($sizeMB MB, valid zip header)" -ForegroundColor Green

# 4b. Generate an Intune config guide if this app doesn't have one yet --------
$guidePath = Join-Path $sourceFolder "intune-config-template.md"
if (-not (Test-Path $guidePath)) {
    $uninstallCmd = if (Test-Path (Join-Path $sourceFolder "uninstall.cmd")) { "uninstall.cmd" } else { "(none found - EDIT ME)" }
    $hasDetectPs1 = Test-Path (Join-Path $sourceFolder "detect.ps1")
    $detectionSection = if ($hasDetectPs1) {
@"
### Detection Rule (PowerShell)
- **Rule type**: Use a custom detection script
- **Script file**: Upload `detect.ps1`
- **Run script as 32-bit process on 64-bit clients**: No
- **Enforce script signature check**: No
"@
    } else {
@"
### Detection Rule - EDIT ME
No `detect.ps1` was found for this app. Configure a detection rule manually
(registry, file/folder existence, or MSI product code) before deploying.
"@
    }

@"
# Intune Win32 App Configuration Template

Auto-generated stub for **$AppName** - fill in the "EDIT ME" fields before
deploying. Generated after the first verified build on $(Get-Date -Format 'yyyy-MM-dd').

## Basic Information

| Field | Value |
|-------|-------|
| **Name** | $AppName (EDIT ME - use a human-readable display name) |
| **Description** | EDIT ME |
| **Publisher** | EDIT ME |
| **Information URL** | EDIT ME |
| **Category** | EDIT ME |

## Program

| Field | Value |
|-------|-------|
| **Install command** | ``$SetupFile`` |
| **Uninstall command** | ``$uninstallCmd`` |
| **Install behavior** | System |
| **Device restart behavior** | No specific action |
| **Return codes** | Default (0=Success, 1707=Success, 3010=Soft reboot, 1641=Hard reboot, 1618=Retry) |

## Requirements

| Field | Value |
|-------|-------|
| **Operating system architecture** | EDIT ME (likely x64) |
| **Minimum operating system** | EDIT ME (e.g. Windows 10 1809) |
| **Disk space required (MB)** | EDIT ME |

## Detection rules

$detectionSection

## Package
- **File**: ``Apps\$AppName\Output\$packageName``
- **Size**: $sizeMB MB
- **Verified**: valid .intunewin (zip) header, built $(Get-Date -Format 'yyyy-MM-dd')
"@ | Set-Content -Path $guidePath -Encoding UTF8

    Write-Host "`nGenerated intune-config-template.md stub - fill in the EDIT ME fields before deploying." -ForegroundColor Yellow
}

# 5. Clean the large installer(s) out of Source now that they're safely
#    inside the verified .intunewin ----------------------------------------
if (-not $SkipSourceCleanup) {
    $thresholdBytes = $LargeFileThresholdMB * 1MB
    $bigFiles = Get-ChildItem -Path $sourceFolder -Recurse -File |
        Where-Object { $_.Length -gt $thresholdBytes -and $_.Name -ne "desktop.ini" }

    if ($bigFiles) {
        Write-Host "`nCleaning up Source (installer is safely archived inside the .intunewin):" -ForegroundColor Yellow
        foreach ($f in $bigFiles) {
            Write-Host "  Removing $($f.FullName.Replace($sourceFolder, '.'))" -ForegroundColor Gray
            Remove-Item $f.FullName -Force
        }
    } else {
        Write-Host "`nNo large files in Source to clean up." -ForegroundColor Gray
    }
} else {
    Write-Host "`nSkipping source cleanup (-SkipSourceCleanup)." -ForegroundColor Gray
}

# 6. Summary -----------------------------------------------------------------
Write-Host "`nAll builds for ${AppName}:" -ForegroundColor Green
Get-ChildItem -Path $outputFolder -Filter "*.intunewin" | ForEach-Object {
    $mb = [math]::Round($_.Length / 1MB, 2)
    Write-Host "  - $($_.Name) ($mb MB)" -ForegroundColor Cyan
}

Write-Host "`nReady to upload to Microsoft Intune: $finalOutputPath" -ForegroundColor Green
