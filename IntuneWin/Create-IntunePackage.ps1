# Create-IntunePackage.ps1
# Creates .intunewin packages from app folders in apps/

param(
    [Parameter(Mandatory=$false)]
    [string]$AppName,

    [Parameter(Mandatory=$false)]
    [string]$OutputFolder = ".\output"
)

$ErrorActionPreference = "Stop"

Write-Host "`nIntuneWin Packager" -ForegroundColor Green
Write-Host "==================`n" -ForegroundColor Green

# --- Select app ---
$appsDir = Join-Path $PSScriptRoot "apps"
if (-not (Test-Path $appsDir)) {
    Write-Host "No 'apps' folder found. Run New-AppTemplate.ps1 first." -ForegroundColor Red
    exit 1
}

if (-not $AppName) {
    $availableApps = Get-ChildItem -Path $appsDir -Directory | Select-Object -ExpandProperty Name

    if ($availableApps.Count -eq 0) {
        Write-Host "No apps found in apps/ folder. Run New-AppTemplate.ps1 to create one." -ForegroundColor Red
        exit 1
    }

    Write-Host "Available apps:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $availableApps.Count; $i++) {
        Write-Host "  $($i + 1). $($availableApps[$i])" -ForegroundColor White
    }

    $selection = Read-Host "`nSelect app number (1-$($availableApps.Count))"
    $selectedIndex = [int]$selection - 1
    if ($selectedIndex -lt 0 -or $selectedIndex -ge $availableApps.Count) {
        Write-Host "Invalid selection." -ForegroundColor Red
        exit 1
    }
    $AppName = $availableApps[$selectedIndex]
}

$sourceFolder = Join-Path $appsDir $AppName
if (-not (Test-Path $sourceFolder)) {
    Write-Host "App folder not found: $sourceFolder" -ForegroundColor Red
    exit 1
}

# Verify install.cmd exists
$installCmd = Join-Path $sourceFolder "install.cmd"
if (-not (Test-Path $installCmd)) {
    Write-Host "install.cmd not found in $sourceFolder" -ForegroundColor Red
    Write-Host "Run New-AppTemplate.ps1 -AppName '$AppName' to generate template files." -ForegroundColor Yellow
    exit 1
}

# Verify at least one exe/msi exists
$installers = Get-ChildItem -Path $sourceFolder -Include "*.exe","*.msi" -File
if ($installers.Count -eq 0) {
    Write-Host "No .exe or .msi installer found in $sourceFolder" -ForegroundColor Red
    Write-Host "Place your installer in the apps/$AppName/ folder." -ForegroundColor Yellow
    exit 1
}

Write-Host "App:       $AppName" -ForegroundColor Cyan
Write-Host "Source:    $sourceFolder" -ForegroundColor Cyan
Write-Host "Installer: $($installers[0].Name)" -ForegroundColor Cyan

# --- Ensure Win32 Content Prep Tool is available ---
$toolsDir = Join-Path $PSScriptRoot "tools"
if (-not (Test-Path $toolsDir)) {
    New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null
}

$win32Tool = Join-Path $toolsDir "IntuneWinAppUtil.exe"
if (-not (Test-Path $win32Tool)) {
    Write-Host "`nWin32 Content Prep Tool not found. Downloading..." -ForegroundColor Yellow

    try {
        $downloadUrl = "https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool/archive/refs/heads/master.zip"
        $tempZip = Join-Path $toolsDir "temp.zip"
        $tempDir = Join-Path $toolsDir "temp"

        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip -UseBasicParsing
        Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force

        $exePath = Get-ChildItem -Path $tempDir -Recurse -Filter "IntuneWinAppUtil.exe" | Select-Object -First 1
        if ($exePath) {
            Copy-Item -Path $exePath.FullName -Destination $win32Tool
            Write-Host "Win32 Content Prep Tool downloaded successfully." -ForegroundColor Green
        } else {
            throw "IntuneWinAppUtil.exe not found in downloaded package."
        }

        Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "Auto-download failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Download manually from: https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool" -ForegroundColor Yellow
        Write-Host "Place IntuneWinAppUtil.exe in the tools/ folder." -ForegroundColor Yellow
        exit 1
    }
}

# --- Create package ---
if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}

Write-Host "`nCreating .intunewin package..." -ForegroundColor Yellow
& $win32Tool -c $sourceFolder -s "install.cmd" -o $OutputFolder -q

if ($LASTEXITCODE -ne 0) {
    Write-Host "Packaging failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit 1
}

# Rename generic output to app-specific name
$genericOutput = Join-Path $OutputFolder "install.intunewin"
$appOutput = Join-Path $OutputFolder "$AppName.intunewin"
if (Test-Path $genericOutput) {
    if (Test-Path $appOutput) { Remove-Item $appOutput -Force }
    Move-Item $genericOutput $appOutput
}

if (Test-Path $appOutput) {
    $sizeMB = [math]::Round((Get-Item $appOutput).Length / 1MB, 2)
    Write-Host "`nPackage created: $AppName.intunewin ($sizeMB MB)" -ForegroundColor Green
    Write-Host "Location: $appOutput" -ForegroundColor Cyan
    Write-Host "`nUpload this file to Microsoft Intune admin center." -ForegroundColor White
} else {
    Write-Host "Package file not found after creation." -ForegroundColor Red
    exit 1
}
