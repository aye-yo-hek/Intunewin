# Adobe Acrobat DC - MST Analysis & Cloud/AI Configuration Guide

## 🔍 Current MST Analysis Results

**File**: `source\AcroPro.mst` (60 KB)  
**Date**: November 24, 2025

### Found Properties

The current MST contains these customizations:

```
✅ EULA_ACCEPT = NO
✅ ENABLE_OPTIMIZATION = YES
✅ REMOVE_PREVIOUS = YES
```

### Missing Cloud/AI Disable Properties

The following properties for disabling cloud and AI features are **NOT present** in the current MST:

```
❌ DISABLE_ARM_SERVICE_UPLOADS     (Disables cloud uploads)
❌ DISABLE_DOCUMENT_CLOUD          (Disables Document Cloud)
❌ DISABLE_SERVICES                (Disables Adobe cloud services)
❌ DISABLE_ACROBAT_COM             (Disables Acrobat.com integration)
❌ DISABLE_PRODUCT_TOUR            (Disables product tour/AI assistant prompts)
❌ ENABLE_CHROMEEXT                (Chrome extension integration)
❌ SUPPRESS_APP_OPEN_ON_INSTALL_COMPLETE
```

---

## ⚠️ Action Required: Create Enhanced MST

To disable AI and cloud features, you need to create a NEW MST file with additional properties.

### Option 1: Use Adobe Customization Wizard (Recommended)

1. **Download Adobe Customization Wizard DC**
   - Available from Adobe Enterprise Dashboard
   - Or search "Adobe Customization Wizard DC download"

2. **Open the AcroPro.msi file**
   ```
   File > Open Package > Select AcroPro.msi
   ```

3. **Configure Installation Properties**

   Navigate to: **Personalization Options > Installation Options**
   
   Add/Modify these properties:
   ```
   DISABLE_ARM_SERVICE_UPLOADS = 1
   DISABLE_DOCUMENT_CLOUD = 1
   DISABLE_SERVICES = 1
   EULA_ACCEPT = YES
   ENABLE_OPTIMIZATION = YES
   REMOVE_PREVIOUS = YES
   SUPPRESS_APP_OPEN_ON_INSTALL_COMPLETE = 1
   ```

4. **Configure Feature Lockdown**

   Navigate to: **Personalization Options > Security**
   
   Enable these registry-based lockdowns:
   
   ```
   SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown
   
   Registry Keys to Add:
   - bDisableShareFeedback = 1 (DWORD)
   - bToggleFillSign = 0 (DWORD)  
   - bTogglePrefsSync = 0 (DWORD)
   - bDisableTrustedSites = 1 (DWORD)
   - bEnableFlash = 0 (DWORD)
   ```

5. **Disable Cloud Services**

   Navigate to: **Personalization Options > Online and Adobe Sign Services**
   
   ```
   SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices
   
   Registry Keys to Add:
   - bToggleAdobeDocumentServices = 0 (DWORD)
   - bToggleAdobeSign = 0 (DWORD)
   - bTogglePrefSync = 0 (DWORD)
   - bToggleWebConnectors = 0 (DWORD)
   - bUpdater = 0 (DWORD)
   ```

6. **Disable AI Assistant**

   Navigate to: **Personalization Options > Features**
   
   ```
   SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown
   
   Registry Keys to Add:
   - bDisableAcrobatAssistant = 1 (DWORD)
   - bDisableAI = 1 (DWORD)
   ```

7. **Save as Transform**
   ```
   Transform > Generate Transform
   Save as: AcroPro-NoCloud.mst
   ```

---

### Option 2: Use Orca to Edit MST

1. **Open Orca** (part of Windows SDK)

2. **Open AcroPro.msi**

3. **Create New Transform**
   ```
   Transform > New Transform
   ```

