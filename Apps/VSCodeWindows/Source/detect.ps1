#Requires -Version 5.1
<#
.SYNOPSIS
    Detection script for VS Code Auto-Update Policy

.DESCRIPTION
    This script checks if the VS Code UpdateMode policy is configured correctly.
    Returns exit code 0 if the policy is set to 'default' (auto-update enabled).
    
    This script is used by Microsoft Intune to detect if the configuration
    needs to be applied or remediated.

.NOTES
    File Name      : detect.ps1
    Author         : IT Admin
    Date           : 2025-11-21
    
.INTUNE DETECTION LOGIC
    Exit 0 = Policy is configured correctly (app is "installed")
    Exit 1 = Policy is not configured or incorrect (app needs to be "installed")
#>

$ErrorActionPreference = "SilentlyContinue"

# Define registry path and expected values
$RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Code"
$ExpectedPolicies = @{
    "UpdateMode" = "default"
    "TelemetryLevel" = "off"
}

# Check if registry path exists
if (-not (Test-Path $RegPath)) {
    Write-Host "VS Code policy registry path not found"
    exit 1
}

# Check each policy
$AllCorrect = $true
foreach ($Policy in $ExpectedPolicies.GetEnumerator()) {
    $CurrentValue = Get-ItemProperty -Path $RegPath -Name $Policy.Key -ErrorAction SilentlyContinue
    
    if (-not $CurrentValue) {
        Write-Host "$($Policy.Key) policy not found"
        $AllCorrect = $false
    }
    elseif ($CurrentValue.($Policy.Key) -ne $Policy.Value) {
        Write-Host "$($Policy.Key) is set to: $($CurrentValue.($Policy.Key)) (expected: $($Policy.Value))"
        $AllCorrect = $false
    }
}

if ($AllCorrect) {
    Write-Host "All VS Code policies are configured correctly"
    exit 0
}
else {
    exit 1
}
