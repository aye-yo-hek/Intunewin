# Troubleshooting Script for Error 0x80070643
# Run this on the TARGET machine where installation failed

Write-Host "`n🔍 Adobe Installation Error 0x80070643 Diagnostics" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

# Check if script is running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "⚠ WARNING: Not running as Administrator" -ForegroundColor Yellow
    Write-Host "Some checks may fail without admin rights`n" -ForegroundColor Yellow
}

# 1. Check for installation logs
Write-Host "[1] Checking for installation logs..." -ForegroundColor Yellow

$logLocations = @(
    "$env:TEMP\Acrobat.msi.install.log",
    "$env:TEMP\Acrobat.msi.install.log.patch",
    "C:\Windows\Temp\Acrobat.msi.install.log"
)

$foundLog = $false
foreach ($log in $logLocations) {
    if (Test-Path $log) {
        Write-Host "  ✓ Found log: $log" -ForegroundColor Green
        $foundLog = $true
        
        # Extract errors from log
        Write-Host "`n  Last 20 error lines:" -ForegroundColor Cyan
        $errors = Select-String -Path $log -Pattern "error|failed|return value 3" -CaseSensitive:$false | Select-Object -Last 20
        if ($errors) {
            $errors | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
        } else {
            Write-Host "    No errors found in log" -ForegroundColor Yellow
        }
    }
}

if (-not $foundLog) {
    Write-Host "  ✗ No installation logs found" -ForegroundColor Red
}

# 2. Check for existing Adobe installations
Write-Host "`n[2] Checking for existing Adobe installations..." -ForegroundColor Yellow

$adobeProducts = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*Adobe*Acrobat*" }
if ($adobeProducts) {
    Write-Host "  ⚠ Found existing Adobe installations:" -ForegroundColor Yellow
    $adobeProducts | ForEach-Object {
        Write-Host "    - $($_.Name) (Version: $($_.Version))" -ForegroundColor Cyan
        Write-Host "      Product Code: $($_.IdentifyingNumber)" -ForegroundColor Gray
    }
} else {
    Write-Host "  ✓ No existing Adobe installations found" -ForegroundColor Green
}

# 3. Check disk space
Write-Host "`n[3] Checking disk space..." -ForegroundColor Yellow

$drive = Get-PSDrive -Name C
$freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
if ($freeSpaceGB -lt 10) {
    Write-Host "  ✗ Low disk space: $freeSpaceGB GB available (need at least 10 GB)" -ForegroundColor Red
} else {
    Write-Host "  ✓ Sufficient disk space: $freeSpaceGB GB available" -ForegroundColor Green
}

# 4. Check Windows Installer service
Write-Host "`n[4] Checking Windows Installer service..." -ForegroundColor Yellow

$msiService = Get-Service -Name msiserver -ErrorAction SilentlyContinue
if ($msiService) {
    Write-Host "  ✓ Service status: $($msiService.Status)" -ForegroundColor Green
    if ($msiService.Status -ne 'Running') {
        Write-Host "  ⚠ Service not running - attempting to start..." -ForegroundColor Yellow
        Start-Service -Name msiserver
    }
} else {
    Write-Host "  ✗ Windows Installer service not found" -ForegroundColor Red
}

# 5. Check for pending reboot
Write-Host "`n[5] Checking for pending reboot..." -ForegroundColor Yellow

$rebootPending = $false
if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") {
    Write-Host "  ⚠ Component Based Servicing reboot pending" -ForegroundColor Yellow
    $rebootPending = $true
}
if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") {
    Write-Host "  ⚠ Windows Update reboot required" -ForegroundColor Yellow
    $rebootPending = $true
}
if (-not $rebootPending) {
    Write-Host "  ✓ No pending reboot detected" -ForegroundColor Green
}

# 6. Check Event Viewer for MSI errors
Write-Host "`n[6] Checking Event Viewer for recent MSI errors..." -ForegroundColor Yellow

$msiErrors = Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='MsiInstaller'; Level=2} -MaxEvents 10 -ErrorAction SilentlyContinue
if ($msiErrors) {
    Write-Host "  ⚠ Found recent MSI errors:" -ForegroundColor Yellow
    $msiErrors | ForEach-Object {
        Write-Host "    - $($_.TimeCreated): $($_.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "  ✓ No recent MSI errors in Event Viewer" -ForegroundColor Green
}

# 7. Check Intune Management Extension logs
Write-Host "`n[7] Checking Intune Management Extension logs..." -ForegroundColor Yellow

$intuneLogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log"
if (Test-Path $intuneLogPath) {
    Write-Host "  ✓ Found Intune log: $intuneLogPath" -ForegroundColor Green
    
    # Extract recent Adobe-related entries
    $intuneErrors = Select-String -Path $intuneLogPath -Pattern "Acrobat|0x80070643|install-enhanced" -CaseSensitive:$false | Select-Object -Last 15
    if ($intuneErrors) {
        Write-Host "`n  Recent Intune log entries:" -ForegroundColor Cyan
        $intuneErrors | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    }
} else {
    Write-Host "  ✗ Intune log not found" -ForegroundColor Red
}

# Summary and recommendations
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "📋 RECOMMENDATIONS:" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

Write-Host "1. Check the installation log files above for specific error messages" -ForegroundColor White
Write-Host "2. If existing Adobe products found, uninstall them first" -ForegroundColor White
Write-Host "3. If pending reboot detected, restart the machine" -ForegroundColor White
Write-Host "4. Ensure sufficient disk space (at least 10 GB free)" -ForegroundColor White
Write-Host "5. Check if antivirus is blocking the installation" -ForegroundColor White
Write-Host "6. Verify CAB files are being extracted properly`n" -ForegroundColor White

Write-Host "Common causes of 0x80070643:" -ForegroundColor Yellow
Write-Host "  - Missing CAB files during installation" -ForegroundColor Gray
Write-Host "  - Conflicting Adobe installation" -ForegroundColor Gray
Write-Host "  - Corrupted Windows Installer database" -ForegroundColor Gray
Write-Host "  - Insufficient permissions" -ForegroundColor Gray
Write-Host "  - Antivirus interference`n" -ForegroundColor Gray
