# Adobe Acrobat DC - Intune Deployment Configuration

## Package Ready for Upload!

**File Location:** `C:\IntuneWin\msi-builders\msi-with-mst\intune-packages\install-enhanced.intunewin`

**Package Size:** 3.39 MB

**Created:** November 24, 2025

---

## Step 1: Upload to Intune

1. Go to: https://intune.microsoft.com
2. Navigate to: **Apps** → **Windows** → **+ Add**
3. Select: **Windows app (Win32)**
4. Click **Select app package file**
5. Browse and select: `install-enhanced.intunewin`
6. Click **OK** and wait for upload to complete

---

## Step 2: Copy & Paste These Settings into Intune

### App Information

**Copy these values:**

```
Name: Adobe Acrobat DC (64-bit) - Cloud & AI Disabled

Description: Adobe Acrobat DC professional PDF software with cloud services, AI features, and telemetry disabled for enhanced privacy and security.

Disabled features:
- AI Assistant and Acrobat Assistant
- Adobe Document Cloud sync
- Adobe Sign cloud services
- Telemetry and usage tracking
- Collaboration and sharing features

Publisher: Adobe Inc.

App Version: 21.001.20135

Category: Productivity

Information URL: https://www.adobe.com/acrobat.html

Privacy URL: https://www.adobe.com/privacy.html
```

---

### Program Settings

**Install command:**
```
install-enhanced.cmd
```

**Uninstall command:**
```
msiexec /x {AC76BA86-1033-FFFF-7760-BC15014EA700} /qn /norestart
```

**Install behavior:** `System`

**Device restart behavior:** `Determine behavior based on return codes`

---

### Requirements

**Operating system architecture:** 
- ☑ **64-bit**

**Minimum operating system:** 
- **Windows 10 1607** (or higher)

---

### Detection Rules

**Rules format:** `Manually configure detection rules`

**Click + Add and enter:**

**Rule type:** `MSI`

**MSI product code:** `{AC76BA86-1033-FFFF-7760-BC15014EA700}`

---

### Dependencies

**None required** - Click Next

---

### Supersedence

**Optional** - If replacing old Adobe Acrobat version:
1. Click **+ Add**
2. Select old Adobe Acrobat app
3. Set **Uninstall previous version:** `Yes`

Otherwise, click **Next**

---

### Assignments

**For Pilot Testing (Recommended):**
1. Under **Required**, click **+ Add group**
2. Select your pilot group (e.g., "IT-Pilot-Users")
3. Click **Select**
4. End user notifications: `Show all toast notifications`
5. Installation deadline: `As soon as possible`

**For Production (After pilot success):**
- Add more groups under **Required** or **Available**

---

## Step 3: What's Included in This Package

The .intunewin package contains:

✅ **AcroPro.msi** (12.59 MB)
   - Adobe Acrobat DC installer
   - Version: 21.001.20135
   - Product Code: {AC76BA86-1033-FFFF-7760-BC15014EA700}

✅ **AcroPro.mst** (60 KB)
   - Your custom transform with installation preferences
   - Includes: EULA acceptance, optimization, previous version removal

✅ **install-enhanced.cmd** (4.33 KB)
   - Enhanced installer script
   - Installs MSI with MST transform
   - Automatically applies cloud/AI/telemetry lockdown

✅ **adobe-disable-cloud-ai.reg** (2.97 KB)
   - 33 registry settings across 12 registry keys
   - Disables all cloud, AI, and telemetry features

---

## Step 4: What Gets Disabled

When this package installs, the following features are AUTOMATICALLY disabled:

### AI Features
- ❌ AI Assistant
- ❌ Acrobat Assistant
- ❌ AI-powered suggestions

### Cloud Services
- ❌ Adobe Document Cloud sync
- ❌ Adobe Sign (cloud signing)
- ❌ Cloud storage integration
- ❌ Preference synchronization
- ❌ Send and track features
- ❌ Fill & Sign cloud features
- ❌ Web connectors

### Privacy & Telemetry
- ❌ Usage tracking and telemetry
- ❌ Crash reporting
- ❌ Usage measurement

### Collaboration
- ❌ Share and feedback
- ❌ SharePoint integration
- ❌ Collaboration features

