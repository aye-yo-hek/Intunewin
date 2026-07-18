# =========================================================
# Adobe Acrobat DC - Error 1603 Diagnostic Script
# Run this on the FAILING device to diagnose the issue
# =========================================================

Write-Host "`n=== ADOBE ACROBAT ERROR 1603 DIAGNOSTICS ===" -ForegroundColor Cyan
Write-Host "Running diagnostics on this device...`n" -ForegroundColor Gray

# 1. Check disk space
Write-Host "[1/7] Checking disk space..." -ForegroundColor Yellow
$disk = Get-PSDrive C | Select-Object Used, Free
$freeGB = [math]::Round($disk.Free / 1GB, 2)
Write-Host "  Free space on C: drive: $freeGB GB" -ForegroundColor White
if ($freeGB -lt 8) {
    Write-Host "  ❌ INSUFFICIENT DISK SPACE! Need at least 8 GB free." -ForegroundColor Red
} else {
    Write-Host "  ✅ Sufficient disk space" -ForegroundColor Green
}

# 2. Check for existing Adobe installations
Write-Host "`n[2/7] Checking for existing Adobe installations..." -ForegroundColor Yellow
$adobe = Get-WmiObject -Class Win32_Product -ErrorAction SilentlyContinue | Where-Object {$_.Name -like "*Adobe*Acrobat*"}
if ($adobe) {
    Write-Host "  ❌ FOUND EXISTING ADOBE INSTALLATION:" -ForegroundColor Red
    $adobe | ForEach-Object {
        Write-Host "    - $($_.Name) (Version: $($_.Version))" -ForegroundColor Yellow
        Write-Host "      Product Code: $($_.IdentifyingNumber)" -ForegroundColor Gray
    }
    Write-Host "  ACTION: Uninstall existing version first!" -ForegroundColor Red
} else {
    Write-Host "  ✅ No existing Adobe Acrobat found" -ForegroundColor Green
}

# 3. Check Windows Installer service
Write-Host "`n[3/7] Checking Windows Installer service..." -ForegroundColor Yellow
$msi = Get-Service -Name msiserver -ErrorAction SilentlyContinue
if ($msi) {
    Write-Host "  Status: $($msi.Status)" -ForegroundColor White
    if ($msi.Status -eq 'Running') {
        Write-Host "  ✅ Windows Installer service is running" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Windows Installer service is not running" -ForegroundColor Yellow
        Write-Host "  Starting service..." -ForegroundColor Gray
        Start-Service msiserver
    }
} else {
    Write-Host "  ❌ Windows Installer service not found!" -ForegroundColor Red
}

# 4. Check TEMP folder access
Write-Host "`n[4/7] Checking TEMP folder..." -ForegroundColor Yellow
$temp = $env:TEMP
Write-Host "  TEMP path: $temp" -ForegroundColor White
if (Test-Path $temp) {
    try {
        $testFile = Join-Path $temp "acrobat-test-$(Get-Random).txt"
        "test" | Out-File $testFile -ErrorAction Stop
        Remove-Item $testFile -ErrorAction SilentlyContinue
        Write-Host "  ✅ TEMP folder is writable" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ CANNOT WRITE TO TEMP FOLDER!" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "  ❌ TEMP folder does not exist!" -ForegroundColor Red
}

# 5. Check for MSI installation logs
Write-Host "`n[5/7] Looking for Adobe installation logs..." -ForegroundColor Yellow
$logFile = Join-Path $env:TEMP "Acrobat.msi.install.log"
if (Test-Path $logFile) {
    Write-Host "  ✅ Found log file: $logFile" -ForegroundColor Green
    Write-Host "`n  LAST 20 LINES OF LOG:" -ForegroundColor Cyan
    Write-Host "  " + ("-" * 70) -ForegroundColor Gray
    Get-Content $logFile -Tail 20 | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
    Write-Host "  " + ("-" * 70) -ForegroundColor Gray
} else {
    Write-Host "  ⚠️  No log file found (installation may not have started)" -ForegroundColor Yellow
}

# 6. Check System32 folder permissions
Write-Host "`n[6/7] Checking System32 folder access..." -ForegroundColor Yellow
try {
    $sys32 = Get-ChildItem $env:SystemRoot\System32 -ErrorAction Stop | Select-Object -First 1
    Write-Host "  ✅ Can access System32 folder" -ForegroundColor Green
} catch {
    Write-Host "  ❌ CANNOT ACCESS SYSTEM32!" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}

# 7. Check pending reboot
Write-Host "`n[7/7] Checking for pending reboot..." -ForegroundColor Yellow
$rebootPending = $false
if (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue) {
    $rebootPending = $true
}
if (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue) {
    $rebootPending = $true
}
if ($rebootPending) {
    Write-Host "  ⚠️  SYSTEM REBOOT PENDING! Reboot before installing." -ForegroundColor Yellow
} else {
    Write-Host "  ✅ No pending reboot" -ForegroundColor Green
}

# Summary
Write-Host "`n" + ("=" * 70) -ForegroundColor Cyan
Write-Host "DIAGNOSTIC SUMMARY" -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "  1. Review the log file tail above (if found)" -ForegroundColor White
Write-Host "  2. Uninstall any existing Adobe installations" -ForegroundColor White
Write-Host "  3. Reboot if pending" -ForegroundColor White
Write-Host "  4. Ensure at least 8 GB free disk space" -ForegroundColor White
Write-Host "  5. Clean TEMP folder: Remove-Item `$env:TEMP\* -Recurse -Force" -ForegroundColor White
Write-Host "  6. Retry deployment`n" -ForegroundColor White

Write-Host "For detailed log analysis, open:" -ForegroundColor Cyan
Write-Host "  $logFile`n" -ForegroundColor Yellow
