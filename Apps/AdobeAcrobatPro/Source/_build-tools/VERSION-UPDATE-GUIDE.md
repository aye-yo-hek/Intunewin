# Adobe Acrobat DC - Version Update & Future Maintenance Guide

## 🔄 Version Update Process

This guide ensures you can update Adobe Acrobat DC to future versions while maintaining cloud/AI disabled configurations.

---

## 📋 Pre-Update Checklist

Before updating to a new version:

- [ ] Backup current MSI/MST files
- [ ] Document current version and Product Code
- [ ] Review Adobe release notes for new features/changes
- [ ] Test in non-production environment first
- [ ] Verify Intune Win32 Content Prep Tool is available

---

## 🔢 Step-by-Step Update Process

### Step 1: Obtain New Version Files

**Option A: Adobe Admin Console**
1. Login to https://adminconsole.adobe.com
2. Navigate to Packages
3. Create/download new Acrobat DC package
4. Include customizations if possible

**Option B: Adobe FTP**
1. Download from Adobe enterprise FTP
2. Extract MSI file

**File Naming Convention**:
```
AcroPro-v{VERSION}.msi
AcroPro-v{VERSION}.mst
```
Example: `AcroPro-v24.001.20643.msi`

---

### Step 2: Extract Version Information

Run this PowerShell script to extract details:

```powershell
# Get-AdobeVersion.ps1
param([string]$MsiPath)

$installer = New-Object -ComObject WindowsInstaller.Installer
$database = $installer.OpenDatabase($MsiPath, 0)

# Get Product Code
$view = $database.OpenView("SELECT Value FROM Property WHERE Property='ProductCode'")
$view.Execute()
$record = $view.Fetch()
$productCode = $record.StringData(1)

# Get Product Version
$view = $database.OpenView("SELECT Value FROM Property WHERE Property='ProductVersion'")
$view.Execute()
$record = $view.Fetch()
$version = $record.StringData(1)

# Get Product Name
$view = $database.OpenView("SELECT Value FROM Property WHERE Property='ProductName'")
$view.Execute()
$record = $view.Fetch()
$name = $record.StringData(1)

Write-Host "Product Name: $name"
Write-Host "Product Version: $version"
Write-Host "Product Code: $productCode"

# Cleanup
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($database) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($installer) | Out-Null

# Return object for scripting
return @{
    Name = $name
    Version = $version
    ProductCode = $productCode
}
```

Usage:
```powershell
.\Get-AdobeVersion.ps1 -MsiPath ".\AcroPro-v24.msi"
```

---

### Step 3: Create Enhanced MST with Cloud/AI Disabled

#### Method 1: Adobe Customization Wizard (Recommended)

1. **Launch Adobe Customization Wizard DC**

2. **Open Package**
   ```
   File > Open Package > Select new AcroPro-vXX.msi
   ```

3. **Installation Options**
   
   Navigate to: `Personalization Options > Installation Options`
   
   Set these properties:
   ```
   DISABLE_ARM_SERVICE_UPLOADS = 1
   DISABLE_DOCUMENT_CLOUD = 1
   DISABLE_SERVICES = 1
   EULA_ACCEPT = YES
   ENABLE_OPTIMIZATION = YES
   REMOVE_PREVIOUS = YES
   SUPPRESS_APP_OPEN_ON_INSTALL_COMPLETE = 1
   ```

4. **Add Registry Policies - Security**
   
   Navigate to: `Registry > Add Registry Entry`
   
   ```
   Root: HKEY_LOCAL_MACHINE
   Key: SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown
   
   Name: bDisableAI
   Type: REG_DWORD
   Data: 1
   
   Name: bDisableAcrobatAssistant
   Type: REG_DWORD
   Data: 1
   
   Name: bDisableShareFeedback
   Type: REG_DWORD
   Data: 1
   
   Name: bToggleFillSign
   Type: REG_DWORD
   Data: 0
   
   Name: bTogglePrefsSync
   Type: REG_DWORD
   Data: 0
   ```

