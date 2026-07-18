# Run this script on the TARGET MACHINE where installation failed
# Must run as Administrator

Write-Host "`n🔍 ADOBE INSTALLATION FAILURE DIAGNOSTICS (0x80070643)" -ForegroundColor Red
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

# Check admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ ERROR: Must run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'`n" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "✅ Running as Administrator`n" -ForegroundColor Green

# 1. Find and analyze the MSI installation log
Write-Host "[1/7] Searching for Adobe installation logs..." -ForegroundColor Cyan

$logPaths = @(
    "$env:TEMP\Acrobat.msi.install.log",
    "$env:WINDIR\Temp\Acrobat.msi.install.log",
    "$env:SystemRoot\Temp\Acrobat.msi.install.log"
)

$logFound = $false
foreach ($logPath in $logPaths) {
    if (Test-Path $logPath) {
        Write-Host "  ✓ Found: $logPath" -ForegroundColor Green
        $logFound = $true
        
        # Check for CAB file errors
        Write-Host "`n  🔍 Checking for CAB file errors..." -ForegroundColor Yellow
        $cabErrors = Select-String -Path $logPath -Pattern "cab|1311|1335" -Context 1,1 | Select-Object -Last 10
        if ($cabErrors) {
            Write-Host "  ⚠️ CAB-related errors found:" -ForegroundColor Red
            $cabErrors | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
        } else {
            Write-Host "  ✓ No CAB file errors found" -ForegroundColor Green
        }
        
        # Check for the actual error
        Write-Host "`n  🔍 Finding the failure reason..." -ForegroundColor Yellow
        $errors = Select-String -Path $logPath -Pattern "return value 3|error|failed" -CaseSensitive:$false | Select-Object -Last 15
        if ($errors) {
            Write-Host "  ⚠️ Error messages:" -ForegroundColor Red
            $errors | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
        }
        
        break
    }
}

if (-not $logFound) {
    Write-Host "  ❌ No installation logs found - installation may not have started" -ForegroundColor Red
}

# 2. Check for existing Adobe installations
Write-Host "`n[2/7] Checking for conflicting Adobe installations..." -ForegroundColor Cyan

$adobeInRegistry = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | 
    Where-Object { $_.DisplayName -like "*Adobe*Acrobat*" }

if ($adobeInRegistry) {
    Write-Host "  ⚠️ Found existing Adobe installations:" -ForegroundColor Yellow
    $adobeInRegistry | ForEach-Object {
        Write-Host "    - $($_.DisplayName)" -ForegroundColor Cyan
        Write-Host "      Version: $($_.DisplayVersion)" -ForegroundColor Gray
        Write-Host "      Uninstall: $($_.UninstallString)" -ForegroundColor Gray
    }
    Write-Host "`n  💡 RECOMMENDATION: Uninstall existing Adobe before deploying" -ForegroundColor Yellow
} else {
    Write-Host "  ✓ No conflicting Adobe installations found" -ForegroundColor Green
}

# 3. Check disk space
Write-Host "`n[3/7] Checking disk space..." -ForegroundColor Cyan

$drive = Get-PSDrive C
$freeGB = [math]::Round($drive.Free / 1GB, 2)
if ($freeGB -lt 10) {
    Write-Host "  ❌ INSUFFICIENT DISK SPACE: $freeGB GB (need 10+ GB)" -ForegroundColor Red
} else {
    Write-Host "  ✓ Sufficient space: $freeGB GB available" -ForegroundColor Green
}

# 4. Check Windows Installer service
Write-Host "`n[4/7] Checking Windows Installer service..." -ForegroundColor Cyan

$msiService = Get-Service msiserver -ErrorAction SilentlyContinue
if ($msiService) {
    if ($msiService.Status -eq 'Running') {
        Write-Host "  ✓ Windows Installer service running" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ Windows Installer service not running: $($msiService.Status)" -ForegroundColor Yellow
        Write-Host "    Attempting to start..." -ForegroundColor Yellow
        Start-Service msiserver -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        $msiService.Refresh()
        if ($msiService.Status -eq 'Running') {
            Write-Host "    ✓ Service started successfully" -ForegroundColor Green
        } else {
            Write-Host "    ❌ Failed to start service" -ForegroundColor Red
        }
    }
} else {
    Write-Host "  ❌ Windows Installer service not found!" -ForegroundColor Red
}

# 5. Check for pending reboot
Write-Host "`n[5/7] Checking for pending reboot..." -ForegroundColor Cyan

$rebootPending = $false
$rebootReasons = @()

if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") {
    $rebootPending = $true
    $rebootReasons += "Component Based Servicing"
}
if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") {
    $rebootPending = $true
    $rebootReasons += "Windows Update"
}

if ($rebootPending) {
    Write-Host "  ⚠️ REBOOT REQUIRED" -ForegroundColor Yellow
    Write-Host "    Reasons: $($rebootReasons -join ', ')" -ForegroundColor Gray
    Write-Host "`n  💡 RECOMMENDATION: Restart computer before installing Adobe" -ForegroundColor Yellow
} else {
    Write-Host "  ✓ No pending reboot" -ForegroundColor Green
}

# 6. Check Intune logs
Write-Host "`n[6/7] Checking Intune Management Extension logs..." -ForegroundColor Cyan

$intuneLog = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log"
if (Test-Path $intuneLog) {
    Write-Host "  ✓ Found Intune log" -ForegroundColor Green
    
    $intuneErrors = Select-String -Path $intuneLog -Pattern "Acrobat|0x80070643|install-enhanced" -CaseSensitive:$false | Select-Object -Last 20
    if ($intuneErrors) {
        Write-Host "`n  Recent Intune entries for Adobe:" -ForegroundColor Yellow
        $intuneErrors | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    }
} else {
    Write-Host "  ⚠️ Intune log not found (not managed by Intune?)" -ForegroundColor Yellow
}

# 7. Check Event Viewer
Write-Host "`n[7/7] Checking Event Viewer for MSI errors..." -ForegroundColor Cyan

$msiErrors = Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='MsiInstaller'; Level=2} -MaxEvents 5 -ErrorAction SilentlyContinue
if ($msiErrors) {
    Write-Host "  ⚠️ Recent MSI errors:" -ForegroundColor Yellow
    $msiErrors | ForEach-Object {
        Write-Host "    [$($_.TimeCreated)] $($_.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "  ✓ No recent MSI errors" -ForegroundColor Green
}

# Summary
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "📋 SUMMARY & NEXT STEPS" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

if ($rebootPending) {
    Write-Host "1. ⚠️ RESTART THIS COMPUTER (pending reboot detected)" -ForegroundColor Yellow
}

if ($adobeInRegistry) {
    Write-Host "2. ⚠️ UNINSTALL existing Adobe Acrobat before redeploying" -ForegroundColor Yellow
}

if ($freeGB -lt 10) {
    Write-Host "3. ⚠️ FREE UP DISK SPACE (need 10+ GB)" -ForegroundColor Yellow
}

if ($logFound) {
    Write-Host "`n📄 Review the full log file for details:" -ForegroundColor White
    Write-Host "   $logPath" -ForegroundColor Cyan
}

Write-Host "`n💡 Most common fix for 0x80070643:" -ForegroundColor Yellow
Write-Host "   - Uninstall any existing Adobe products" -ForegroundColor White
Write-Host "   - Restart the computer" -ForegroundColor White
Write-Host "   - Redeploy from Intune`n" -ForegroundColor White

pause
