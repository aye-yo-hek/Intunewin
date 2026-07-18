# Process-Inbox.ps1
# Drop ANY installer (.exe/.msi) into C:\IntuneWin\Inbox\ and run this script.
# For each file it finds, this script will:
#   1. Work out which app it belongs to (matching an existing Apps\ folder if
#      one looks related, otherwise creating a new one)
#   2. Create Apps\<AppName>\Source and \Output if they don't exist
#   3. Move the installer into Apps\<AppName>\Source
#   4. Scaffold install.cmd / uninstall.cmd / detect.ps1 if the app is brand new
#      (real ProductCode-based scripts for .msi; a best-effort, clearly-flagged
#      template for .exe, since silent switches can't be known for certain)
#   5. Build + verify + version the .intunewin via Create-IntunePackage.ps1
#   6. Clean the large installer back out of Source once verified
#
# The Inbox file itself is always moved out as step 3 — nothing lingers there.
#
# Usage:
#   .\Scripts\Process-Inbox.ps1
#   .\Scripts\Process-Inbox.ps1 -AppName Slack        # force the app name for a single file (only valid with one file in Inbox)

param(
    [string]$AppName
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }
$inbox = Join-Path $root "Inbox"
$appsRoot = Join-Path $root "Apps"

New-Item -ItemType Directory -Path $inbox -Force | Out-Null

$files = Get-ChildItem -Path $inbox -File | Where-Object { $_.Name -ne "desktop.ini" }
if ($files.Count -eq 0) {
    Write-Host "Inbox is empty. Drop an installer into $inbox and re-run." -ForegroundColor Yellow
    exit 0
}
if ($AppName -and $files.Count -gt 1) {
    Write-Host "-AppName can only be used when Inbox has exactly one file." -ForegroundColor Red
    exit 1
}

function Get-CandidateAppName {
    param([string]$FileBaseName)
    $noise = @('setup','installer','install','full','offline','online','enterprise',
               'universal','x64','x86','amd64','win64','win32','en','en-us','release','final')
    $parts = $FileBaseName -split '[-_\s\.]+' | Where-Object {
        $_ -and ($_.ToLower() -notin $noise) -and ($_ -notmatch '^\d+(\.\d+)*$')
    }
    if (-not $parts) { $parts = @($FileBaseName) }
    ($parts -join '')
}

function Resolve-AppFolder {
    param([string]$Candidate)
    $existing = Get-ChildItem -Path $appsRoot -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    $normalize = { param($s) ($s -replace '[^a-zA-Z0-9]', '').ToLower() }
    $c = & $normalize $Candidate

    # Direct substring match either direction (e.g. "Zoom" <-> "ZoomInstallerFull")
    foreach ($e in $existing) {
        $en = & $normalize $e
        if ($en -like "*$c*" -or $c -like "*$en*") { return $e }
    }

    # Shared-prefix fallback (e.g. "VSCodeSetup" candidate matching existing "VSCodeWindows")
    $minPrefix = 5
    $best = $null; $bestLen = 0
    foreach ($e in $existing) {
        $en = & $normalize $e
        $max = [Math]::Min($c.Length, $en.Length)
        $len = 0
        for ($i = 0; $i -lt $max; $i++) { if ($c[$i] -eq $en[$i]) { $len++ } else { break } }
        if ($len -ge $minPrefix -and $len -gt $bestLen) { $best = $e; $bestLen = $len }
    }
    if ($best) { return $best }

    return $Candidate
}

function Get-MsiInfo {
    param([string]$MsiPath)
    $installer = New-Object -ComObject WindowsInstaller.Installer
    $db = $installer.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $installer, @($MsiPath, 0))
    $props = @{}
    foreach ($prop in @("ProductCode", "ProductName", "ProductVersion")) {
        try {
            $view = $db.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $db,
                @("SELECT ``Value`` FROM ``Property`` WHERE ``Property``='$prop'"))
            $view.GetType().InvokeMember("Execute", "InvokeMethod", $null, $view, $null) | Out-Null
            $record = $view.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $view, $null)
            if ($record) {
                $props[$prop] = $record.GetType().InvokeMember("StringData", "GetProperty", $null, $record, 1)
            }
        } catch { $props[$prop] = $null }
    }
    return $props
}

