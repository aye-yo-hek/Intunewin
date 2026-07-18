#Requires -Version 5.1
<#
.SYNOPSIS
    Removes VS Code automatic update policy

.DESCRIPTION
    This script removes the UpdateMode policy for Visual Studio Code,
    allowing users to control update settings themselves.

.NOTES
    File Name      : uninstall.ps1
    Author         : IT Admin
    Date           : 2025-11-21
#>

$ErrorActionPreference = "Stop"

$RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Code"
$PolicyNames = @("UpdateMode", "TelemetryLevel")

try {
    Write-Host "Removing VS Code Policies..." -ForegroundColor Cyan
    
    if (Test-Path $RegPath) {
        $RemovedAny = $false
        
        foreach ($PolicyName in $PolicyNames) {
            $Property = Get-ItemProperty -Path $RegPath -Name $PolicyName -ErrorAction SilentlyContinue
            
            if ($Property) {
                Write-Host "Removing $PolicyName policy..." -ForegroundColor Yellow
                Remove-ItemProperty -Path $RegPath -Name $PolicyName -Force
                Write-Host "  ✓ $PolicyName removed" -ForegroundColor Green
                $RemovedAny = $true
            }
        }
        
        if ($RemovedAny) {
            Write-Host ""
            Write-Host "✓ VS Code policies removed successfully!" -ForegroundColor Green
        }
        else {
            Write-Host "No policies found to remove." -ForegroundColor Yellow
        }
        
        # Clean up empty registry key if no other policies exist
        $RemainingProperties = Get-ItemProperty -Path $RegPath
        if (($RemainingProperties.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' }).Count -eq 0) {
            Write-Host "Removing empty registry key..." -ForegroundColor Yellow
            Remove-Item -Path $RegPath -Force
        }
    }
    else {
        Write-Host "Registry path not found. Nothing to remove." -ForegroundColor Yellow
    }
    
    exit 0
}
catch {
    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