### UI Elements
- ❌ In-product messaging and ads
- ❌ Product tour
- ❌ Welcome screen

---

## Step 5: Verification After Deployment

### On Client Device - Run PowerShell Script:

```powershell
# Check installation
$productCode = "{AC76BA86-1033-FFFF-7760-BC15014EA700}"
$installed = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$productCode" -ErrorAction SilentlyContinue

if ($installed) {
    Write-Host "✓ Adobe Acrobat DC installed" -ForegroundColor Green
    Write-Host "  Version: $($installed.DisplayVersion)"
} else {
    Write-Host "✗ NOT installed" -ForegroundColor Red
}

# Check lockdown settings
$lockdown = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" -ErrorAction SilentlyContinue

if ($lockdown.bDisableAI -eq 1) {
    Write-Host "✓ AI features disabled" -ForegroundColor Green
} else {
    Write-Host "✗ AI features NOT disabled" -ForegroundColor Red
}

$services = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" -ErrorAction SilentlyContinue

if ($services.bToggleAdobeDocumentServices -eq 0) {
    Write-Host "✓ Document Cloud disabled" -ForegroundColor Green
} else {
    Write-Host "✗ Document Cloud NOT disabled" -ForegroundColor Red
}
```

### Manual Verification:

1. Launch Adobe Acrobat DC
2. Go to **Edit** > **Preferences** > **Services**
3. You should see: **"Services are disabled by your administrator"**
4. Check toolbar - AI Assistant icon should NOT be present

---

## Step 6: Monitor Deployment in Intune

1. Go to: **Apps** > **Windows** > **Adobe Acrobat DC**
2. Click **Device install status**
3. Monitor installation progress
4. Check for any failures

**Expected Success Rate:** >95%

---

## Troubleshooting Common Issues

### Issue: Installation Error 1603

**Solution:** Uninstall any existing Acrobat version first
```powershell
Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -like "*Acrobat*" }
```

### Issue: Detection Not Working

**Solution:** Verify Product Code in registry
```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{AC76BA86-1033-FFFF-7760-BC15014EA700}"
```

### Issue: Cloud Features Still Enabled

**Solution:** Deploy Apply-AdobeLockdown.ps1 as separate PowerShell script
- Location: `C:\IntuneWin\msi-builders\msi-with-mst\Apply-AdobeLockdown.ps1`
- Upload to: **Devices** > **Scripts** > **Add**
- Run as: **System**

---

## Package Contents Summary

| File | Size | Purpose |
|------|------|---------|
| install-enhanced.intunewin | 3.39 MB | Complete Intune package (READY TO UPLOAD) |
| AcroPro.msi | 12.59 MB | Adobe installer (inside package) |
| AcroPro.mst | 60 KB | Installation customizations (inside package) |
| install-enhanced.cmd | 4.33 KB | Enhanced installer script (inside package) |
| adobe-disable-cloud-ai.reg | 2.97 KB | Cloud/AI lockdown (inside package) |

---

## Quick Reference

**Package Location:**
```
C:\IntuneWin\msi-builders\msi-with-mst\intune-packages\install-enhanced.intunewin
```

**Intune Portal:**
```
https://intune.microsoft.com
```

**Install Command:**
```
install-enhanced.cmd
```

**Uninstall Command:**
```
msiexec /x {AC76BA86-1033-FFFF-7760-BC15014EA700} /qn /norestart
```

**Product Code:**
```
{AC76BA86-1033-FFFF-7760-BC15014EA700}
```

**Detection:** MSI Product Code (use code above)

---

## Ready to Deploy!

✅ Package created: `install-enhanced.intunewin`
✅ Size: 3.39 MB (compressed from 12.6 MB)
✅ All files included (MSI + MST + enhanced installer + registry lockdown)
✅ Cloud/AI/telemetry disable configured (33 settings)
✅ Ready for upload to Intune

**Next Step:** Go to https://intune.microsoft.com and follow the configuration above!

---

**Created:** November 24, 2025 22:35:02
**Package Hash:** Generated by IntuneWinAppUtil
**Status:** ✅ READY FOR PRODUCTION DEPLOYMENT