function New-MsiScaffold {
    param([string]$SourceFolder, [string]$InstallerFileName, [hashtable]$MsiInfo)

    $productCode = $MsiInfo.ProductCode
    $productName = $MsiInfo.ProductName

    @"
@echo off
msiexec /i "%~dp0$InstallerFileName" /qn /norestart
"@ | Set-Content -Path (Join-Path $SourceFolder "install.cmd") -Encoding ASCII

    @"
@echo off
msiexec /x "$productCode" /qn /norestart
"@ | Set-Content -Path (Join-Path $SourceFolder "uninstall.cmd") -Encoding ASCII

    @"
# Auto-generated detection script - checks for the MSI's real ProductCode in the
# uninstall registry keys (64-bit and 32-bit views). ProductName: $productName
`$paths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$productCode",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$productCode"
)
foreach (`$p in `$paths) {
    if (Test-Path `$p) { exit 0 }
}
exit 1
"@ | Set-Content -Path (Join-Path $SourceFolder "detect.ps1") -Encoding UTF8

    $productVersion = $MsiInfo.ProductVersion
    @"
# Intune Win32 App Configuration Template

Auto-generated from the MSI's own metadata - fill in the "EDIT ME" fields
before deploying.

## Basic Information

| Field | Value |
|-------|-------|
| **Name** | $productName |
| **Description** | EDIT ME |
| **Publisher** | EDIT ME |
| **Category** | EDIT ME |

## Program

| Field | Value |
|-------|-------|
| **Install command** | ``install.cmd`` -> ``msiexec /i "$InstallerFileName" /qn /norestart`` |
| **Uninstall command** | ``uninstall.cmd`` -> ``msiexec /x "$productCode" /qn /norestart`` |
| **Install behavior** | System |
| **Return codes** | Default (0=Success, 1707=Success, 3010=Soft reboot, 1641=Hard reboot, 1618=Retry) |

## Requirements

| Field | Value |
|-------|-------|
| **Operating system architecture** | EDIT ME (likely x64) |
| **Minimum operating system** | EDIT ME (e.g. Windows 10 1809) |
| **Disk space required (MB)** | EDIT ME |

## Detection rules

### Detection Rule (PowerShell - matches detect.ps1)
- **Rule type**: Use a custom detection script
- **Script file**: Upload ``detect.ps1``
- Checks for ProductCode ``$productCode`` under the Uninstall registry keys.

### Alternative Detection Rule (MSI Product Code)
- **Rule type**: MSI
- **MSI product code**: ``$productCode``

## MSI metadata (read directly from the installer)
- **ProductName**: $productName
- **ProductCode**: $productCode
- **ProductVersion**: $productVersion
"@ | Set-Content -Path (Join-Path $SourceFolder "intune-config-template.md") -Encoding UTF8

    Write-Host "  Generated install.cmd / uninstall.cmd / detect.ps1 / intune-config-template.md from the MSI's real ProductCode ($productCode)." -ForegroundColor Green
}

