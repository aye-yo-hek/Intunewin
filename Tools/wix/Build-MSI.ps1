# Build script for WiX installer (WiX Toolset v4 CLI - `wix build`)
# Requires the WiX v4 dotnet tool: dotnet tool install --global wix

param(
    [string]$WxsFile = ".\Product.wxs",
    [string]$OutputMsi = ".\output\Product.msi"
)

$ErrorActionPreference = "Stop"

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "WiX MSI Builder (v4)" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Locate the wix v4 CLI - either on PATH or as a per-user dotnet global tool
$wixExe = $null
if (Get-Command wix -ErrorAction SilentlyContinue) {
    $wixExe = "wix"
} else {
    $candidate = Join-Path $env:USERPROFILE ".dotnet\tools\wix.exe"
    if (Test-Path $candidate) { $wixExe = $candidate }
}

if (-not $wixExe) {
    Write-Host "WiX Toolset v4 CLI not found!" -ForegroundColor Red
    Write-Host "Install it with: dotnet tool install --global wix" -ForegroundColor Yellow
    exit 1
}

Write-Host "Using WiX CLI: $wixExe" -ForegroundColor Green
& $wixExe --version | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }

$outputDir = Split-Path -Parent $OutputMsi
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

Write-Host "`nBuilding $WxsFile -> $OutputMsi ..." -ForegroundColor Yellow
& $wixExe build $WxsFile -o $OutputMsi

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed (exit $LASTEXITCODE)." -ForegroundColor Red
    exit $LASTEXITCODE
}

if (-not (Test-Path $OutputMsi)) {
    Write-Host "wix reported success but $OutputMsi was not created." -ForegroundColor Red
    exit 1
}

$fileInfo = Get-Item $OutputMsi
Write-Host "`nBuild complete: $OutputMsi ($([math]::Round($fileInfo.Length / 1KB, 1)) KB)" -ForegroundColor Green

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Sanity-check the MSI's ProductCode/Registry contents before trusting it." -ForegroundColor White
Write-Host "2. Drop it in Inbox\ (or Apps\<AppName>\Source\) and run Process-Inbox.ps1 / Create-IntunePackage.ps1 to get a verified .intunewin." -ForegroundColor White
