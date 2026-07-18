# Intune Win32 App Configuration Guide
## Following Andrew Taylor's Best Practices

This guide explains how to properly configure the Win32 apps in Microsoft Intune using the corrected packages.

---

## Package Overview

### Available Packages:
- **AXCodeSetup.intunewin** (146.97 MB) - AX Code editor
- **Python314-v2.intunewin** (28.27 MB) - Python 3.14 for all users

---

## AXCodeSetup Configuration

### Basic Information
- **Name:** AX Code
- **Description:** AX Code editor for development
- **Publisher:** AX Technologies
- **App Version:** Latest

### Program Settings
- **Install command:** `install.cmd`
- **Uninstall command:** `uninstall.cmd`
- **Install behavior:** System
- **Device restart behavior:** No specific action

### Requirements
- **Operating system:** Windows 10 1607 or later
- **Architecture:** x64
- **Minimum RAM:** 512 MB
- **Disk space:** 200 MB

### Detection Rule
**Type:** Custom script
**Script file:** `detect.ps1` (PowerShell detection script)

**Manual Detection Rule Alternative:**
- **Rule type:** File
- **Path:** `%LOCALAPPDATA%\Programs\AX Code`
- **File or folder:** `AX Code.exe`
- **Detection method:** File or folder exists

### Dependencies
None required

### Return Codes
- **0:** Success
- **1:** General failure
- **1641:** Success (restart required)
- **3010:** Success (soft restart required)

---

## Python 3.14 Configuration

### Basic Information
- **Name:** Python 3.14
- **Description:** Python 3.14 for all users with PATH integration
- **Publisher:** Python Software Foundation
- **App Version:** 3.14.0

### Program Settings
- **Install command:** `install.cmd`
- **Uninstall command:** `uninstall.cmd`
- **Install behavior:** System
- **Device restart behavior:** No specific action

### Requirements
- **Operating system:** Windows 10 1607 or later
- **Architecture:** x64
- **Minimum RAM:** 256 MB
- **Disk space:** 100 MB

### Detection Rule
**Type:** Manual detection rule
- **Rule type:** File
- **Path:** `%ProgramFiles%\Python314`
- **File or folder:** `python.exe`
- **Detection method:** File or folder exists

### Dependencies
None required

### Return Codes
- **0:** Success
- **1:** General failure
- **1641:** Success (restart required)
- **3010:** Success (soft restart required)

---

## Key Improvements Made

Following Andrew Taylor's article recommendations:

1. **Simplified Folder Structure**
   - Source files moved into each app's directory
   - No dependency on external "exe files" folder
   - Clean, self-contained packages

2. **Streamlined Install Commands**
   - Removed complex error checking and registry manipulation
   - Direct executable calls with silent parameters
   - Follows "keep it simple" principle

3. **Reliable Detection Methods**
   - File-based detection instead of custom registry entries
   - Standard installation path checking
   - Reduced complexity and failure points

4. **Proper Silent Installation Parameters**
   - **AXCode:** `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-` (Inno Setup)
   - **Python:** `/quiet InstallAllUsers=1 PrependPath=1` (Windows Installer)

---

## Upload and Deployment Steps

1. **Upload Packages**
   - Navigate to Microsoft Endpoint Manager admin center
   - Go to Apps > Windows > Add
   - Select "Windows app (Win32)"
   - Upload the respective .intunewin files

2. **Configure Settings**
   - Use the configuration details above
   - Test deployment to a pilot group first
   - Monitor installation status in Intune

3. **Troubleshooting**
   - Check device logs for installation errors
   - Verify detection scripts execute properly
   - Use Intune Company Portal for user-initiated installs

---

## Common Issues Resolved

- **0x80070001 Error:** Fixed by simplifying install scripts and using proper silent parameters
- **Detection Failures:** Resolved by switching to file-based detection methods
- **Path Dependencies:** Eliminated by moving source files to app directories
- **Complex Scripts:** Simplified to basic executable calls per best practices

The packages now follow industry best practices and should deploy reliably through Microsoft Intune.