# Build script for NSIS installer
# Requires NSIS installed

param(
    [string]$NSISScript = ".\installer.nsi",
    [string]$OutputDir = "..\output"
)

$ErrorActionPreference = "Stop"

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "NSIS Installer Builder" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Check if NSIS is installed
$nsisPath = $null
$possiblePaths = @(
    "${env:ProgramFiles(x86)}\NSIS\makensis.exe",
    "${env:ProgramFiles}\NSIS\makensis.exe",
    "C:\Program Files (x86)\NSIS\makensis.exe",
    "C:\Program Files\NSIS\makensis.exe"
)

foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $nsisPath = $path
        break
    }
}

if (-not $nsisPath) {
    Write-Host "✗ NSIS not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install NSIS from: https://nsis.sourceforge.io/" -ForegroundColor Yellow
    Write-Host "Or add makensis.exe to your PATH" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Found NSIS at: $nsisPath" -ForegroundColor Green

# Create output directory
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# Build the installer
Write-Host ""
Write-Host "Building installer..." -ForegroundColor Yellow

& $nsisPath $NSISScript

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Build failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "✓ Build successful" -ForegroundColor Green

# Find the output file
$exeFile = Get-ChildItem -Path $OutputDir -Filter "*.exe" | Select-Object -First 1

if ($exeFile) {
    Write-Host ""
    Write-Host "==================================" -ForegroundColor Green
    Write-Host "✓ Installer Build Complete!" -ForegroundColor Green
    Write-Host "==================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Output: $($exeFile.FullName)" -ForegroundColor Cyan
    Write-Host "File Size: $([math]::Round($exeFile.Length / 1MB, 2)) MB" -ForegroundColor Gray
    Write-Host "Created: $($exeFile.CreationTime)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Test the installer: Run $($exeFile.Name)" -ForegroundColor White
    Write-Host "2. Silent install test: $($exeFile.Name) /S" -ForegroundColor White
    Write-Host "3. Package for Intune with IntuneWinAppUtil" -ForegroundColor White
    Write-Host "4. Upload to Intune portal" -ForegroundColor White
}
else {
    Write-Host "✗ Output file not found!" -ForegroundColor Red
    exit 1
}
