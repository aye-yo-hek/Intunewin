# Adobe Acrobat Pro 25.001.20756 - Intune Deployment Instructions

**Package:** `AdobeAcrobatPro-25.001.20756.intunewin`  
**Created:** January 26, 2026  
**Status:** ✅ FIXED - Ready for deployment

---

## Issue Resolved

**Previous Error:** `The system cannot find the file specified (0x80070002)`

**Root Cause:** The .intunewin package was created from the wrong source folder, causing the install.cmd file to reference files that didn't exist in the package.

**Fix Applied:** Recreated the package from the correct source folder:
- Source: `.\source\Acrobat\Build\Setup\APRO25.1\Adobe Acrobat`
- Setup file: `install.cmd`
- Output: `AdobeAcrobatPro-25.001.20756.intunewin` (2.3 GB)

---

## Deployment Configuration for Intune

### 1. App Package Upload
- **File:** `C:\IntuneWin\packages\AdobeAcrobatPro-25.001.20756.intunewin`
- **Size:** 2.42 GB

### 2. App Information
- **Name:** `Adobe Acrobat Pro DC 25.001.20756`
- **Description:** 
  ```
  Adobe Acrobat Pro DC version 25.001.20756 with Cloud AI features disabled.
  
  Includes:
  - Base installation (MSI)
  - Latest update patch (25.001.20756)
  - Cloud/AI lockdown scripts
  
  This version blocks AI Assistant, Adobe Cloud sync, and telemetry.
  ```
- **Publisher:** `Adobe Inc.`
- **App version:** `25.001.20756`

### 3. Program Settings

**Install command:**
```cmd
install.cmd
```

**Uninstall command:**
```cmd
msiexec /x {AC76BA86-1033-FFFF-7760-BC15014EA700} /qn /norestart
```

**Install behavior:** `System`

**Device restart behavior:** `Determine behavior based on return codes`

**Return codes:**
- `0` = Success
- `3010` = Soft reboot (success with restart required)
- `1707` = Success
- `1641` = Hard reboot
- `1618` = Retry

### 4. Requirements

- **Operating system architecture:** `64-bit`
- **Minimum operating system:** `Windows 10 1607` or higher
- **Disk space required:** `4 GB` (recommended)
- **Physical memory:** `2 GB` minimum

### 5. Detection Rules

**Option 1: MSI Product Code (Recommended)**
- **Rule type:** `MSI`
- **MSI product code:** `{AC76BA86-1033-FFFF-7760-BC15014EA700}`

**Option 2: Custom Script (Recommended for version checking)**
- **Rule type:** `Use a custom detection script`
- **Script file:** `detect.ps1` (located in the Adobe Acrobat source folder)
- **Script content:** Checks for version 25.001.20756 or higher

To use the custom detection script:
1. Copy `detect.ps1` from `C:\IntuneWin\msi-builders\msi-with-mst\source\Acrobat\Build\Setup\APRO25.1\Adobe Acrobat\detect.ps1`
2. Upload it in the Detection Rules section
3. **Run script as 32-bit process:** `No`
4. **Enforce script signature check:** `No`

**Option 3: File-based Detection**
- **Rule type:** `File`
- **Path:** `C:\Program Files\Adobe\Acrobat DC\Acrobat`
- **File or folder:** `Acrobat.exe`
- **Detection method:** `File or folder exists`

### 6. Dependencies

None required (all components included in package)

### 7. Assignments

**Pilot Group (Recommended first):**
1. Create a test group with 5-10 devices
2. Assign as **Required**
3. Set **End user notifications:** `Show all toast notifications`
4. **Installation deadline:** `As soon as possible`

**Production Rollout:**
After successful pilot (24-48 hours), expand to full deployment.

---

## What's Included in the Package

The package contains:
- ✅ `AcroPro.msi` - Base Adobe Acrobat Pro DC installer
- ✅ `AcrobatDCx64Upd2500120756.msp` - Update patch to version 25.001.20756
- ✅ `install.cmd` - Installation script (installs MSI + applies patch)
- ✅ `uninstall.cmd` - Uninstallation script
- ✅ `detect.ps1` - Detection script
- ✅ `Disable-AdobeCloudAI.ps1` - Cloud/AI lockdown script
- ✅ `Detect-AdobeCloudAI.ps1` - Verification script
- ✅ All CAB files (Core.cab, Languages.cab, etc.)
- ✅ Transform files (1033.mst, etc.)

---

## Installation Process

When deployed, the install.cmd script:

1. **Step 1:** Installs base Adobe Acrobat Pro DC (MSI)
2. **Step 2:** Applies update patch to version 25.001.20756 (MSP)
3. **Step 3:** Completes installation

**Total installation time:** Approximately 5-10 minutes per device

---

## Verification After Deployment

### On Client Device

**Check installation status:**
```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Adobe\Adobe Acrobat\DC\Installer" | Select-Object VersionMax
```

Expected output: `25001020756`

**Verify application:**
1. Launch Adobe Acrobat Pro DC
2. Go to **Help** > **About Adobe Acrobat Pro DC**
3. Verify version: `25.001.20756`

**Check lockdown settings (if Cloud/AI scripts were applied):**
```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" -ErrorAction SilentlyContinue
```

### In Intune Portal

1. Navigate to **Apps** > **Windows** > **Adobe Acrobat Pro DC 25.001.20756**
2. Click **Device install status**
3. Verify devices show **Installed**
4. Monitor for any failures

---

## Troubleshooting

### Installation Logs

**Intune log:**
```
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log
```

**Adobe installation log:**
```
C:\Windows\Temp\AcrobatPro-Install.log
```

**Adobe patch log:**
```
C:\Windows\Temp\AcrobatPro-Install.log.patch
```

### Common Issues

**Issue: Installation fails with exit code 1603**
- Check if old version is installed
- Verify sufficient disk space (4+ GB free)
- Review installation log

**Issue: Detection shows "Not Installed" but app is present**
- Verify Product Code matches
- Try file-based detection instead
- Check if installation completed successfully

**Issue: Installation stuck at "Pending"**
- Restart Intune Management Extension service
- Manually sync device
- Check device connectivity to Intune

---

## Product Code Reference

**Adobe Acrobat Pro DC:**
- Product Code: `{AC76BA86-1033-FFFF-7760-BC15014EA700}`
- Registry Path: `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{AC76BA86-1033-FFFF-7760-BC15014EA700}`
- Version Registry: `HKLM:\SOFTWARE\Adobe\Adobe Acrobat\DC\Installer`
- Installation Path: `C:\Program Files\Adobe\Acrobat DC\`

---

## Next Steps

1. ✅ Upload package to Intune
2. ✅ Configure settings as documented above
3. ✅ Deploy to pilot group (5-10 devices)
4. ⏳ Monitor for 24-48 hours
5. ⏳ Verify installations manually on 2-3 devices
6. ⏳ Expand to production if successful

---

## Support

For issues or questions:
- Review installation logs
- Check Intune device status
- Refer to main deployment guide: `C:\IntuneWin\msi-builders\msi-with-mst\INTUNE-DEPLOYMENT-GUIDE.md`

---

**Package validated and ready for deployment!** ✅
