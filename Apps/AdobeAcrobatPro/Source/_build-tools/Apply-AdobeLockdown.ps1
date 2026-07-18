# Apply-AdobeLockdown.ps1
# PowerShell script to apply Adobe cloud/AI lockdown settings
# Can be deployed as a separate Intune PowerShell script

$ErrorActionPreference = "Stop"

Write-Host "=== Adobe Acrobat DC - Cloud/AI Lockdown ===" -ForegroundColor Cyan

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must run as Administrator" -ForegroundColor Red
    exit 1
}

# Define registry settings
$regSettings = @{
    "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" = @{
        "bDisableShareFeedback" = 1
        "bToggleFillSign" = 0
        "bTogglePrefsSync" = 0
        "bDisableTrustedSites" = 1
        "bEnableFlash" = 0
        "bDisableAcrobatAssistant" = 1
        "bDisableAI" = 1
        "bDisableAcrobatUpdate" = 0
        "bProtectedMode" = 1
    }
    "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" = @{
        "bToggleAdobeDocumentServices" = 0
        "bToggleAdobeSign" = 0
        "bTogglePrefSync" = 0
        "bToggleWebConnectors" = 0
        "bUpdater" = 0
        "bToggleShareFeedback" = 0
    }
    "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cCloud" = @{
        "bDisableShareFeedback" = 1
        "bDisablePDFHandlerSwitching" = 1
    }
    "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cIPM" = @{
        "bShowMsgAtLaunch" = 0
        "bDontShowMsgWhenViewingDoc" = 1
    }
    "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cSharePoint" = @{
        "bDisableSharePointFeatures" = 1
    }
    "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cWelcomeScreen" = @{
        "bShowWelcomeScreen" = 0
    }
    "HKLM:\SOFTWARE\Adobe\Adobe Acrobat\DC\Workflows" = @{
        "bEnableAcrobatHS" = 0
    }
    "HKLM:\SOFTWARE\Adobe\Adobe Acrobat\DC\AVGeneral" = @{
        "bUsageMeasurement" = 0
    }
}

# Apply registry settings
$successCount = 0
$failCount = 0

foreach ($path in $regSettings.Keys) {
    Write-Host "`nConfiguring: $path" -ForegroundColor Yellow
    
    # Create registry path if it doesn't exist
    if (-not (Test-Path $path)) {
        try {
            New-Item -Path $path -Force | Out-Null
            Write-Host "  Created registry path" -ForegroundColor Green
        }
        catch {
            Write-Host "  ERROR: Failed to create path: $($_.Exception.Message)" -ForegroundColor Red
            $failCount++
            continue
        }
    }
    
    # Set each value
    foreach ($name in $regSettings[$path].Keys) {
        $value = $regSettings[$path][$name]
        
        try {
            Set-ItemProperty -Path $path -Name $name -Value $value -Type DWord -Force
            Write-Host "  ✓ $name = $value" -ForegroundColor Green
            $successCount++
        }
        catch {
            Write-Host "  ✗ Failed to set $name : $($_.Exception.Message)" -ForegroundColor Red
            $failCount++
        }
    }
}

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Successfully applied: $successCount settings" -ForegroundColor Green
if ($failCount -gt 0) {
    Write-Host "Failed to apply: $failCount settings" -ForegroundColor Red
}

# Verification
Write-Host "`n=== Verification ===" -ForegroundColor Yellow

$keysToCheck = @(
    @{ Path = "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown"; Name = "bDisableAI" },
    @{ Path = "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown"; Name = "bDisableAcrobatAssistant" },
    @{ Path = "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices"; Name = "bToggleAdobeDocumentServices" },
    @{ Path = "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices"; Name = "bToggleAdobeSign" }
)

foreach ($key in $keysToCheck) {
    try {
        $value = Get-ItemProperty -Path $key.Path -Name $key.Name -ErrorAction Stop
        $val = $value.($key.Name)
        
        $expected = if ($key.Name -match "^bDisable|bShowMsg") { 1 } else { 0 }
        
        if ($val -eq $expected) {
            Write-Host "✓ $($key.Name) = $val (Correct)" -ForegroundColor Green
        } else {
            Write-Host "⚠ $($key.Name) = $val (Expected: $expected)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "✗ $($key.Name) : Not found" -ForegroundColor Red
    }
}

Write-Host "`n=== Cloud/AI Lockdown Complete ===" -ForegroundColor Cyan

if ($failCount -eq 0) {
    Write-Host "All settings applied successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Some settings failed to apply. Check errors above." -ForegroundColor Yellow
    exit 1
}