5. **Add Cloud Services Lockdown**
   
   ```
   Root: HKEY_LOCAL_MACHINE
   Key: SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices
   
   Name: bToggleAdobeDocumentServices
   Type: REG_DWORD
   Data: 0
   
   Name: bToggleAdobeSign
   Type: REG_DWORD
   Data: 0
   
   Name: bTogglePrefSync
   Type: REG_DWORD
   Data: 0
   
   Name: bToggleWebConnectors
   Type: REG_DWORD
   Data: 0
   ```

6. **Save Transform**
   ```
   Transform > Generate Transform
   Save as: AcroPro-vXX-NoCloud.mst
   ```

7. **Verify Transform**
   
   Run inspection:
   ```powershell
   .\Inspect-MST.ps1 -MsiPath ".\AcroPro-vXX.msi" -MstPath ".\AcroPro-vXX-NoCloud.mst"
   ```
   
   Verify these properties exist:
   - ✅ DISABLE_DOCUMENT_CLOUD = 1
   - ✅ DISABLE_SERVICES = 1
   - ✅ Registry keys for bDisableAI, bDisableAcrobatAssistant

---

#### Method 2: Use Orca + Registry Template

1. **Open Orca**

2. **Open new MSI**
   ```
   File > Open > AcroPro-vXX.msi
   ```

3. **Create Transform**
   ```
   Transform > New Transform
   ```

4. **Edit Property Table**
   
   Add rows:
   | Property | Value |
   |----------|-------|
   | DISABLE_ARM_SERVICE_UPLOADS | 1 |
   | DISABLE_DOCUMENT_CLOUD | 1 |
   | DISABLE_SERVICES | 1 |
   | EULA_ACCEPT | YES |

5. **Import Registry Template**
   
   Navigate to Registry table, add entries from `adobe-disable-cloud-ai.reg`

6. **Save Transform**
   ```
   Transform > Generate Transform
   Save as: AcroPro-vXX-NoCloud.mst
   ```

---

### Step 4: Update Deployment Files

#### 4.1 Update Version Tracking

Create `VERSION.txt`:
```
Adobe Acrobat DC
Version: 24.001.20643
Product Code: {AC76BA86-1033-FFFF-7760-BC15014EA700}
Build Date: 2025-11-24
MSI File: AcroPro-v24.001.msi
MST File: AcroPro-v24.001-NoCloud.mst
Deployment Date: 2025-11-30
```

#### 4.2 Update uninstall.cmd

```cmd
@echo off
REM Uninstall Adobe Acrobat DC v24.001.20643
REM Updated: 2025-11-24

echo Uninstalling Adobe Acrobat DC...

REM Updated Product Code for new version
msiexec /x {AC76BA86-1033-FFFF-7760-BC15014EA700} /qn /norestart /l*v "%TEMP%\AcroPro-Uninstall.log"

if %ERRORLEVEL% EQU 0 (
    echo Uninstallation completed successfully.
) else (
    echo Uninstallation failed with code %ERRORLEVEL%
)

exit /b %ERRORLEVEL%
```

#### 4.3 Update detect.ps1

```powershell
# detect.ps1 - Updated for v24.001.20643

$productCode = "{AC76BA86-1033-FFFF-7760-BC15014EA700}"  # UPDATE THIS
$expectedVersion = "24.001.20643"  # UPDATE THIS

# Method 1: Product Code
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$productCode",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$productCode"
)

foreach ($path in $regPaths) {
    if (Test-Path $path) {
        $props = Get-ItemProperty $path
        if ($props.DisplayVersion -ge $expectedVersion) {
            Write-Host "Detected: $($props.DisplayName) v$($props.DisplayVersion)"
            exit 0
        }
    }
}

exit 1
```

#### 4.4 Copy Files to source/

```powershell
# Update-SourceFiles.ps1

$newVersion = "24.001.20643"
$sourceDir = ".\source"

# Backup old files
if (Test-Path "$sourceDir\AcroPro.msi") {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    New-Item -Path ".\backup\$timestamp" -ItemType Directory -Force
    Move-Item "$sourceDir\AcroPro.msi" ".\backup\$timestamp\AcroPro.msi"
    Move-Item "$sourceDir\AcroPro.mst" ".\backup\$timestamp\AcroPro.mst"
}

# Copy new files
Copy-Item ".\downloads\AcroPro-v$newVersion.msi" "$sourceDir\AcroPro.msi"
Copy-Item ".\downloads\AcroPro-v$newVersion-NoCloud.mst" "$sourceDir\AcroPro.mst"

Write-Host "✓ Files updated in source folder"
Write-Host "✓ Old files backed up to .\backup\$timestamp"
```

