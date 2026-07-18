# Remediation Script - Saves diagnostic to Public Documents
# This location is accessible to all users

$outputFile = "$env:PUBLIC\Documents\Adobe-Diagnostic-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"

try {
    # Header
    "=" * 60 | Out-File $outputFile
    "ADOBE ACROBAT INSTALLATION DIAGNOSTIC" | Out-File $outputFile -Append
    "Generated: $(Get-Date)" | Out-File $outputFile -Append
    "Computer: $env:COMPUTERNAME" | Out-File $outputFile -Append
    "=" * 60 | Out-File $outputFile -Append
    "" | Out-File $outputFile -Append

    # Check 1: Existing Adobe
    "[1] EXISTING ADOBE INSTALLATIONS" | Out-File $outputFile -Append
    "-" * 40 | Out-File $outputFile -Append
    
    $existing = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", 
                                  "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | 
        Where-Object { $_.DisplayName -like "*Adobe*Acrobat*" -or $_.DisplayName -like "*Adobe*Reader*" }
    
    if ($existing) {
        "FOUND - THIS IS LIKELY THE PROBLEM!" | Out-File $outputFile -Append
        $existing | ForEach-Object {
            "  Product: $($_.DisplayName)" | Out-File $outputFile -Append
            "  Version: $($_.DisplayVersion)" | Out-File $outputFile -Append
            "  Code: $($_.PSChildName)" | Out-File $outputFile -Append
            "  Uninstall: $($_.UninstallString)" | Out-File $outputFile -Append
            "" | Out-File $outputFile -Append
        }
    } else {
        "None found - OK" | Out-File $outputFile -Append
    }
    "" | Out-File $outputFile -Append

    # Check 2: Disk Space
    "[2] DISK SPACE" | Out-File $outputFile -Append
    "-" * 40 | Out-File $outputFile -Append
    $freeGB = [math]::Round((Get-PSDrive C).Free / 1GB, 2)
    "C: Drive Free: $freeGB GB" | Out-File $outputFile -Append
    if ($freeGB -lt 10) {
        "LOW DISK SPACE - PROBLEM!" | Out-File $outputFile -Append
    } else {
        "Sufficient - OK" | Out-File $outputFile -Append
    }
    "" | Out-File $outputFile -Append

    # Check 3: Installation Logs
    "[3] INSTALLATION LOGS" | Out-File $outputFile -Append
    "-" * 40 | Out-File $outputFile -Append
    
    $logs = @()
    @("$env:TEMP", "C:\Windows\Temp") | ForEach-Object {
        $logs += Get-ChildItem $_ -Filter "*Acrobat*.log" -ErrorAction SilentlyContinue
    }
    
    if ($logs) {
        $latest = $logs | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        "Found: $($latest.FullName)" | Out-File $outputFile -Append
        "Size: $([math]::Round($latest.Length/1KB, 2)) KB" | Out-File $outputFile -Append
        "Modified: $($latest.LastWriteTime)" | Out-File $outputFile -Append
        "" | Out-File $outputFile -Append
        
        "Searching for errors..." | Out-File $outputFile -Append
        $errors = Select-String -Path $latest.FullName -Pattern "Error 1311|Error 1335|cab|return value 3" -Context 0,1 | Select-Object -Last 10
        if ($errors) {
            "ERRORS FOUND:" | Out-File $outputFile -Append
            $errors | ForEach-Object { "  $($_.Line)" | Out-File $outputFile -Append }
        } else {
            "No critical errors in log" | Out-File $outputFile -Append
        }
    } else {
        "No logs found - installation may not have started" | Out-File $outputFile -Append
    }
    "" | Out-File $outputFile -Append

    # Check 4: Windows Installer
    "[4] WINDOWS INSTALLER SERVICE" | Out-File $outputFile -Append
    "-" * 40 | Out-File $outputFile -Append
    $msi = Get-Service msiserver -ErrorAction SilentlyContinue
    if ($msi) {
        "Status: $($msi.Status)" | Out-File $outputFile -Append
    } else {
        "NOT FOUND - CRITICAL PROBLEM!" | Out-File $outputFile -Append
    }
    "" | Out-File $outputFile -Append

    # Check 5: Event Viewer
    "[5] RECENT MSI ERRORS" | Out-File $outputFile -Append
    "-" * 40 | Out-File $outputFile -Append
    $events = Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='MsiInstaller'; Level=2} -MaxEvents 3 -ErrorAction SilentlyContinue
    if ($events) {
        $events | ForEach-Object {
            "[$($_.TimeCreated)] $($_.Message)" | Out-File $outputFile -Append
        }
    } else {
        "No recent errors - OK" | Out-File $outputFile -Append
    }
    "" | Out-File $outputFile -Append

    # Summary
    "=" * 60 | Out-File $outputFile -Append
    "SUMMARY" | Out-File $outputFile -Append
    "=" * 60 | Out-File $outputFile -Append
    
    if ($existing) {
        "ACTION REQUIRED: Uninstall existing Adobe before deploying" | Out-File $outputFile -Append
    }
    if ($freeGB -lt 10) {
        "ACTION REQUIRED: Free up disk space (need 10+ GB)" | Out-File $outputFile -Append
    }
    if (-not $existing -and $freeGB -ge 10) {
        "No obvious issues found. Check installation logs above." | Out-File $outputFile -Append
    }
    "" | Out-File $outputFile -Append
    "Report saved: $outputFile" | Out-File $outputFile -Append

    Write-Host "Diagnostic complete: $outputFile"
    Exit 0
}
catch {
    Write-Host "Error: $_"
    Exit 1
}
