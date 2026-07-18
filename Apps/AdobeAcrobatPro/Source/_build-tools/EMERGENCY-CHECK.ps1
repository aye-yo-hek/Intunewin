# EMERGENCY DIAGNOSTIC - Run on failing machine
# This will tell us EXACTLY what's wrong

Write-Host "`n=== CRITICAL CHECKS ===" -ForegroundColor Red

# 1. Is there an existing Adobe installation?
Write-Host "`n[1] Checking for existing Adobe..." -ForegroundColor Yellow
$existing = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -like "*Adobe*Acrobat*" }
if ($existing) {
    Write-Host "PROBLEM FOUND: Existing Adobe installation detected" -ForegroundColor Red
    $existing | ForEach-Object { 
        Write-Host "  Name: $($_.DisplayName)" -ForegroundColor White
        Write-Host "  Uninstall: $($_.UninstallString)" -ForegroundColor White
    }
    Write-Host "`nFIX: Uninstall existing Adobe first" -ForegroundColor Green
} else {
    Write-Host "OK: No existing Adobe found" -ForegroundColor Green
}

# 2. Check disk space
Write-Host "`n[2] Checking disk space..." -ForegroundColor Yellow
$freeGB = [math]::Round((Get-PSDrive C).Free / 1GB, 2)
if ($freeGB -lt 10) {
    Write-Host "PROBLEM FOUND: Only $freeGB GB free (need 10+ GB)" -ForegroundColor Red
    Write-Host "`nFIX: Free up disk space" -ForegroundColor Green
} else {
    Write-Host "OK: $freeGB GB available" -ForegroundColor Green
}

# 3. Find installation logs
Write-Host "`n[3] Looking for installation logs..." -ForegroundColor Yellow
$logs = Get-ChildItem "$env:TEMP", "C:\Windows\Temp" -Filter "*Acrobat*.log" -ErrorAction SilentlyContinue
if ($logs) {
    $latest = $logs | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    Write-Host "LOG FOUND: $($latest.FullName)" -ForegroundColor Green
    Write-Host "`nSearching for actual error..." -ForegroundColor Yellow
    
    # Look for the smoking gun
    $critical = Select-String -Path $latest.FullName -Pattern "Error 1311|Error 1335|cab|return value 3" -Context 1,1 | Select-Object -Last 5
    if ($critical) {
        Write-Host "`nCRITICAL ERRORS:" -ForegroundColor Red
        $critical | ForEach-Object { Write-Host $_.Line -ForegroundColor White }
    }
} else {
    Write-Host "NO LOG FOUND - Installation never started" -ForegroundColor Red
    Write-Host "`nCheck Intune log instead:" -ForegroundColor Yellow
    Write-Host "  C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log" -ForegroundColor White
}

# 4. Check Windows Installer
Write-Host "`n[4] Checking Windows Installer..." -ForegroundColor Yellow
$msi = Get-Service msiserver
if ($msi.Status -ne 'Running') {
    Write-Host "PROBLEM: Windows Installer not running" -ForegroundColor Red
    Write-Host "`nFIX: Start-Service msiserver" -ForegroundColor Green
} else {
    Write-Host "OK: Windows Installer running" -ForegroundColor Green
}

# 5. Recent MSI errors in Event Log
Write-Host "`n[5] Checking Event Viewer..." -ForegroundColor Yellow
$events = Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='MsiInstaller'; Level=2} -MaxEvents 3 -ErrorAction SilentlyContinue
if ($events) {
    Write-Host "RECENT MSI ERRORS:" -ForegroundColor Red
    $events | ForEach-Object {
        Write-Host "  [$($_.TimeCreated)] $($_.Message)" -ForegroundColor White
    }
} else {
    Write-Host "OK: No recent MSI errors" -ForegroundColor Green
}

Write-Host "`n=== WHAT TO DO NEXT ===" -ForegroundColor Cyan
Write-Host "1. If existing Adobe found: Uninstall it" -ForegroundColor White
Write-Host "2. Restart the computer" -ForegroundColor White
Write-Host "3. Retry deployment from Intune" -ForegroundColor White
Write-Host "4. If still fails, share the log file content`n" -ForegroundColor White

pause
