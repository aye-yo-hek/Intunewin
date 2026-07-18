# Intune Win32 App Configuration Template

Use this template when configuring the .NET SDK app in Microsoft Intune.

## Basic Information

| Field | Value |
|-------|-------|
| **Name** | .NET SDK 8.0.423 (win-x64) |
| **Description** | .NET SDK 8.0.423 - includes the .NET Runtime, ASP.NET Core Runtime, and command-line build tools (dotnet CLI, MSBuild, NuGet). |
| **Publisher** | Microsoft Corporation |
| **Information URL** | https://dotnet.microsoft.com/ |
| **Privacy URL** | https://privacy.microsoft.com/ |
| **Category** | Developer Tools |
| **Show this as a featured app in Company Portal** | No |
| **Logo** | Upload .NET logo (optional) |

## Program

| Field | Value |
|-------|-------|
| **Install command** | `install.cmd` |
| **Uninstall command** | `uninstall.cmd` |
| **Install behavior** | System |
| **Device restart behavior** | No specific action |
| **Return codes** | Default (0=Success, 1707=Success, 3010=Soft reboot, 1641=Hard reboot, 1618=Retry) |

Underlying installer commands (what `install.cmd`/`uninstall.cmd` actually run):
```
install:   dotnet-sdk-8.0.423-win-x64.exe /install /quiet /norestart
uninstall: dotnet-sdk-8.0.423-win-x64.exe /uninstall /quiet /norestart
```

## Requirements

| Field | Value |
|-------|-------|
| **Operating system architecture** | x64 |
| **Minimum operating system** | Windows 10 1809 |
| **Disk space required (MB)** | 1024 |
| **Physical memory required (MB)** | 512 |
| **Minimum number of logical processors required** | 1 |
| **Minimum CPU speed required (MHz)** | 1000 |

## Detection rules

### Detection Rule (PowerShell - this is the one actually used)
- **Rule type**: Use a custom detection script
- **Script file**: Upload `detect.ps1`
- **Run script as 32-bit process on 64-bit clients**: No
- **Enforce script signature check**: No
- **What it checks**: `C:\Program Files\dotnet\sdk\8.0.423\dotnet.dll` exists
  (Microsoft's own recommended detection signal for a specific SDK version)

### Alternative Detection Rule (File, if you'd rather not use a script)
- **Rule type**: File
- **Path**: `C:\Program Files\dotnet\sdk\8.0.423`
- **File or folder**: `dotnet.dll`
- **Detection method**: File or folder exists
- **Associated with a 32-bit app on 64-bit clients**: No

## Dependencies
None required

## Supersedence
Configure if replacing an older .NET SDK version (e.g. superseding a prior 8.0.x SDK build)

## Assignments

### Available for enrolled devices
- **Group type**: Device group
- **Include**: Select device groups that should have the .NET SDK available
- **Exclude**: None (unless specific exclusions needed)

### Required for enrolled devices
- **Group type**: Device group
- **Include**: Select device groups (e.g. developer workstations) that must have it installed
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
- **Installation time required (minutes)**: 10

## Scope Tags
Configure according to your organization's scope tag strategy

## Package
- **File**: `Apps\DotNetSDK\Output\DotNetSDK_2026-07-17.intunewin`
- **Size**: 213.76 MB
- **Verified**: valid .intunewin (zip) header, built 2026-07-17
