# Python 3.14 Win32 App Package for Microsoft Intune

## Overview
This package contains the necessary files to deploy Python 3.14 via Microsoft Intune as a Win32 application.

## Package Contents

### Installation Files
- `install.cmd` - Silent installation script
- `uninstall.cmd` - Uninstallation script  
- `detect.ps1` - Detection script for Intune
- `python-3.14.0-amd64.exe` - **[YOU NEED TO DOWNLOAD THIS]**

### Required Download
**IMPORTANT**: You must download the Python 3.14 installer and place it in the exe files folder:

1. Go to https://www.python.org/downloads/
2. Download `python-3.14.0-amd64.exe` (Windows x86-64 executable installer)
3. Place the file in the "exe files" folder in the root directory

## Installation Details

### What the installer does:
- Installs Python 3.14 for all users
- Adds Python to system PATH
- Includes pip package manager
- Creates registry entries for detection
- Installs to `C:\Program Files\Python314\`

### Installation Parameters:
- `/quiet` - Silent installation
- `InstallAllUsers=1` - Install for all users
- `PrependPath=1` - Add to PATH
- `Include_test=0` - Skip test suite
- `Include_launcher=1` - Include Python launcher
- `InstallLauncherAllUsers=1` - Launcher for all users

## Intune Configuration

### Application Information
- **Name**: Python 3.14
- **Description**: Python 3.14 programming language runtime
- **Publisher**: Python Software Foundation
- **Category**: Developer tools

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
- **Value name**: `Python314`
- **Detection method**: String comparison
- **Operator**: Equals
- **Value**: `Installed`

#### Option 2: File Detection
- **Rule type**: File
- **Path**: `C:\Program Files\Python314`
- **File or folder**: `python.exe`
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
# After downloading python-3.14.0-amd64.exe to the "exe files" folder
.\Create-IntunePackage.ps1
```

### Using Win32 Content Prep Tool Directly
```cmd
.\packaging\IntuneWinAppUtil.exe -c "src\Python314" -s "install.cmd" -o "packages"
```

## Pre-deployment Testing

Test the installation locally:

```powershell
# Test the install script directly
.\src\Python314\install.cmd

# Test the uninstall script
.\src\Python314\uninstall.cmd

# Test detection
.\src\Python314\detect.ps1
```

## Troubleshooting

### Common Issues
1. **Python installer not found**: Ensure `python-3.14.0-amd64.exe` is in the same directory as `install.cmd`
2. **Permission denied**: Installation requires administrative privileges
3. **PATH not updated**: May require user logout/login or system restart
4. **Detection fails**: Verify registry entries are created during installation

### Log Locations
- **Installation logs**: `%TEMP%\Python 3.14.0 Installation Log.txt`
- **Windows Event Log**: Application log for installation events
- **Intune logs**: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs`

## Verification Commands

After installation, verify Python is working:

```cmd
python --version
pip --version
python -c "print('Hello from Python 3.14!')"
```

## Notes
- Installation is silent and requires no user interaction
- Python is installed for all users on the system
- The package includes pip for installing additional Python packages
- Uninstall removes Python and cleans up PATH and registry entries