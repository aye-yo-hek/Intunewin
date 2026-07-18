# Adobe Acrobat Reader DC - FIXED Deployment Guide

## 🔧 What Was Fixed

### Previous Errors
1. **Error 1311** - Missing CAB files (RESOLVED: All 6 CAB files verified in package)
2. **Script Errors** - Improper variable expansion (RESOLVED: Fixed delayed expansion syntax)
3. **Error 0x80070643** - Installation failure (RESOLVED: Proper exit code handling)

### Fixes Applied
✅ **CAB File Verification** - Script now validates all 6 required CAB files exist before attempting MSI installation  
✅ **Fixed Delayed Expansion** - Changed `%ERRORLEVEL%` to `!ERRORLEVEL!` for proper variable expansion  
✅ **Exit Code Propagation** - MSI exit codes now properly preserved and returned to Intune  
✅ **Enhanced Logging** - Better error messages showing which step failed and why

---

## 📦 Package Details

**File:** `install-enhanced-FIXED.intunewin`  
**Location:** Desktop (ready to upload)  
**Size:** ~4.87 GB  
**Contains:**
- Acrobat.msi (base Adobe Acrobat DC Reader)
- 6 CAB files (Core, Languages, Extras, Intermediate, Optional, AlfSdPack)
- AcrobatDCx64Upd2500120756.msp (latest security update)
- adobe-disable-cloud-ai.reg (lockdown settings)
- install-enhanced.cmd (FIXED installation script)

---

## 🚀 Deployment Steps

### 1. Upload to Intune
1. Go to **Microsoft Intune Admin Center** → **Apps** → **Windows** → **+ Add**
2. Select **Windows app (Win32)**
3. Upload: `install-enhanced-FIXED.intunewin` from Desktop

### 2. Configure App Information
- **Name:** Adobe Acrobat Reader DC (Enterprise Edition)
- **Description:** Adobe Acrobat Reader DC with security updates and cloud/AI disabled
- **Publisher:** Adobe Systems Incorporated

### 3. Program Settings
**Install command:**
```cmd
install-enhanced.cmd
```

**Uninstall command:**
```cmd
msiexec /x {AC76BA86-7AD7-1033-7B44-AC0F074E4100} /qn
```

**Install behavior:** System  
**Device restart behavior:** Determine behavior based on return codes

### 4. Requirements
- **Operating system architecture:** 64-bit
- **Minimum OS:** Windows 10 1607

### 5. Detection Rules
**Rule format:** MSI  
**MSI product code:** `{AC76BA86-7AD7-1033-7B44-AC0F074E4100}`

⚠️ **IMPORTANT:** Use MSI detection, NOT custom PowerShell scripts

### 6. Return Codes
Keep default return codes:
- `0` = Success
- `1707` = Success
- `3010` = Soft reboot
- `1641` = Hard reboot
- `1618` = Retry

### 7. Assign to Groups
- Select target device or user groups
- **Intent:** Required (for mandatory deployment)

---

## ✅ Verification

After deployment completes successfully, verify:

1. **Application Installed:**
   ```powershell
   Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "*Adobe Acrobat*"}
   ```

2. **Registry Lockdown Applied:**
   ```powershell
   Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown" -Name bDisableJavaScript
   # Should return: 1
   ```

3. **Cloud Services Disabled:**
   ```powershell
   Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cCloud" -Name bAdobeSendPluginToggle
   # Should return: 0
   ```

---

## 🔍 Troubleshooting

If deployment still fails:

1. **Check Intune Logs:**
   - Device: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`
   - Install log: `%TEMP%\Acrobat.msi.install.log`

2. **Common Issues:**
   - **0x87D1041C** - Detection rule failed → Verify MSI product code
   - **0x80070643** - Still failing → Check install log for MSI-specific errors
   - **Script timeout** - Large package needs time to download

3. **Test Locally First:**
   ```cmd
   # Extract package contents and run:
   cd C:\IntuneWin\msi-builders\msi-with-mst\source
   install-enhanced.cmd
   # Check exit code:
   echo %ERRORLEVEL%
   ```

---

## 📋 What the Script Does

### Step 1: Pre-Install Validation
- Verifies MSI file exists
- **NEW:** Validates all 6 CAB files are present
- Lists all files being used

### Step 2: Base Installation
- Installs Adobe Acrobat DC Reader (MSI)
- Logs to `%TEMP%\Acrobat.msi.install.log`
- **FIXED:** Properly captures and returns exit codes

### Step 3: Apply Update Patch
- Installs AcrobatDCx64Upd2500120756.msp
- Logs to `%TEMP%\Acrobat.msi.install.log.patch`
- Continues even if patch fails (non-critical)

### Step 4: Security Lockdown
- Imports adobe-disable-cloud-ai.reg
- Disables: JavaScript, Flash, Cloud, AI, Telemetry
- Warnings logged if registry import fails

---

## 🎯 Expected Deployment Timeline

1. **Download** (~5-10 min for 4.87 GB package)
2. **Install MSI** (~3-5 min)
3. **Apply Patch** (~2-3 min)
4. **Registry Import** (~5 sec)

**Total:** ~10-20 minutes depending on network speed

---

## 📝 Notes

- Package does NOT require Adobe Pro license (Reader edition only)
- All cloud and AI features disabled by default after deployment
- No user interaction required (silent install)
- Detection uses MSI product code (most reliable method)
- Script includes detailed logging for troubleshooting
- Exit codes properly returned to Intune for reporting

---

## 🆘 Support

If issues persist after using the FIXED package:
1. Check install logs at `%TEMP%\Acrobat.msi.install.log`
2. Test script locally before deploying via Intune
3. Verify all CAB files are in package (script will check automatically)
4. Ensure MSI detection rule uses correct product code

---

**Last Updated:** December 30, 2025  
**Package Version:** install-enhanced-FIXED  
**Status:** Ready for Production Deployment
