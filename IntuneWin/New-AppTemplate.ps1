# New-AppTemplate.ps1
# Creates a new app folder with template install/uninstall/detect scripts

param(
    [Parameter(Mandatory=$true)]
    [string]$AppName
)

$ErrorActionPreference = "Stop"

$appDir = Join-Path $PSScriptRoot "apps" $AppName

if (Test-Path $appDir) {
    Write-Host "App folder already exists: apps/$AppName/" -ForegroundColor Yellow
    Write-Host "Edit the existing files or delete the folder to start over." -ForegroundColor Yellow
    exit 0
}

New-Item -ItemType Directory -Path $appDir -Force | Out-Null

# --- install.cmd ---
@"
@echo off
REM Silent install for $AppName
REM Replace INSTALLER.exe with your actual installer filename
REM Adjust the silent flags for your specific installer

INSTALLER.exe /S /v/qn
exit /b %errorlevel%
"@ | Set-Content -Path (Join-Path $appDir "install.cmd") -Encoding ASCII

# --- uninstall.cmd ---
@"
@echo off
REM Silent uninstall for $AppName
REM Option 1: Use the installer's uninstall flag
REM INSTALLER.exe /uninstall /S

REM Option 2: Use the uninstall string from registry
REM Find it at: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{PRODUCT-GUID}
REM msiexec /x {PRODUCT-GUID} /qn

echo Uninstall not configured. Edit uninstall.cmd for your app.
exit /b 1
"@ | Set-Content -Path (Join-Path $appDir "uninstall.cmd") -Encoding ASCII

# --- detect.ps1 ---
@"
# Detection script for $AppName
# Intune runs this to check if the app is already installed.
# Exit 0 = detected (installed), Exit 1 = not detected.

# Option 1: Check if a file exists
# if (Test-Path "C:\Program Files\$AppName\app.exe") { exit 0 }

# Option 2: Check registry
# `$reg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" |
#     Where-Object { `$_.DisplayName -like "*$AppName*" }
# if (`$reg) { exit 0 }

# Option 3: Check installed programs via WMI (slower)
# `$app = Get-CimInstance Win32_Product | Where-Object { `$_.Name -like "*$AppName*" }
# if (`$app) { exit 0 }

Write-Host "Not detected"
exit 1
"@ | Set-Content -Path (Join-Path $appDir "detect.ps1") -Encoding UTF8

Write-Host "Created app template: apps/$AppName/" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Place your .exe installer in apps/$AppName/" -ForegroundColor White
Write-Host "  2. Edit apps/$AppName/install.cmd   - set your installer filename and silent flags" -ForegroundColor White
Write-Host "  3. Edit apps/$AppName/uninstall.cmd  - configure uninstall command" -ForegroundColor White
Write-Host "  4. Edit apps/$AppName/detect.ps1     - configure detection logic" -ForegroundColor White
Write-Host "  5. Run: .\Create-IntunePackage.ps1 -AppName '$AppName'" -ForegroundColor White
