#Requires -Version 5.1
<#
.SYNOPSIS
    Detection script for MSI application deployment via Intune

.DESCRIPTION
    This script detects if the application is installed correctly.
    Customize the detection logic for your specific application.

.NOTES
    Exit 0 = Application is installed (detected)
    Exit 1 = Application is not installed (not detected)
#>

$ErrorActionPreference = "SilentlyContinue"

# ===================================
# Configuration - Choose detection method
# ===================================

# Method 1: Detect by MSI Product Code (Most reliable)
$ProductCode = "{00000000-0000-0000-0000-000000000000}"  # Update this!

# Method 2: Detect by file path
$FilePath = "C:\Program Files\YourCompany\YourApp\YourApp.exe"  # Update this!

# Method 3: Detect by registry key
$RegistryPath = "HKLM:\SOFTWARE\YourCompany\YourApp"  # Update this!
$RegistryValue = "Version"
$ExpectedVersion = "1.0.0"

# ===================================
# Detection Logic - Uncomment the method you want to use
# ===================================

# Method 1: Product Code Detection (Recommended)
<#
$installedApps = Get-WmiObject -Class Win32_Product | Where-Object {$_.IdentifyingNumber -eq $ProductCode}

if ($installedApps) {
    Write-Host "Application detected via Product Code: $ProductCode"
    exit 0
}
#>

# Method 2: File Path Detection
<#
if (Test-Path $FilePath) {
    $fileVersion = (Get-Item $FilePath).VersionInfo.FileVersion
    Write-Host "Application detected at: $FilePath (Version: $fileVersion)"
    exit 0
}
#>

# Method 3: Registry Detection
<#
if (Test-Path $RegistryPath) {
    $installedVersion = Get-ItemProperty -Path $RegistryPath -Name $RegistryValue -ErrorAction SilentlyContinue
    
    if ($installedVersion.$RegistryValue -eq $ExpectedVersion) {
        Write-Host "Application detected via registry. Version: $ExpectedVersion"
        exit 0
    }
}
#>

# Method 4: Combined Detection (File + Version check)
<#
if (Test-Path $FilePath) {
    $fileVersion = (Get-Item $FilePath).VersionInfo.FileVersion
    
    if ($fileVersion -eq $ExpectedVersion) {
        Write-Host "Application detected. Version: $fileVersion"
        exit 0
    }
    else {
        Write-Host "Wrong version detected. Expected: $ExpectedVersion, Found: $fileVersion"
        exit 1
    }
}
#>

# Default: Not detected
Write-Host "Application not detected"
exit 1
