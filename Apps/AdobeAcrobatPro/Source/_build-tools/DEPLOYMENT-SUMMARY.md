# Adobe Acrobat Pro DC - Intune Deployment Summary

## ✅ Testing Complete

All deployment methods have been validated and are ready for Intune deployment.

---

## Application Details

- **Product Name**: Adobe Acrobat DC (64-bit)
- **Version**: 21.001.20135
- **Product Code**: `{AC76BA86-1033-FFFF-7760-BC15014EA700}`
- **MSI Size**: 12.59 MB
- **MST Size**: 60 KB
- **Merged MSI Size**: 12.61 MB

---

## Deployment Methods

### Method 1: Bundle MSI + MST Together (Recommended)

**Files**: `source\AcroPro.msi` + `source\AcroPro.mst` + `source\install.cmd`

**Steps to Deploy**:

1. **Package for Intune**:
   ```powershell
   IntuneWinAppUtil.exe -c ".\source" -s "install.cmd" -o ".\intune-packages"
   ```

2. **Upload to Intune**:
   - Apps → Windows → Add → Windows app (Win32)
   - Upload the `.intunewin` file

3. **Configure Installation**:
   ```
   Install command:   install.cmd
   Uninstall command: msiexec /x {AC76BA86-1033-FFFF-7760-BC15014EA700} /qn
   Install behavior:  System
   ```

4. **Detection Rules** (choose one):

   **Option A: MSI Product Code (Recommended)**
   ```
   Rule type: MSI
   Product code: {AC76BA86-1033-FFFF-7760-BC15014EA700}
   ```

   **Option B: File Detection**
   ```
   Path: C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe
   File or folder: File
   Detection method: File or folder exists
   ```

   **Option C: Registry Detection**
   ```
   Key: HKLM\SOFTWARE\Adobe\Adobe Acrobat\DC
   Value: (check for version or install path)
   ```

5. **Requirements**:
   ```
   OS architecture: 64-bit
   Minimum OS: Windows 10 1607
   ```

6. **Assign** to device groups

---

### Method 2: Single Merged MSI

**File**: `output\AcroPro-Merged.msi`

**Steps to Deploy**:

1. **Package for Intune** (if using Win32 app):
   ```powershell
   IntuneWinAppUtil.exe -c ".\output" -s "AcroPro-Merged.msi" -o ".\intune-packages"
   ```

   **OR upload directly** as Line-of-Business app (LOB)

2. **Upload to Intune**:
   - **Win32 App**: Apps → Windows → Add → Windows app (Win32)
   - **LOB App**: Apps → Windows → Add → Line-of-business app

3. **Configure Installation**:
   ```
   Install command:   msiexec /i AcroPro-Merged.msi /qn /norestart
   Uninstall command: msiexec /x {AC76BA86-1033-FFFF-7760-BC15014EA700} /qn
   ```

4. **Detection Rules**: Same as Method 1

5. **Assign** to device groups

---

## Test Results

✅ **All Tests Passed (6/6)**

- ✅ Source Files: PASS
- ✅ Install Script: PASS
- ✅ MSI Structure: PASS
- ✅ Method 1 (Bundle): PASS
- ✅ Method 2 (Merge): PASS
- ✅ Detection Script: PASS

---

## Files Ready for Deployment

### Method 1 (Bundle)
```
source/
├── AcroPro.msi          ✅ Ready
├── AcroPro.mst          ✅ Ready
└── install.cmd          ✅ Configured
```

### Method 2 (Merge)
```
output/
└── AcroPro-Merged.msi   ✅ Ready
```

### Support Files
```
├── uninstall.cmd        ✅ Configured with Product Code
├── detect.ps1           ✅ Ready (optional)
└── Test-Deployment.ps1  ✅ Validation passed
```

---

## Installation Commands

### Silent Install (Bundle Method)
```cmd
install.cmd
```
or manually:
```cmd
msiexec /i AcroPro.msi TRANSFORMS=AcroPro.mst /qn /norestart /l*v C:\Temp\acropro-install.log
```

### Silent Install (Merged Method)
```cmd
msiexec /i AcroPro-Merged.msi /qn /norestart /l*v C:\Temp\acropro-install.log
```

### Silent Uninstall
```cmd
msiexec /x {AC76BA86-1033-FFFF-7760-BC15014EA700} /qn /norestart
```

---

## Intune Configuration Summary

| Setting | Value |
|---------|-------|
| **App Name** | Adobe Acrobat DC (64-bit) |
| **Install Command** | `install.cmd` (Method 1) or `msiexec /i AcroPro-Merged.msi /qn /norestart` (Method 2) |
| **Uninstall Command** | `msiexec /x {AC76BA86-1033-FFFF-7760-BC15014EA700} /qn` |
| **Install Behavior** | System |
| **Restart Behavior** | No specific action |
| **Detection Rule** | MSI Product Code: `{AC76BA86-1033-FFFF-7760-BC15014EA700}` |
| **OS Architecture** | 64-bit |
| **Min OS Version** | Windows 10 1607 |

---

## Advantages of Each Method

### Method 1: Bundle (MSI + MST)

**Pros**:
- ✅ Keep original MSI and MST separate
- ✅ Easy to update MST without changing MSI
- ✅ Can maintain multiple transform versions
- ✅ Better for testing different configurations

**Cons**:
- ❌ Slightly more complex (3 files vs 1)
- ❌ Requires wrapper script

**Best For**:
- Organizations that need flexibility
- Multiple deployment configurations
- Testing and staging environments

### Method 2: Merged MSI

**Pros**:
- ✅ Single file deployment
- ✅ Simpler to manage
- ✅ Can use LOB app deployment
- ✅ Standard MSI workflow

**Cons**:
- ❌ Must recreate merged MSI if transform changes
- ❌ Less flexible

**Best For**:
- Production deployments
- Organizations preferring simplicity
- When transforms rarely change

---

## Troubleshooting

### Installation Logs

Logs are created automatically at:
```
%TEMP%\AcroPro.msi.install.log (Bundle method)
C:\Temp\acropro-install.log (Manual installation)
```

### Common Issues

**Issue**: Installation fails with error 1603
- **Solution**: Check if older version is installed, uninstall first

**Issue**: MST not applying
- **Solution**: Verify MST is in same directory as MSI

**Issue**: Detection not working
- **Solution**: Check Product Code matches: `{AC76BA86-1033-FFFF-7760-BC15014EA700}`

### Intune Logs

Check deployment status in Intune:
```
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log
```

---

## Next Steps

1. **Choose deployment method** (Method 1 or Method 2)
2. **Package with IntuneWinAppUtil** (if not already done)
3. **Upload to Intune portal**
4. **Configure detection rules**
5. **Test with pilot group** (recommended)
6. **Deploy to production groups**
7. **Monitor deployment status** in Intune portal

---

## Validation Commands

Run these to verify deployment readiness:

```powershell
# Re-run validation tests
cd C:\IntuneWin\msi-builders\msi-with-mst
.\Test-Deployment.ps1

# Verify files exist
Test-Path .\source\AcroPro.msi
Test-Path .\source\AcroPro.mst
Test-Path .\source\install.cmd
Test-Path .\output\AcroPro-Merged.msi

# Check Product Code
$installer = New-Object -ComObject WindowsInstaller.Installer
$db = $installer.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $installer, @(".\source\AcroPro.msi", 0))
# View in Orca or InstEd for details
```

---

**Created**: November 24, 2025  
**Status**: ✅ Ready for Intune Deployment  
**Tested**: Both methods validated successfully  
**Application**: Adobe Acrobat DC (64-bit) v21.001.20135