---

### Step 5: Test New Version

```powershell
# Run comprehensive tests
.\Test-Deployment.ps1

# Expected results:
# ✓ Found MSI: AcroPro.msi (XX.XX MB)
# ✓ Found MST: AcroPro.mst (XX KB)
# ✓ Product Code: {NEW-PRODUCT-CODE}
# ✓ Product Version: XX.XXX.XXXXX
# ✓ Method 1 (Bundle): PASS
# ✓ Method 2 (Merge): PASS
# ✓ Detection Script: PASS
```

Verify cloud/AI settings:
```powershell
.\Inspect-MST.ps1

# Should show:
# ✓ DISABLE_DOCUMENT_CLOUD = 1
# ✓ DISABLE_SERVICES = 1
# ✓ Registry: bDisableAI = 1
# ✓ Registry: bDisableAcrobatAssistant = 1
```

---

### Step 6: Create New Merged MSI

```powershell
# Merge MSI + MST
.\Merge-MSI-MST.ps1

# Output: output\AcroPro-Merged.msi
```

Verify merged MSI:
```powershell
# Check file exists and size
Get-Item .\output\AcroPro-Merged.msi | Select-Object Name, Length, LastWriteTime
```

---

### Step 7: Package for Intune

**Method 1: Bundle (Recommended)**

```powershell
# Package source folder with install-enhanced.cmd
IntuneWinAppUtil.exe -c ".\source" -s "install-enhanced.cmd" -o ".\intune-packages"

# Output: intune-packages\install-enhanced.intunewin
```

**Method 2: Merged MSI**

```powershell
# Package merged MSI
IntuneWinAppUtil.exe -c ".\output" -s "AcroPro-Merged.msi" -o ".\intune-packages"

# Output: intune-packages\AcroPro-Merged.intunewin
```

---

### Step 8: Update Intune Deployment

#### 8.1 Create New App (Recommended for Major Updates)

