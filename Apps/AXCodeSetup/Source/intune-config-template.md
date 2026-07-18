# Intune Win32 App Configuration Template for AXCodeSetup

Use this template when configuring the AXCodeSetup app in Microsoft Intune.

## Basic Information
| Field | Value |
|-------|-------|
| **Name** | AXCodeSetup |
| **Description** | AXCodeSetup application |
| **Publisher** | [Your Publisher] |
| **Category** | [Choose appropriate category] |
| **Show as featured app** | No |

## Program
| Field | Value |
|-------|-------|
| **Install command** | install.cmd |
| **Uninstall command** | uninstall.cmd |
| **Install behavior** | System |
| **Device restart behavior** | No specific action |
| **Return codes** | Default (0=Success, 1707=Success, 3010=Soft reboot, 1641=Hard reboot, 1618=Retry) |

## Requirements
| Field | Value |
|-------|-------|
| **Operating system architecture** | x64 |
| **Minimum operating system** | Windows 10 1809 |
| **Disk space required (MB)** | [Specify] |
| **Physical memory required (MB)** | [Specify] |
| **Minimum number of logical processors required** | 1 |
| **Minimum CPU speed required (MHz)** | 1000 |

## Detection rules
### Primary Detection Rule (Registry)
- **Rule type**: Registry
- **Key path**: `HKEY_LOCAL_MACHINE\SOFTWARE\YourCompany\IntuneApps`
- **Value name**: `AXCodeSetup`
- **Detection method**: String comparison
- **Operator**: Equals
- **Value**: Installed
- **Associated with a 32-bit app on 64-bit clients**: No

### Alternative Detection Rule (File)
- **Rule type**: File
- **Path**: `C:\Program Files\AXCodeSetup`
- **File or folder**: `axcodesetup.exe`
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
Configure if replacing an older version

## Assignments
- Assign to device groups as required

## Installation Timeline
- **Install deadline**: Set as needed
- **Grace period**: Set as needed
- **Restart grace period**: Set as needed

## User Experience
- **User notifications**: Show all toast notifications
- **User experience**: Available install / Required install
- **Allow users to repair the app**: Yes
- **Installation time required (minutes)**: [Specify]

## Scope Tags
Configure according to your organization's scope tag strategy