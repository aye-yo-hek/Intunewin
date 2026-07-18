# Xerox Global Print Driver PCL6 - Intune Deployment Guide

## Package Info
| Item | Value |
|------|-------|
| **Driver** | Xerox Global Print Driver PCL6 |
| **Driver Version** | 5.1076.3.0 |
| **INF File** | x3UNIVX.inf |
| **Package** | `packages\XeroxPrinter\Install-Printer.intunewin` |

## Printers to Deploy

| Printer Name | IP Address | Port Name |
|-------------|------------|-----------|
| XeroxVersaLink4036 | 10.20.32.35 | Port_10.20.32.35 |
| XeroxVersaLink4035 | 10.20.4.207 | Port_10.20.4.207 |

> **Note:** You need to create **two separate Win32 app deployments** in Intune — one for each printer — using the **same .intunewin package** but with different install/uninstall commands.

---

## Intune Win32 App Configuration

### App 1: XeroxVersaLink4036 (10.20.32.35)

#### App Information Tab
| Field | Value |
|-------|-------|
| Name | Xerox VersaLink 4036 Printer |
| Description | Xerox Global Print Driver PCL6 - XeroxVersaLink4036 at 10.20.32.35 |
| Publisher | Xerox |

#### Program Tab
| Field | Value |
|-------|-------|
| **Install command** | `powershell.exe -executionpolicy bypass -file Install-Printer.ps1 -PrinterIP "10.20.32.35" -PrinterName "XeroxVersaLink4036" -InfPath ".\Driver\x3UNIVX.inf" -DriverName "Xerox Global Print Driver PCL6"` |
| **Uninstall command** | `powershell.exe -executionpolicy bypass -file Uninstall-Printer.ps1 -PrinterName "XeroxVersaLink4036" -PrinterIP "10.20.32.35"` |
| Install behavior | **System** |
| Device restart behavior | No specific action |
| Return codes | Keep defaults |

#### Requirements Tab
| Field | Value |
|-------|-------|
| OS Architecture | **64-bit** |
| Minimum OS | **Windows 10 1607** |

#### Detection Rules Tab
| Field | Value |
|-------|-------|
| Rule type | **Registry** |
| Key path | `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers\XeroxVersaLink4036` |
| Value name | `Name` |
| Detection method | **String comparison** |
| Operator | **Equals** |
| Value | `XeroxVersaLink4036` |
| Associated with 32-bit app on 64-bit clients | **No** |

---

### App 2: XeroxVersaLink4035 (10.20.4.207)

#### App Information Tab
| Field | Value |
|-------|-------|
| Name | Xerox VersaLink 4035 Printer |
| Description | Xerox Global Print Driver PCL6 - XeroxVersaLink4035 at 10.20.4.207 |
| Publisher | Xerox |

#### Program Tab
| Field | Value |
|-------|-------|
| **Install command** | `powershell.exe -executionpolicy bypass -file Install-Printer.ps1 -PrinterIP "10.20.4.207" -PrinterName "XeroxVersaLink4035" -InfPath ".\Driver\x3UNIVX.inf" -DriverName "Xerox Global Print Driver PCL6"` |
| **Uninstall command** | `powershell.exe -executionpolicy bypass -file Uninstall-Printer.ps1 -PrinterName "XeroxVersaLink4035" -PrinterIP "10.20.4.207"` |
| Install behavior | **System** |
| Device restart behavior | No specific action |
| Return codes | Keep defaults |

#### Requirements Tab
| Field | Value |
|-------|-------|
| OS Architecture | **64-bit** |
| Minimum OS | **Windows 10 1607** |

#### Detection Rules Tab
| Field | Value |
|-------|-------|
| Rule type | **Registry** |
| Key path | `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers\XeroxVersaLink4035` |
| Value name | `Name` |
| Detection method | **String comparison** |
| Operator | **Equals** |
| Value | `XeroxVersaLink4035` |
| Associated with 32-bit app on 64-bit clients | **No** |

---

## Step-by-Step Deployment Instructions

1. Sign in to the **Intune Admin Center** → Apps → All Apps
2. Click **+ Create** → Select **Windows app (Win32)**
3. **Select app package file** → Browse to `packages\XeroxPrinter\Install-Printer.intunewin`
4. Fill in the **App Information** tab (see tables above)
5. Fill in the **Program** tab with the install/uninstall commands for the specific printer
6. Set **Requirements** (64-bit, Windows 10 1607+)
7. Add **Detection Rule** (Registry-based, see tables above)
8. Skip **Supersedence** and **Dependencies**
9. **Assignments** → Assign to your target device group
10. **Review + Create** → Click **Create**
11. Repeat steps 2–10 for the second printer

## Troubleshooting

- Logs are written to: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\Install-Printer.log`
- Verify driver staged: Check `C:\Windows\System32\DriverStore\FileRepository` for a folder matching `x3univx.inf_*`
- Verify port created: Run `Get-PrinterPort | Where-Object { $_.Name -like "Port_10.20.*" }`
- Verify printer installed: Run `Get-Printer | Where-Object { $_.Name -like "XeroxVersaLink*" }`

## Force Sync

To test immediately on a device:
- Settings → Accounts → Access work or school → Click your account → Info → Sync
- Or run: `Get-ScheduledTask | Where-Object { $_.TaskName -eq 'PushLaunch' } | Start-ScheduledTask`