1. **Login to Intune** (https://intune.microsoft.com)

2. **Create New Win32 App**
   - Apps → Windows → Add → Windows app (Win32)
   - Select new `.intunewin` file
   
3. **App Information**
   ```
   Name: Adobe Acrobat DC (v24.001)
   Description: Adobe Acrobat DC with cloud and AI features disabled
   Publisher: Adobe Inc.
   ```

4. **Program**
   ```
   Install command: install-enhanced.cmd
   Uninstall command: msiexec /x {AC76BA86-1033-FFFF-7760-BC15014EA700} /qn
   Install behavior: System
   ```

5. **Requirements**
   ```
   OS architecture: 64-bit
   Minimum OS: Windows 10 1607
   ```

6. **Detection Rules**
   
   **Option A: MSI Product Code**
   ```
   Rule type: MSI
   Product code: {AC76BA86-1033-FFFF-7760-BC15014EA700}
   ```
   
   **Option B: Custom Script**
   - Upload `detect.ps1`
   - Detection method: Custom script

7. **Dependencies (if applicable)**
   - Previous Acrobat version (uninstall)
   
8. **Supersedence (if applicable)**
   - Supersede old Acrobat DC v23.x deployment
   - Uninstall previous version: Yes

---

#### 8.2 Deploy Cloud/AI Lockdown (PowerShell Script)

Since MST may not have all settings, deploy additional lockdown:

1. **Create PowerShell Script Deployment**
   - Devices → Scripts → Add → Windows 10 and later

2. **Script Settings**
   ```
   Name: Adobe Acrobat DC - Cloud AI Lockdown
   Script file: Apply-AdobeLockdown.ps1
   Run this script using the logged on credentials: No
   Enforce script signature check: No
   Run script in 64-bit PowerShell: Yes
   ```

3. **Assign to Same Groups** as Adobe app

4. **Dependencies**
   - Set Adobe Acrobat app as dependency
   - Run lockdown script AFTER Acrobat installs

---

### Step 9: Pilot Testing

1. **Create Pilot Group**
   ```
   Group name: Pilot-AdobeAcrobat-v24
   Members: 5-10 test users
   ```

2. **Assign App**
   - Required installation
   - Available by deadline: Immediate

3. **Monitor Installation**
   - Apps → Monitor → Device install status
   - Check for failures

4. **Verify on Test Device**
   ```powershell
   # Check installation
   $code = "{AC76BA86-1033-FFFF-7760-BC15014EA700}"
   Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$code"
   
   # Check cloud/AI lockdown
   Get-ItemProperty "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown"
   ```

5. **Manual Testing**
   - Launch Acrobat
   - Check Edit → Preferences → Services (should be disabled)
   - Verify no AI Assistant in toolbar
   - Check Help → About to confirm version

---

### Step 10: Production Rollout

1. **Review Pilot Results**
   - 100% success rate required
   - No user complaints
   - Settings verified

2. **Update Production Assignment**
   - Change existing app assignment to new version
   - Or assign new app to production groups

3. **Communication**
   ```
   Subject: Adobe Acrobat DC Update - Version 24.001
   
   Adobe Acrobat DC will be updated to version 24.001.20643.
   
   New features:
   - [List from Adobe release notes]
   
   Security improvements:
   - Cloud features disabled
   - AI assistant disabled
   - Enhanced privacy controls
   
   Installation: Automatic via Intune
   Timeline: Rollout over 7 days
   ```

4. **Phased Rollout** (Recommended)
   ```
   Week 1: Pilot group (10 users)
   Week 2: Department A (100 users)
   Week 3: Department B (200 users)
   Week 4: All remaining users
   ```

---

## 📊 Monitoring & Validation

### Post-Deployment Monitoring

```powershell
# Check-AdobeDeployment.ps1
# Run this to verify deployments

$productCode = "{AC76BA86-1033-FFFF-7760-BC15014EA700}"

# Check if installed
$installed = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$productCode" -ErrorAction SilentlyContinue

if ($installed) {
    Write-Host "✓ Adobe Acrobat DC installed" -ForegroundColor Green
    Write-Host "  Version: $($installed.DisplayVersion)"
    Write-Host "  Install Date: $($installed.InstallDate)"
} else {
    Write-Host "✗ Adobe Acrobat DC not installed" -ForegroundColor Red
    exit 1
}

# Check cloud/AI lockdown
$lockdown = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" -ErrorAction SilentlyContinue

if ($lockdown.bDisableAI -eq 1) {
    Write-Host "✓ AI features disabled" -ForegroundColor Green
} else {
    Write-Host "⚠ AI features NOT disabled" -ForegroundColor Yellow
}

if ($lockdown.bDisableAcrobatAssistant -eq 1) {
    Write-Host "✓ Acrobat Assistant disabled" -ForegroundColor Green
} else {
    Write-Host "⚠ Acrobat Assistant NOT disabled" -ForegroundColor Yellow
}

$services = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" -ErrorAction SilentlyContinue

if ($services.bToggleAdobeDocumentServices -eq 0) {
    Write-Host "✓ Adobe Document Services disabled" -ForegroundColor Green
} else {
    Write-Host "⚠ Adobe Document Services NOT disabled" -ForegroundColor Yellow
}

exit 0
```

Deploy as Intune compliance script or proactive remediation.

---

## 🔧 Troubleshooting Updates

### Common Issues

#### Issue: Product Code Detection Fails

**Symptom**: Intune shows "Not Detected" after installation

**Solution**:
1. Verify Product Code changed in new version
2. Update detection rule with new Product Code
3. Run `Get-AdobeVersion.ps1` to confirm

#### Issue: MST Not Applying

**Symptom**: Cloud features still enabled after install

**Solution**:
1. Verify MST in same directory as MSI
2. Check install.cmd uses correct TRANSFORMS parameter
3. Review log file: `%TEMP%\AcroPro.msi.install.log`
4. Deploy `Apply-AdobeLockdown.ps1` as separate script

#### Issue: Installation Error 1603

**Symptom**: Installation fails with error code 1603

**Solutions**:
1. Check old version is uninstalled first
2. Verify sufficient disk space
3. Check Windows Installer service is running
4. Review detailed log file
5. Try: `msiexec /x {OLD-PRODUCT-CODE} /qn` first

#### Issue: Supersedence Not Working

**Symptom**: Old and new versions both installed

**Solution**:
1. Verify supersedence relationship in Intune
2. Check "Uninstall previous version" is enabled
3. May need to manually uninstall old version first
4. Use `REMOVE_PREVIOUS=YES` in MSI properties

---

## 📅 Maintenance Schedule

### Quarterly Tasks

- [ ] Check for Adobe security updates
- [ ] Review Adobe release notes
- [ ] Test new versions in pilot environment
- [ ] Update documentation

### Monthly Tasks

- [ ] Monitor Intune deployment status
- [ ] Review installation logs for errors
- [ ] Verify cloud/AI lockdown compliance
- [ ] Check for user complaints

### As-Needed Tasks

- [ ] Adobe security patches (deploy immediately)
- [ ] Critical bug fixes
- [ ] New feature releases (test thoroughly)

---

## 📝 Version History Template

Keep this updated in `VERSION-HISTORY.md`:

```markdown
# Adobe Acrobat DC Version History

## v24.001.20643 (2025-11-30)
- Product Code: {AC76BA86-1033-FFFF-7760-BC15014EA700}
- Changes: Security updates, performance improvements
- MST: AcroPro-v24.001-NoCloud.mst
- Cloud/AI: Disabled via MST + registry
- Deployment: Success (100%)
- Issues: None

## v23.008.20421 (2025-10-15)
- Product Code: {AC76BA86-1033-FFFF-7760-BC15014EA699}
- Changes: Initial deployment
- MST: AcroPro-v23.008-NoCloud.mst
- Cloud/AI: Disabled via registry only
- Deployment: Success (98%)
- Issues: 2% required manual intervention
```

---

## ✅ Version Update Checklist

Use this for each update:

```
Adobe Acrobat DC Version Update Checklist
Version: _____________  Date: _____________

Pre-Update:
[ ] Backup current MSI/MST files
[ ] Document current Product Code
[ ] Review Adobe release notes
[ ] Verify Win32 Content Prep Tool available

Update Process:
[ ] Downloaded new MSI from Adobe
[ ] Extracted version info with Get-AdobeVersion.ps1
[ ] Created new MST with cloud/AI disabled
[ ] Verified MST with Inspect-MST.ps1
[ ] Updated uninstall.cmd with new Product Code
[ ] Updated detect.ps1 with new version
[ ] Copied files to source/ folder
[ ] Ran Test-Deployment.ps1 (all tests passed)
[ ] Created merged MSI (if using Method 2)
[ ] Packaged for Intune (.intunewin created)

Intune Configuration:
[ ] Created/updated Win32 app in Intune
[ ] Configured install/uninstall commands
[ ] Set detection rules (Product Code or script)
[ ] Assigned to pilot group
[ ] Deployed Apply-AdobeLockdown.ps1 script

Testing:
[ ] Pilot deployment successful (100%)
[ ] Verified version on test device
[ ] Checked cloud/AI lockdown settings
[ ] Tested uninstallation
[ ] No user issues reported

Production:
[ ] Updated production assignments
[ ] Sent user communication
[ ] Monitored deployment status
[ ] Verified compliance
[ ] Updated version history

Completed by: _____________ Date: _____________
```

---

## 🚀 Quick Reference Commands

```powershell
# Extract version info
.\Get-AdobeVersion.ps1 -MsiPath ".\new-version.msi"

# Inspect MST
.\Inspect-MST.ps1 -MsiPath ".\AcroPro.msi" -MstPath ".\AcroPro.mst"

# Test deployment
.\Test-Deployment.ps1

# Merge MSI+MST
.\Merge-MSI-MST.ps1

# Package for Intune (Bundle)
IntuneWinAppUtil.exe -c ".\source" -s "install-enhanced.cmd" -o ".\intune-packages"

# Package for Intune (Merged)
IntuneWinAppUtil.exe -c ".\output" -s "AcroPro-Merged.msi" -o ".\intune-packages"

# Apply lockdown separately
.\Apply-AdobeLockdown.ps1

# Check deployment status
.\Check-AdobeDeployment.ps1
```

---

**Prepared by**: IT Admin  
**Last Updated**: November 24, 2025  
**Next Review**: Quarterly or when Adobe releases new version
