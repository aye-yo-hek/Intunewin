# ADOBE DIAGNOSTIC - Saves results to Downloads folder
# Deploy via Intune as a script

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$outputFile = "$env:USERPROFILE\Downloads\Adobe-Diagnostic-$timestamp.txt"

function Write-Output-Both {
    param([string]$Message)
    Write-Host $Message
    Add-Content -Path $outputFile -Value $Message
}

# Start diagnostic
Write-Output-Both "=============================================="
Write-Output-Both "ADOBE ACROBAT DIAGNOSTIC REPORT"
Write-Output-Both "Generated: $(Get-Date)"
Write-Output-Both "Computer: $env:COMPUTERNAME"
Write-Output-Both "User: $env:USERNAME"
Write-Output-Both "==============================================`n"

# 1. Check for existing Adobe
Write-Output-Both "[CHECK 1] EXISTING ADOBE INSTALLATIONS"
Write-Output-Both "----------------------------------------"
$existing = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | 
    Where-Object { $_.DisplayName -like "*Adobe*Acrobat*" -or $_.DisplayName -like "*Adobe*Reader*" }

if ($existing) {
    Write-Output-Both "STATUS: EXISTING ADOBE FOUND - THIS IS THE PROBLEM!"
    $existing | ForEach-Object {
        Write-Output-Both "  Product: $($_.DisplayName)"
        Write-Output-Both "  Version: $($_.DisplayVersion)"
        Write-Output-Both "  Publisher: $($_.Publisher)"
        Write-Output-Both "  Product Code: $($_.PSChildName)"
        Write-Output-Both "  Uninstall String: $($_.UninstallString)"
        Write-Output-Both ""
    }
    Write-Output-Both "RECOMMENDATION: Uninstall existing Adobe before deploying new package"
} else {
    Write-Output-Both "STATUS: No existing Adobe installations found - GOOD"
}
Write-Output-Both ""

# 2. Check disk space
Write-Output-Both "[CHECK 2] DISK SPACE"
Write-Output-Both "----------------------------------------"
$drive = Get-PSDrive C
$freeGB = [math]::Round($drive.Free / 1GB, 2)
$totalGB = [math]::Round($drive.Used / 1GB + $freeGB, 2)
Write-Output-Both "C: Drive Total: $totalGB GB"
Write-Output-Both "C: Drive Free: $freeGB GB"
if ($freeGB -lt 10) {
    Write-Output-Both "STATUS: LOW DISK SPACE - THIS IS A PROBLEM!"
    Write-Output-Both "RECOMMENDATION: Free up at least 10 GB of space"
} else {
    Write-Output-Both "STATUS: Sufficient disk space - GOOD"
}
Write-Output-Both ""

# 3. Check for installation logs
Write-Output-Both "[CHECK 3] INSTALLATION LOGS"
Write-Output-Both "----------------------------------------"
$logLocations = @(
    "$env:TEMP\Acrobat.msi.install.log",
    "$env:TEMP\Acrobat.msi.install.log.patch",
    "C:\Windows\Temp\Acrobat.msi.install.log",
    "C:\Windows\Temp\Acrobat.msi.install.log.patch"
)

$logFound = $false
foreach ($log in $logLocations) {
    if (Test-Path $log) {
        $logFound = $true
        $logInfo = Get-Item $log
        Write-Output-Both "FOUND: $log"
        Write-Output-Both "  Size: $([math]::Round($logInfo.Length/1KB, 2)) KB"
        Write-Output-Both "  Modified: $($logInfo.LastWriteTime)"
        
        # Search for critical errors
        Write-Output-Both "`n  Searching for errors in log..."
        $errors = Select-String -Path $log -Pattern "Error 1311|Error 1335|cab|return value 3|failed" -Context 1,1 | Select-Object -Last 10
        if ($errors) {
            Write-Output-Both "  ERRORS FOUND:"
            $errors | ForEach-Object {
                Write-Output-Both "    $($_.Line)"
            }
        } else {
            Write-Output-Both "  No critical errors found in log"
        }
        Write-Output-Both ""
    }
}

if (-not $logFound) {
    Write-Output-Both "STATUS: No installation logs found"
    Write-Output-Both "This means installation never started or logs were cleaned up"
}
Write-Output-Both ""