4. **Edit Property Table**
   
   Navigate to: **Property table**
   
   Add these rows:
   
   | Property | Value |
   |----------|-------|
   | DISABLE_ARM_SERVICE_UPLOADS | 1 |
   | DISABLE_DOCUMENT_CLOUD | 1 |
   | DISABLE_SERVICES | 1 |
   | EULA_ACCEPT | YES |
   | SUPPRESS_APP_OPEN_ON_INSTALL_COMPLETE | 1 |

5. **Edit Registry Table**
   
   Navigate to: **Registry table**
   
   Add these rows for cloud/AI lockdown:
   
   | Root | Key | Name | Value |
   |------|-----|------|-------|
   | 2 | SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown | bDisableShareFeedback | #1 |
   | 2 | SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown | bToggleFillSign | #0 |
   | 2 | SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown | bTogglePrefsSync | #0 |
   | 2 | SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices | bToggleAdobeDocumentServices | #0 |
   | 2 | SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices | bToggleAdobeSign | #0 |
   | 2 | SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown | bDisableAcrobatAssistant | #1 |
   | 2 | SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown | bDisableAI | #1 |

   **Note**: Root 2 = HKLM, #1 means DWORD value 1, #0 means DWORD value 0

6. **Save Transform**
   ```
   Transform > Generate Transform
   Save as: AcroPro-NoCloud.mst
   ```

---

### Option 3: Use Group Policy (Post-Installation)

If you can't modify the MST, deploy via Intune Configuration Profiles:

1. **Create Configuration Profile**
   - Endpoint Manager > Devices > Configuration profiles > Create profile
   - Platform: Windows 10 and later
   - Profile type: Settings catalog

2. **Add Settings**
   
   Search for: **Administrative Templates > Adobe Acrobat**
   
   Configure:
   - Disable Document Cloud
   - Disable Services
   - Disable AI Assistant
   - Disable Share Feedback

3. **Or Use Custom OMA-URI**
   
   ```xml
   <SyncML>
     <SyncBody>
       <Add>
         <CmdID>1</CmdID>
         <Item>
           <Target>
             <LocURI>./Device/Vendor/MSFT/Policy/Config/ADMX_AdobeAcrobat/DisableDocumentCloud</LocURI>
           </Target>
           <Meta>
             <Format xmlns="syncml:metinf">int</Format>
           </Meta>
           <Data>1</Data>
         </Item>
       </Add>
     </SyncBody>
   </SyncML>
   ```

---

## 📝 Registry Keys Reference

### Complete List of Cloud/AI Disable Registry Keys

Copy these to a `.reg` file for manual deployment:

```reg
Windows Registry Editor Version 5.00

; Disable Adobe Cloud Services and AI Features
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown]
"bDisableShareFeedback"=dword:00000001
"bToggleFillSign"=dword:00000000
"bTogglePrefsSync"=dword:00000000
"bDisableTrustedSites"=dword:00000001
"bEnableFlash"=dword:00000000
"bDisableAcrobatAssistant"=dword:00000001
"bDisableAI"=dword:00000001
"bDisableAcrobatUpdate"=dword:00000000

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices]
"bToggleAdobeDocumentServices"=dword:00000000
"bToggleAdobeSign"=dword:00000000
"bTogglePrefSync"=dword:00000000
"bToggleWebConnectors"=dword:00000000
"bUpdater"=dword:00000000

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cCloud]
"bDisableShareFeedback"=dword:00000001
"bDisablePDFHandlerSwitching"=dword:00000001

; Disable telemetry
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cIPM]
"bShowMsgAtLaunch"=dword:00000000
"bDontShowMsgWhenViewingDoc"=dword:00000001
```

Save as: `adobe-disable-cloud-ai.reg`

Deploy via:
- **Intune**: Configuration Profile > Custom OMA-URI
- **PowerShell Script**: `reg import adobe-disable-cloud-ai.reg`
- **Installation Script**: `install.cmd`

---

## 🔄 Future Version Update Process

### When Adobe Releases New Version

