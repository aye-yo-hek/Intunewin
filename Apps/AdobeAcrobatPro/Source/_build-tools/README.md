# MSI + MST Combiner

This folder helps you combine MSI files with MST (transform) files for deployment via Microsoft Intune.

## What This Does

Combines an MSI installer with an MST transform file into a single deployable package that can be uploaded to Intune as a Win32 app.

## Two Approaches

### 1. Bundle Both Files (Recommended)
Keep MSI and MST separate but deploy together as a Win32 app

### 2. Merge into Single MSI
Use Orca/InstEd to permanently apply the MST to the MSI

---

## Method 1: Bundle MSI + MST Together

### Step 1: Place Your Files

Copy your files to this folder:
```
msi-with-mst/
├── source/
│   ├── YourApp.msi        ← Your MSI file
│   └── YourApp.mst        ← Your MST transform file
```

### Step 2: Customize Install Script

The `install.cmd` script is already configured to apply the MST during installation.

**If your files have different names**, edit `install.cmd`:
```batch
set MSI_FILE=YourApp.msi
set MST_FILE=YourApp.mst
```

### Step 3: Test Locally

```powershell
# Test the installation
.\source\install.cmd

# Test silent install
.\source\install.cmd /quiet
```

### Step 4: Package for Intune

```powershell
# Use IntuneWinAppUtil to create .intunewin package
.\IntuneWinAppUtil.exe -c ".\source" -s "install.cmd" -o ".\output"
```

### Step 5: Upload to Intune

1. **Apps** → **Windows** → **Add** → **Windows app (Win32)**
2. Upload the `.intunewin` file
3. Configure:
   - **Install command**: `install.cmd`
   - **Uninstall command**: `msiexec /x {ProductCode} /qn`
4. Set detection rules
5. Assign to groups

---

## Method 2: Merge MSI + MST

Use Orca or InstEd to permanently merge the transform into the MSI.

### Using Orca

1. Open MSI in Orca
2. **Transform** → **Apply Transform** → Select MST file
3. **File** → **Save As** → New MSI filename
4. Deploy the new MSI normally

### Using InstEd

1. Open MSI in InstEd
2. **Transform** → **Apply Transform** → Select MST file
3. **File** → **Save As** → New MSI filename
4. Deploy the new MSI normally

### Using PowerShell Script

Run the provided `Merge-MSI-MST.ps1` script:
```powershell
.\Merge-MSI-MST.ps1 -MsiPath ".\source\YourApp.msi" -MstPath ".\source\YourApp.mst" -OutputPath ".\output\YourApp-Merged.msi"
```

---

## Files Included

- `install.cmd` - Wrapper script that applies MST during installation
- `detect.ps1` - Detection script for Intune (customize for your app)
- `uninstall.cmd` - Uninstall script
- `Merge-MSI-MST.ps1` - PowerShell script to merge MSI + MST
- `README.md` - This file

---

## Intune Configuration

### Install Command
```
install.cmd
```

### Uninstall Command
```
msiexec /x {PRODUCT-CODE-GUID} /qn
```

**To find Product Code:**
```powershell
# Option 1: View MSI properties
$installer = New-Object -ComObject WindowsInstaller.Installer
$database = $installer.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $installer, @("YourApp.msi", 0))
$view = $database.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $database, ("SELECT Value FROM Property WHERE Property='ProductCode'"))
$view.GetType().InvokeMember("Execute", "InvokeMethod", $null, $view, $null)
$record = $view.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $view, $null)
$productCode = $record.GetType().InvokeMember("StringData", "GetProperty", $null, $record, 1)
Write-Host "Product Code: $productCode"

# Option 2: Use Orca/InstEd to view Property table
```

### Detection Rules

Choose one:

**1. MSI Product Code Detection (Recommended)**
- Rule type: MSI
- Product code: {YOUR-PRODUCT-CODE-GUID}

**2. File Detection**
- Path: `C:\Program Files\YourApp\YourApp.exe`
- File or folder: File
- Detection method: File or folder exists

**3. Registry Detection**
- Key: `HKLM\SOFTWARE\YourCompany\YourApp`
- Value: Version
- Detection method: String comparison
- Operator: Equals
- Value: 1.0.0

**4. Script Detection**
- Upload `detect.ps1` (customize for your app)

---

## Advantages of Each Method

### Bundle MSI + MST (Method 1)

**Pros:**
- ✅ Keep original MSI unchanged
- ✅ Easy to update MST separately
- ✅ Can maintain multiple transform versions
- ✅ Easier troubleshooting

**Cons:**
- ❌ Slightly more complex deployment
- ❌ Two files to manage

### Merge into Single MSI (Method 2)

**Pros:**
- ✅ Single file deployment
- ✅ Simpler Intune configuration
- ✅ Standard MSI deployment

**Cons:**
- ❌ Need to recreate merged MSI for transform changes
- ❌ Requires Orca/InstEd or script

---

## Troubleshooting

### MST Not Applying

**Check command syntax:**
```batch
msiexec /i "app.msi" TRANSFORMS="app.mst" /qn /norestart
```

**Verify MST path:**
- Use absolute paths: `TRANSFORMS="%~dp0app.mst"`
- Ensure MST file exists in same directory

**Test manually:**
```cmd
cd source
msiexec /i YourApp.msi TRANSFORMS=YourApp.mst /l*v install.log
notepad install.log
```

### Installation Fails

**Check logs:**
```powershell
# Intune logs
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\

# MSI installation logs
msiexec /i app.msi TRANSFORMS=app.mst /qn /l*v C:\Temp\install.log
```

**Common issues:**
- Product Code conflicts (old version installed)
- MST not compatible with MSI version
- Insufficient permissions
- Missing dependencies

### Detection Not Working

**Verify Product Code:**
```powershell
Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "*YourApp*"} | Select-Object Name, IdentifyingNumber
```

**Check install location:**
```powershell
Test-Path "C:\Program Files\YourApp\YourApp.exe"
```

---

## Next Steps

1. Place your MSI and MST files in `source\` folder
2. Choose Method 1 (bundle) or Method 2 (merge)
3. Test locally
4. Package with IntuneWinAppUtil
5. Upload to Intune
6. Configure detection rules
7. Deploy to test group
8. Monitor deployment status

---

**Created**: November 24, 2025  
**Purpose**: MSI + MST deployment via Microsoft Intune  
**Methods**: Bundle (Win32 app) or Merge (single MSI)
