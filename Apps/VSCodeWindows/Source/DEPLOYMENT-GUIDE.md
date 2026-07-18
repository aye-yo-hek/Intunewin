# VS Code 1.113.0 - Intune Win32 App Deployment Guide (Windows)

## Package Info
| Item | Value |
|------|-------|
| **Application** | Visual Studio Code |
| **Version** | 1.113.0 |
| **Installer** | VSCodeSetup-x64-1.113.0.exe (Inno Setup) |
| **Package** | `packages\VSCodeSetup-x64-1.113.0.intunewin` |

---

## Intune Win32 App Configuration

### App Information Tab
| Field | Value |
|-------|-------|
| Name | Visual Studio Code 1.113.0 |
| Description | Visual Studio Code x64 - version 1.113.0 |
| Publisher | Microsoft |
| App version | 1.113.0 |

### Program Tab
| Field | Value |
|-------|-------|
| **Install command** | `VSCodeSetup-x64-1.113.0.exe /VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,addtopath` |
| **Uninstall command** | `"C:\Program Files\Microsoft VS Code\unins000.exe" /VERYSILENT /NORESTART` |
| Install behavior | **System** |
| Device restart behavior | No specific action |
| Return codes | Keep defaults |

> **Note:** The `/MERGETASKS` flags add right-click context menu entries and add VS Code to PATH. Remove `addcontextmenufiles,addcontextmenufolders,addtopath` if not needed.

### Requirements Tab
| Field | Value |
|-------|-------|
| OS Architecture | **64-bit** |
| Minimum OS | **Windows 10 1607** |

### Detection Rules Tab (Version-Based - Recommended for Upgrades)
| Field | Value |
|-------|-------|
| Rule type | **File** |
| Path | `C:\Program Files\Microsoft VS Code` |
| File or folder | `Code.exe` |
| Detection method | **String (version)** |
| Operator | **Greater than or equal to** |
| Value | `1.113.0` |
| Associated with 32-bit app on 64-bit clients | **No** |

> **Important:** Using version-based detection ensures Intune will push the installer when devices have an older version. If you only check that `Code.exe` exists, upgrades will not be deployed.

---

## Step-by-Step Deployment Instructions

1. Sign in to the **Intune Admin Center** → Apps → All Apps
2. Click **+ Create** → Select **Windows app (Win32)**
3. **Select app package file** → Browse to `packages\VSCodeSetup-x64-1.113.0.intunewin`
4. Fill in the **App Information** tab (see table above)
5. Fill in the **Program** tab with the install/uninstall commands
6. Set **Requirements** (64-bit, Windows 10 1607+)
7. Add **Detection Rule** (File version-based, see table above)
8. Skip **Supersedence** and **Dependencies**
9. **Assignments** → Assign to your target device group
10. **Review + Create** → Click **Create**

---

## Upgrading to a New Version

When a new VS Code version is released (e.g., 1.114.0):

1. Download the new `VSCodeSetup-x64-1.114.0.exe` into `src\VSCodeUpdates`
2. Repackage:
   ```powershell
   & "packaging\IntuneWinAppUtil.exe" -c "src\VSCodeUpdates" -s "VSCodeSetup-x64-1.114.0.exe" -o "packages" -q
   ```
3. In Intune, edit the existing VS Code app:
   - Upload the new `.intunewin` package
   - Update the **Install command** filename to `VSCodeSetup-x64-1.114.0.exe`
   - Update the **Detection rule** version to `1.114.0`
4. Intune will detect the older version on devices and push the upgrade automatically

---

## Optional: Enable Auto-Updates via Policy

Deploy the auto-update policy (also in this folder) so VS Code updates itself between Intune pushes:

| Field | Value |
|-------|-------|
| Install command | `install.cmd` |
| Uninstall command | `uninstall.cmd` |
| Detection | Custom script → `detect.ps1` |

This sets `HKLM\SOFTWARE\Policies\Microsoft\Code\UpdateMode` to `default`, enabling VS Code's built-in auto-updater.

---

## Troubleshooting

- **Intune logs:** `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`
- **Verify install:** Run `Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{EA457B21-F73E-494C-ACAB-524FDE069978}_is1"` 
- **Verify version:** Run `(Get-Item "C:\Program Files\Microsoft VS Code\Code.exe").VersionInfo.ProductVersion`
- **Force sync:** Settings → Accounts → Access work or school → Info → Sync

## Force Sync

To test immediately on a device:
- Settings → Accounts → Access work or school → Click your account → Info → Sync
- Or run: `Get-ScheduledTask | Where-Object { $_.TaskName -eq 'PushLaunch' } | Start-ScheduledTask`
