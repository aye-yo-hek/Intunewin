# Intune Deployment Guide

Step-by-step guide for uploading and configuring a `.intunewin` package in Microsoft Intune.

## Upload to Intune

1. Go to [Microsoft Intune admin center](https://intune.microsoft.com)
2. Navigate to **Apps** > **All apps** > **Add**
3. Select **App type** = **Windows app (Win32)**
4. Click **Select**

## App Information

| Field | Value |
|-------|-------|
| Name | Your application name |
| Description | Brief description of the app |
| Publisher | Publisher name |

Upload your `.intunewin` file from the `output/` folder.

## Program Settings

| Setting | Value |
|---------|-------|
| Install command | `install.cmd` |
| Uninstall command | `uninstall.cmd` |
| Install behavior | **System** |
| Device restart behavior | **App install may force a device restart** |

## Requirements

| Setting | Value |
|---------|-------|
| OS architecture | **64-bit** |
| Minimum OS | **Windows 10 1607** (or your requirement) |

## Detection Rules

| Setting | Value |
|---------|-------|
| Rule format | **Use a custom detection script** |
| Script file | Upload `detect.ps1` from your app folder |
| Run script as 32-bit | **No** |
| Enforce script signature check | **No** |

## Return Codes

| Code | Type |
|------|------|
| 0 | Success |
| 1707 | Success |
| 3010 | Soft reboot |
| 1641 | Hard reboot |
| 1618 | Retry |

## Assignments

1. Click **Add group** under **Required** or **Available for enrolled devices**
2. Select your target device/user groups
3. Click **Review + create**

## Monitoring

- Go to **Apps** > **Monitor** > **App install status**
- Check individual device status under **Device install status**
- Review logs at `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\` on target devices
