# Adobe Acrobat Reader DC - Intune Configuration Guide

## Package Information

- **File:** install-enhanced.intunewin
- **Size:** 4.87 GB
- **Edition:** Adobe Acrobat Reader DC (NO Pro license required)
- **Version:** Latest with security updates (includes 1.14 GB patch)
- **Security:** 34 lockdown settings applied

---

## CRITICAL: Use MSI Detection (Not Custom Script)

When configuring this app in Intune, you MUST use the built-in MSI detection method instead of a custom PowerShell script.

---

## Step-by-Step Configuration in Intune

### 1. App Information
- **Name:** Adobe Acrobat Reader DC (Locked Down)
- **Description:** Adobe Acrobat Reader DC with all cloud/AI/JavaScript/telemetry disabled. Latest security updates included. No Pro license required.
- **Publisher:** Adobe Systems

### 2. Program Configuration

**Install command:**
```
install-enhanced.cmd
```

**Uninstall command:**
```
msiexec /x {8E8DCD43-1A9F-45CF-88FE-8F57CB4C5677} /qn
```

**Install behavior:** System

**Device restart behavior:** Determine behavior based on return codes

---

### 3. Return Codes ⚠️ IMPORTANT

Add these return codes (if not already present):

| Return Code | Code Type                    |
|-------------|------------------------------|
| 0           | Success                      |
| 3010        | Soft reboot                  |
| 1707        | Success                      |
| 1641        | Hard reboot                  |

---

### 4. Detection Rules ⚠️ THIS IS THE KEY FIX

**Rule format:** MSI

**MSI product code:**
```
{8E8DCD43-1A9F-45CF-88FE-8F57CB4C5677}
```

**❌ DO NOT use "Use a custom detection script"**

**✅ USE "MSI" detection type**

---

### 5. Requirements

**Operating system architecture:**
- ☑ 64-bit

**Minimum operating system:**
- Windows 10 1607

**Disk space required:** 5120 MB (5 GB)

**Physical memory required:** (leave blank or use 2048 MB)

**Number of processors required:** (leave blank or use 1)

**CPU speed required:** (leave blank)

---

### 6. Assignments

Assign to your target groups:
- Required / Available / Uninstall

---

## Why MSI Detection Is Required

1. **Custom PowerShell scripts can fail** with script errors (0x87D30068)
2. **MSI detection is native to Intune** and more reliable
3. **Product code detection is standard** for MSI packages
4. **No additional dependencies** or execution policies required

---

## Verification After Deployment

Once deployed, verify on the target machine:

### Check Installation
```powershell
# Check if installed via registry
Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{8E8DCD43-1A9F-45CF-88FE-8F57CB4C5677}"

# Get version info
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{8E8DCD43-1A9F-45CF-88FE-8F57CB4C5677}" | Select-Object DisplayName, DisplayVersion
```

### Check Lockdown Settings
```powershell
# Check JavaScript disabled
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" -Name bDisableJavaScript

# Check AI disabled
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" -Name bDisableAI
```

---

## Troubleshooting

If you still get 0x87D30068 error after changing to MSI detection:

1. **Delete the old app** from Intune completely
2. **Create a NEW app** with fresh configuration using MSI detection
3. **Upload the latest package** from Desktop (install-enhanced.intunewin)
4. **Ensure MSI detection is selected** (not custom script)

---

## Package Details

- **File:** install-enhanced.intunewin (on Desktop)
- **Size:** 4.87 GB
- **Edition:** Reader (no Pro license required)
- **Contents:**
  - Acrobat.msi (90 MB) - Base installer
  - AcrobatDCx64Upd2500120756.msp (1142 MB) - Latest security patch
  - 6 CAB files (714 MB total) - Required installation components
  - install-enhanced.cmd - Installation script
  - adobe-disable-cloud-ai.reg - Security lockdown (34 settings)
  
- **Security Lockdowns Applied:**
  - ✓ JavaScript disabled (bDisableJavaScript=1)
  - ✓ Flash disabled (bEnableFlash=0)
  - ✓ AI Assistant disabled (bDisableAI=1)
  - ✓ Acrobat Assistant disabled (bDisableAcrobatAssistant=1)
  - ✓ Cloud services disabled (Document Cloud, Adobe Sign)
  - ✓ Telemetry disabled (bUsageMeasurement=0)
  - ✓ Collaboration disabled
  - ✓ Automatic updates disabled (manage via Intune)
  - Plus 26 additional security settings
