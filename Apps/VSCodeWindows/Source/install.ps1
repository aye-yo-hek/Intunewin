#Requires -Version 5.1
<#
.SYNOPSIS
    Configures VS Code automatic update policy via registry

.DESCRIPTION
    This script sets the UpdateMode policy for Visual Studio Code to enable
    automatic checking and installation of updates. Deploys the policy at
    the machine level (HKLM) so it applies to all users.

.NOTES
    File Name      : install.ps1
    Author         : IT Admin
    Prerequisite   : PowerShell 5.1 or higher
    Date           : 2025-11-21
#>

# Set error action preference
$ErrorActionPreference = "Stop"

# Define registry path for VS Code policies
$RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Code"

# Policy configurations
$Policies = @{
    "UpdateMode" = "default"      # Options: default, start, manual, none
    "TelemetryLevel" = "off"      # Options: all, error, crash, off
}

try {
    Write-Host "Configuring VS Code Policies..." -ForegroundColor Cyan
    Write-Host "Registry Path: $RegPath" -ForegroundColor Gray
    Write-Host ""

    # Create registry path if it doesn't exist
    if (-not (Test-Path $RegPath)) {
        Write-Host "Creating registry path: $RegPath" -ForegroundColor Yellow
        New-Item -Path $RegPath -Force | Out-Null
    }

    # Apply each policy
    $AllSuccess = $true
    foreach ($Policy in $Policies.GetEnumerator()) {
        Write-Host "Setting $($Policy.Key) to '$($Policy.Value)'..." -ForegroundColor Yellow
        Set-ItemProperty -Path $RegPath -Name $Policy.Key -Value $Policy.Value -Type String -Force
        
        # Verify
        $CurrentValue = Get-ItemProperty -Path $RegPath -Name $Policy.Key -ErrorAction SilentlyContinue
        if ($CurrentValue.($Policy.Key) -eq $Policy.Value) {
            Write-Host "  ✓ $($Policy.Key) = $($Policy.Value)" -ForegroundColor Green
        }
        else {
            Write-Host "  ✗ Failed to set $($Policy.Key)" -ForegroundColor Red
            $AllSuccess = $false
        }
    }

    Write-Host ""
    if ($AllSuccess) {
        Write-Host "✓ All VS Code policies successfully configured!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Policy Details:" -ForegroundColor Cyan
        Write-Host "  Auto-Updates:" -ForegroundColor White
        Write-Host "    - Updates will be checked automatically in the background" -ForegroundColor White
        Write-Host "    - New versions will be downloaded and installed automatically" -ForegroundColor White
        Write-Host "    - Users will be prompted to restart VS Code when updates are ready" -ForegroundColor White
        Write-Host ""
        Write-Host "  Telemetry:" -ForegroundColor White
        Write-Host "    - All telemetry data collection is disabled" -ForegroundColor White
        Write-Host "    - No usage data, errors, or crash reports will be sent" -ForegroundColor White
        exit 0
    }
    else {
        Write-Host "✗ Some policies failed to configure" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
