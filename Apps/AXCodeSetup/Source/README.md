# AXCodeSetup Win32 App Package for Microsoft Intune

## Overview
This package contains the necessary files to deploy AXCodeSetup via Microsoft Intune as a Win32 application.

## Package Contents

### Installation Files
- `install.cmd` - Silent installation script
- `uninstall.cmd` - Uninstallation script
- `detect.ps1` - Detection script for Intune
- `axcodesetup.exe` - **[YOU NEED TO PLACE THIS IN exe files FOLDER]**

### Required Download
**IMPORTANT**: Place the AXCodeSetup installer (`axcodesetup.exe`) in the `exe files` folder in the root directory.

## Installation Details
- **Install command**: `"%~dp0..\..\exe files\axcodesetup.exe" /S`
- **Uninstall command**: `"%~dp0..\..\exe files\axcodesetup.exe" /S /uninstall`
- Creates registry entries for detection
- Silent installation with no user interaction required

## Intune Configuration

### Application Information
- **Name**: AXCodeSetup
- **Description**: AXCodeSetup application
- **Publisher**: [Your Publisher]
- **Category**: [Choose appropriate category]

### Program Configuration
- **Install command**: `install.cmd`
- **Uninstall command**: `uninstall.cmd`
- **Install behavior**: System
- **Device restart behavior**: No specific action

### Requirements
- **Operating system architecture**: x64
- **Minimum operating system**: Windows 10 1809

### Detection Rules
#### Option 1: Registry Detection (Recommended)
- **Rule type**: Registry
- **Key path**: `HKEY_LOCAL_MACHINE\SOFTWARE\YourCompany\IntuneApps`
- **Value name**: `AXCodeSetup`
- **Detection method**: String comparison
- **Operator**: Equals
- **Value**: `Installed`

#### Option 2: File Detection
- **Rule type**: File
- **Path**: `C:\Program Files\AXCodeSetup`
- **File or folder**: `axcodesetup.exe`
- **Detection method**: File or folder exists

#### Option 3: PowerShell Script Detection
- **Rule type**: Use a custom detection script
- **Script file**: Upload `detect.ps1`
- **Run script as 32-bit process**: No

### Return Codes
- **0**: Success
- **1603**: Fatal error during installation
- **1618**: Another installation is in progress
- **3010**: Success, restart required

## Creating the .intunewin Package

### Using the provided script (Recommended)
```powershell
# After placing axcodesetup.exe in the "exe files" folder
.\Create-IntunePackage.ps1
```

### Using Win32 Content Prep Tool Directly
```cmd
.\packaging\IntuneWinAppUtil.exe -c "src\AXCodeSetup" -s "install.cmd" -o "packages"
```

## Pre-deployment Testing
Test the installation locally:
```powershell
# Test the install script directly
.\src\AXCodeSetup\install.cmd

# Test the uninstall script
.\src\AXCodeSetup\uninstall.cmd

# Test detection
.\src\AXCodeSetup\detect.ps1
```

## Notes
- Installation is silent and requires no user interaction
- Uninstall removes AXCodeSetup and cleans up registry entries