1. **Download New MSI/MST from Adobe**
   - Check Adobe Admin Console
   - Or use Adobe Acrobat Customization Wizard

2. **Verify Product Code Changed**
   ```powershell
   $installer = New-Object -ComObject WindowsInstaller.Installer
   $db = $installer.OpenDatabase("AcroPro-NEW.msi", 0)
   $view = $db.OpenView("SELECT Value FROM Property WHERE Property='ProductCode'")
   $view.Execute()
   $record = $view.Fetch()
   $newProductCode = $record.StringData(1)
   Write-Host "New Product Code: $newProductCode"
   ```

3. **Recreate MST with Cloud/AI Disabled**
   - Use Adobe Customization Wizard (preferred)
   - Apply same settings as documented above
   - Save as `AcroPro-vXX.XX-NoCloud.mst`

4. **Update Scripts**
   
   **Update uninstall.cmd**:
   ```cmd
   @echo off
   REM Uninstall Adobe Acrobat DC
   msiexec /x {NEW-PRODUCT-CODE-HERE} /qn /norestart
   ```

   **Update detect.ps1** (if using file-based detection):
   ```powershell
   $version = "XX.XXX.XXXXX"  # New version number
   ```

5. **Test Installation**
   ```powershell
   .\Test-Installation.ps1 -Method Bundle
   ```

6. **Verify Settings Applied**
   - Check registry keys
   - Launch Acrobat > Edit > Preferences > Services (should be disabled)
   - Check for AI Assistant (should not appear)

7. **Re-merge MSI+MST**
   ```powershell
   .\Merge-MSI-MST.ps1
   ```

8. **Run Validation**
   ```powershell
   .\Test-Deployment.ps1
   ```

9. **Package for Intune**
   ```powershell
   IntuneWinAppUtil.exe -c ".\source" -s "install.cmd" -o ".\intune-packages"
   ```

10. **Update Intune Deployment**
    - Upload new `.intunewin` package
    - Update detection rules if Product Code changed
    - Test with pilot group
    - Deploy to production

---

## ✅ Verification Checklist

After installation, verify these settings:

### Registry Verification

```powershell
# Check FeatureLockDown
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" -ErrorAction SilentlyContinue

# Check Cloud Services
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" -ErrorAction SilentlyContinue

# Check AI Settings
$ai = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" -Name "bDisableAI" -ErrorAction SilentlyContinue
if ($ai.bDisableAI -eq 1) {
    Write-Host "✓ AI Features Disabled" -ForegroundColor Green
} else {
    Write-Host "❌ AI Features NOT Disabled" -ForegroundColor Red
}
```

### Application Verification

1. Launch Adobe Acrobat DC
2. Go to **Edit > Preferences**
3. Check **Services** section:
   - Should show "Services are disabled by your administrator"
   - Adobe Sign should be unavailable
   - Document Cloud sync should be disabled
4. Check **Help** menu:
   - AI Assistant option should not appear
   - Or is grayed out/disabled
5. Check toolbar:
   - No "Share" button for cloud sharing
   - No "Fill & Sign" cloud features

---

## 📋 Summary

### Current State
- ✅ MST file exists (60 KB)
- ✅ Basic installation properties configured
- ❌ **Cloud/AI disable features NOT configured**
- ❌ **MST needs to be recreated with proper settings**

### Required Actions
1. **Recreate MST** using Adobe Customization Wizard or Orca
2. Add cloud/AI disable properties and registry keys
3. Test installation with new MST
4. Verify settings are applied
5. Re-package for Intune deployment

### Alternative Solutions
- Deploy registry keys via Intune Configuration Profile
- Use Group Policy (for domain-joined devices)
- Add registry import to install.cmd script

---

**Important**: The current MST does not disable cloud or AI features. You must either:
1. Create a new MST with proper settings, OR
2. Deploy additional registry keys via Intune Configuration Profile

**Next Steps**: Choose your preferred method and implement cloud/AI disabling before production deployment.
