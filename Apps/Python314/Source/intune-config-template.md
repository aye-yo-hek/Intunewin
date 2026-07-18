# Intune Win32 App Configuration Template

Use this template when configuring the Python 3.14 app in Microsoft Intune.

## Basic Information

| Field | Value |
|-------|-------|
| **Name** | Python 3.14 |
| **Description** | Python 3.14 programming language runtime for all users |
| **Publisher** | Python Software Foundation |
| **Information URL** | https://www.python.org/ |
| **Privacy URL** | https://www.python.org/privacy/ |
| **Category** | Computer Management |
| **Show this as a featured app in Company Portal** | No |
| **Logo** | Upload Python logo (optional) |

## Program

| Field | Value |
|-------|-------|
| **Install command** | `install.cmd` |
| **Uninstall command** | `uninstall.cmd` |
| **Install behavior** | System |
| **Device restart behavior** | No specific action |
| **Return codes** | Default (0=Success, 1707=Success, 3010=Soft reboot, 1641=Hard reboot, 1618=Retry) |

## Requirements

| Field | Value |
|-------|-------|
| **Operating system architecture** | x64 |
| **Minimum operating system** | Windows 10 1809 |
| **Disk space required (MB)** | 100 |
| **Physical memory required (MB)** | 512 |
| **Minimum number of logical processors required** | 1 |
| **Minimum CPU speed required (MHz)** | 1000 |

## Detection rules

### Primary Detection Rule (Registry)
- **Rules format**: Manually configure detection rules
- **Rule type**: Registry
- **Key path**: `HKEY_LOCAL_MACHINE\SOFTWARE\YourCompany\IntuneApps`
- **Value name**: `Python314`
- **Detection method**: String comparison
- **Operator**: Equals
- **Value**: `Installed`
- **Associated with a 32-bit app on 64-bit clients**: No

### Alternative Detection Rule (File)
- **Rule type**: File
- **Path**: `C:\Program Files\Python314`
- **File or folder**: `python.exe`
- **Detection method**: File or folder exists
- **Associated with a 32-bit app on 64-bit clients**: No

### Advanced Detection Rule (PowerShell)
- **Rule type**: Use a custom detection script
- **Script file**: Upload `detect.ps1`
- **Run script as 32-bit process on 64-bit clients**: No
- **Enforce script signature check**: No

## Dependencies
None required

## Supersedence
Configure if replacing an older Python version

## Assignments

### Available for enrolled devices
- **Group type**: Device group
- **Include**: Select device groups that should have Python available
- **Exclude**: None (unless specific exclusions needed)

### Required for enrolled devices  
- **Group type**: Device group
- **Include**: Select device groups that must have Python installed
- **Exclude**: None (unless specific exclusions needed)
- **Make this app required regardless of platform**: No
- **Delivery optimization priority**: Not configured

## Installation Timeline
- **Install deadline**: Select appropriate deadline for required installations
- **Grace period**: 4 hours (adjustable)
- **Restart grace period**: 4 hours (adjustable)

## User Experience
- **User notifications**: Show all toast notifications
- **User experience**: Available install / Required install
- **Allow users to repair the app**: Yes
- **Installation time required (minutes)**: 15

## Scope Tags
Configure according to your organization's scope tag strategy