function New-ExeScaffold {
    param([string]$SourceFolder, [string]$InstallerFileName, [string]$AppName)

    # Best-effort sniff of the installer type from strings embedded in the binary.
    # This is a guess, not a guarantee - flagged clearly below and in a review file.
    $installerPath = Join-Path $SourceFolder $InstallerFileName
    $signature = "Unknown"
    $silentSwitch = "/S"
    try {
        $hit = Select-String -Path $installerPath -Pattern "Inno Setup", "Nullsoft", "InstallShield", "WiX Toolset" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hit) {
            switch -Wildcard ($hit.Line) {
                "*Inno Setup*"     { $signature = "Inno Setup"; $silentSwitch = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" }
                "*Nullsoft*"       { $signature = "NSIS (Nullsoft)"; $silentSwitch = "/S" }
                "*InstallShield*"  { $signature = "InstallShield"; $silentSwitch = '/s /v"/qn"' }
                "*WiX Toolset*"    { $signature = "WiX-wrapped"; $silentSwitch = "/quiet /norestart" }
            }
        }
    } catch { }

    @"
@echo off
REM UNVERIFIED - installer type guessed as: $signature
REM Confirm the correct silent switch for this specific installer before deploying.
"%~dp0$InstallerFileName" $silentSwitch
"@ | Set-Content -Path (Join-Path $SourceFolder "install.cmd") -Encoding ASCII

    @"
@echo off
REM UNVERIFIED - fill in this app's real uninstall command (check Add/Remove Programs
REM for the quiet-uninstall string, or the vendor's docs).
echo Uninstall command not yet configured for $AppName
exit /b 1
"@ | Set-Content -Path (Join-Path $SourceFolder "uninstall.cmd") -Encoding ASCII

    @"
# UNVERIFIED placeholder detection - loosely matches on DisplayName under Uninstall
# registry keys. Confirm this actually matches the installed app, or replace with a
# file-existence / version check instead.
`$displayNameLike = "*$AppName*"
`$paths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
foreach (`$p in `$paths) {
    `$found = Get-ItemProperty `$p -ErrorAction SilentlyContinue | Where-Object { `$_.DisplayName -like `$displayNameLike }
    if (`$found) { exit 0 }
}
exit 1
"@ | Set-Content -Path (Join-Path $SourceFolder "detect.ps1") -Encoding UTF8

    @"
# NEEDS REVIEW: $InstallerFileName

This app's install.cmd / uninstall.cmd / detect.ps1 were auto-generated by
Process-Inbox.ps1 and are UNVERIFIED:

- Installer type guessed as: $signature (silent switch: $silentSwitch)
- uninstall.cmd is a stub - it does not actually uninstall anything yet
- detect.ps1 does a loose DisplayName match - confirm it actually matches
  (or replace with a registry/file-version check)

Test all three before deploying this package to real devices, then delete
this file.
"@ | Set-Content -Path (Join-Path $SourceFolder "_NEEDS-REVIEW.md") -Encoding UTF8

    Write-Host "  Generated an UNVERIFIED install/uninstall/detect scaffold (guessed type: $signature)." -ForegroundColor Yellow
    Write-Host "  See Source\_NEEDS-REVIEW.md - review before deploying to real devices." -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
$processed = @()

foreach ($file in $files) {
    Write-Host "`n=== Processing: $($file.Name) ===" -ForegroundColor Cyan

    $ext = $file.Extension.ToLower()
    if ($ext -notin @(".exe", ".msi")) {
        Write-Host "  Skipping - unsupported file type '$ext'. Only .exe and .msi are auto-processed." -ForegroundColor Red
        continue
    }

    $thisAppName = if ($AppName) { $AppName } else {
        $candidate = Get-CandidateAppName -FileBaseName $file.BaseName
        Resolve-AppFolder -Candidate $candidate
    }

    $sourceFolder = Join-Path $appsRoot "$thisAppName\Source"
    $outputFolder = Join-Path $appsRoot "$thisAppName\Output"
    $isNewApp = -not (Test-Path $sourceFolder)

    New-Item -ItemType Directory -Path $sourceFolder -Force | Out-Null
    New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null

    if ($isNewApp) {
        Write-Host "  New app - created Apps\$thisAppName\" -ForegroundColor Green
    } else {
        Write-Host "  Matched existing app: Apps\$thisAppName\" -ForegroundColor Green
    }

    $destInstaller = Join-Path $sourceFolder $file.Name
    Move-Item -Path $file.FullName -Destination $destInstaller -Force
    Write-Host "  Moved into Source\ (removed from Inbox)." -ForegroundColor Gray

    $hasScripts = Test-Path (Join-Path $sourceFolder "install.cmd")
    if (-not $hasScripts) {
        if ($ext -eq ".msi") {
            $msiInfo = Get-MsiInfo -MsiPath $destInstaller
            New-MsiScaffold -SourceFolder $sourceFolder -InstallerFileName $file.Name -MsiInfo $msiInfo
        } else {
            New-ExeScaffold -SourceFolder $sourceFolder -InstallerFileName $file.Name -AppName $thisAppName
        }
    } else {
        Write-Host "  Existing install.cmd/uninstall.cmd/detect.ps1 left as-is (version update)." -ForegroundColor Gray
    }

    & (Join-Path $PSScriptRoot "Create-IntunePackage.ps1") -AppName $thisAppName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Build failed for $thisAppName - installer is still in Source\ for you to inspect." -ForegroundColor Red
    }

    $processed += $thisAppName
}

Write-Host "`n=== Done ===" -ForegroundColor Green
Write-Host "Processed apps: $($processed -join ', ')" -ForegroundColor Cyan
Write-Host "Check each Apps\<AppName>\Source\_NEEDS-REVIEW.md if present before deploying." -ForegroundColor Yellow