# 4. Check Windows Installer service
Write-Output-Both "[CHECK 4] WINDOWS INSTALLER SERVICE"
Write-Output-Both "----------------------------------------"
$msiService = Get-Service msiserver -ErrorAction SilentlyContinue
if ($msiService) {
    Write-Output-Both "Service Status: $($msiService.Status)"
    Write-Output-Both "Service Start Type: $($msiService.StartType)"
    if ($msiService.Status -eq 'Running') {
        Write-Output-Both "STATUS: Service running - GOOD"
    } else {
        Write-Output-Both "STATUS: Service not running - PROBLEM"
    }
} else {
    Write-Output-Both "STATUS: Windows Installer service not found - CRITICAL PROBLEM"
}
Write-Output-Both ""

# 5. Check Event Viewer for MSI errors
Write-Output-Both "[CHECK 5] RECENT MSI ERRORS (EVENT VIEWER)"
Write-Output-Both "----------------------------------------"
$msiErrors = Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='MsiInstaller'; Level=2} -MaxEvents 5 -ErrorAction SilentlyContinue
if ($msiErrors) {
    Write-Output-Both "RECENT MSI ERRORS FOUND:"
    $msiErrors | ForEach-Object {
        Write-Output-Both "  Time: $($_.TimeCreated)"
        Write-Output-Both "  Message: $($_.Message)"
        Write-Output-Both ""
    }
} else {
    Write-Output-Both "STATUS: No recent MSI errors - GOOD"
}
Write-Output-Both ""

# 6. Check Intune logs
Write-Output-Both "[CHECK 6] INTUNE MANAGEMENT LOGS"
Write-Output-Both "----------------------------------------"
$intuneLog = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log"
if (Test-Path $intuneLog) {
    Write-Output-Both "FOUND: $intuneLog"
    $intuneErrors = Select-String -Path $intuneLog -Pattern "Acrobat|Adobe|0x80070643|install-enhanced" -Context 0,1 | Select-Object -Last 15
    if ($intuneErrors) {
        Write-Output-Both "`nRecent Adobe-related entries:"
        $intuneErrors | ForEach-Object {
            Write-Output-Both "  $($_.Line)"
        }
    } else {
        Write-Output-Both "No Adobe-related entries found"
    }
} else {
    Write-Output-Both "STATUS: Intune log not found (machine may not be Intune-managed)"
}
Write-Output-Both ""

# 7. Check for pending reboots
Write-Output-Both "[CHECK 7] PENDING REBOOT"
Write-Output-Both "----------------------------------------"
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
    Write-Output-Both "STATUS: REBOOT REQUIRED"
    Write-Output-Both "Reasons: $($rebootReasons -join ', ')"
    Write-Output-Both "RECOMMENDATION: Restart computer before installing Adobe"
} else {
    Write-Output-Both "STATUS: No pending reboot - GOOD"
}
Write-Output-Both ""

# Summary
Write-Output-Both "=============================================="
Write-Output-Both "SUMMARY & RECOMMENDATIONS"
Write-Output-Both "=============================================="

$criticalIssues = @()
if ($existing) { $criticalIssues += "Existing Adobe installation found - MUST UNINSTALL FIRST" }
if ($freeGB -lt 10) { $criticalIssues += "Insufficient disk space - Need 10+ GB free" }
if ($rebootPending) { $criticalIssues += "Pending reboot - Restart required" }
if ($msiService.Status -ne 'Running') { $criticalIssues += "Windows Installer service not running" }

if ($criticalIssues.Count -gt 0) {
    Write-Output-Both "`nCRITICAL ISSUES FOUND:"
    $criticalIssues | ForEach-Object {
        Write-Output-Both "  - $_"
    }
    Write-Output-Both "`nFIX THESE ISSUES BEFORE REDEPLOYING ADOBE"
} else {
    Write-Output-Both "`nNo critical issues found. If installation still fails,"
    Write-Output-Both "the problem may be with the package itself or Intune deployment settings."
}

Write-Output-Both "`n=============================================="
Write-Output-Both "Report saved to: $outputFile"
Write-Output-Both "=============================================="

# Open the report
Start-Process notepad.exe -ArgumentList $outputFile

Write-Host "`nDiagnostic complete! Report saved to Downloads folder." -ForegroundColor Green
Exit 0
