# Adobe Acrobat DC - Intune Deployment Guide

## Step-by-Step Instructions for Deploying via Microsoft Intune

---

## Prerequisites

Before you begin, ensure you have:

- [ ] Microsoft Intune admin access (Intune Administrator or Global Administrator role)
- [ ] Microsoft Win32 Content Prep Tool (IntuneWinAppUtil.exe)
- [ ] Source files in the `source\` folder:
  - AcroPro.msi
  - AcroPro.mst
  - install-enhanced.cmd
  - adobe-disable-cloud-ai.reg

---

## Part 1: Package the Application

### Step 1: Download IntuneWinAppUtil (if you don't have it)

1. Open PowerShell
2. Download the tool:
   ```powershell
   # Create tools directory
   New-Item -Path "C:\IntuneTools" -ItemType Directory -Force
   
   # Download IntuneWinAppUtil
   Invoke-WebRequest -Uri "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/raw/master/IntuneWinAppUtil.exe" -OutFile "C:\IntuneTools\IntuneWinAppUtil.exe"
   ```

### Step 2: Package Your Files

1. Open PowerShell as Administrator
2. Navigate to your msi-with-mst folder:
   ```powershell
   cd C:\IntuneWin\msi-builders\msi-with-mst
   ```

3. Run the packaging tool:
   ```powershell
   C:\IntuneTools\IntuneWinAppUtil.exe -c ".\source" -s "install-enhanced.cmd" -o ".\intune-packages"
   ```

   **Parameters explained:**
   - `-c` = Source folder containing all your files
   - `-s` = Setup file (the installer script)
   - `-o` = Output folder for the .intunewin package

4. You should see output like:
   ```
   Microsoft Win32 Content Prep Tool v1.8.x
   
   Specify the source folder: .\source
   Specify the setup file: install-enhanced.cmd
   Specify the output folder: .\intune-packages
   
   Creating package...
   Package created: .\intune-packages\install-enhanced.intunewin
   ```

5. Verify the package was created:
   ```powershell
   Get-Item .\intune-packages\install-enhanced.intunewin
   ```

---

## Part 2: Upload to Microsoft Intune

### Step 1: Access Intune Portal

1. Open your web browser
2. Navigate to: https://intune.microsoft.com
3. Sign in with your admin credentials

### Step 2: Create New Win32 App

1. In the left menu, click **Apps**
2. Click **Windows**
3. Click **+ Add** button at the top
4. In the "Select app type" panel, choose **Windows app (Win32)**
5. Click **Select**

### Step 3: Upload Package

1. **App package file** section:
   - Click **Select app package file**
   - Browse to: `C:\IntuneWin\msi-builders\msi-with-mst\intune-packages\`
   - Select `install-enhanced.intunewin`
   - Click **OK**
   - Wait for upload to complete (you'll see a green checkmark)
   - Click **Next**

### Step 4: Configure App Information

Fill in the following details:

**Required fields:**
- **Name**: `Adobe Acrobat DC (64-bit) - Cloud & AI Disabled`
- **Description**: 
  ```
  Adobe Acrobat DC professional PDF software with cloud services, AI features, and telemetry disabled for enhanced privacy and security.
  
  Disabled features:
  - AI Assistant and Acrobat Assistant
  - Adobe Document Cloud sync
  - Adobe Sign cloud services
  - Telemetry and usage tracking
  - Collaboration and sharing features
  ```
- **Publisher**: `Adobe Inc.`

**Optional but recommended:**
- **App version**: `21.001.20135`
- **Category**: Productivity
- **Show this as a featured app in the Company Portal**: No
- **Information URL**: `https://www.adobe.com/acrobat.html`
- **Privacy URL**: `https://www.adobe.com/privacy.html`
- **Developer**: `Adobe Inc.`
- **Owner**: `IT Department`
- **Notes**: `Deployed with cloud/AI features disabled via registry lockdown`

**Logo** (optional): Upload Adobe Acrobat icon if you have one

Click **Next**

### Step 5: Configure Program Settings

**Install command:**
```cmd
install-enhanced.cmd
```

**Uninstall command:**
```cmd
msiexec /x {AC76BA86-1033-FFFF-7760-BC15014EA700} /qn /norestart
```

**Install behavior:** `System`

**Device restart behavior:** `Determine behavior based on return codes`

**Return codes:** (Leave default or verify these are present)
- 0 = Success
- 1707 = Success
- 3010 = Soft reboot
- 1641 = Hard reboot
- 1618 = Retry

Click **Next**

### Step 6: Configure Requirements

Set minimum requirements for installation:

**Operating system architecture:** 
- ☑ 64-bit

**Minimum operating system:** 
- `Windows 10 1607` (or higher)

**Additional requirement rules:** (Optional)
- Disk space: `500 MB`
- Physical memory: `1 GB`

Click **Next**

### Step 7: Configure Detection Rules

**Rules format:** `Manually configure detection rules`

Click **+ Add**

**Detection Rule #1 - MSI Product Code (Recommended):**
1. **Rule type**: `MSI`
2. **MSI product code**: `{AC76BA86-1033-FFFF-7760-BC15014EA700}`
3. Click **OK**

**Alternative Detection Rule - File-based (if MSI detection doesn't work):**
1. **Rule type**: `File`
2. **Path**: `C:\Program Files\Adobe\Acrobat DC\Acrobat`
3. **File or folder**: `Acrobat.exe`
4. **Detection method**: `File or folder exists`
5. **Associated with a 32-bit app on 64-bit clients**: No
6. Click **OK**

**Alternative Detection Rule - Registry (most reliable):**
1. **Rule type**: `Registry`
2. **Key path**: `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{AC76BA86-1033-FFFF-7760-BC15014EA700}`
3. **Value name**: `DisplayVersion`
4. **Detection method**: `String comparison`
5. **Operator**: `Greater than or equal to`
6. **Value**: `21.001.20135`
7. Click **OK**

**Recommendation:** Use MSI Product Code detection (simplest and most reliable)

Click **Next**

### Step 8: Configure Dependencies

**Optional:** If you have prerequisites (e.g., Visual C++ Runtime)

For now, skip this:
- Click **Next**

### Step 9: Configure Supersedence

**Optional:** If replacing an older version of Adobe Acrobat

To supersede an old version:
1. Click **+ Add**
2. Select the old Adobe Acrobat app
3. **Uninstall previous version**: `Yes`
4. Click **OK**

For new deployment, skip this:
- Click **Next**

### Step 10: Create Assignments

**Pilot Deployment (Recommended first):**

1. Under **Required**, click **+ Add group**
2. Search for your pilot group (e.g., "Pilot-Adobe-Users")
3. Select the group
4. Click **Select**
5. Configure assignment settings:
   - **End user notifications**: `Show all toast notifications`
   - **Available time**: Immediately
   - **Installation deadline**: `As soon as possible` or set a date
   - **Restart grace period**: `0 minutes` (no forced restart)
6. Click **OK**

**Production Deployment (After pilot success):**

Add additional groups under **Required** or **Available for enrolled devices**

**Groups to consider:**
- All Users
- Finance Department
- Legal Department
- Executive Team
- etc.

Click **Next**

### Step 11: Review + Create

1. Review all your settings:
   - App information ✓
   - Program (install/uninstall commands) ✓
   - Requirements ✓
   - Detection rules ✓
   - Assignments ✓

2. If everything looks correct, click **Create**

3. Wait for the app to be created (this may take 30-60 seconds)

4. You'll see "Successfully created Adobe Acrobat DC" message

---

## Part 3: Monitor Deployment

### Step 1: Check App Status

1. Navigate to **Apps** > **Windows**
2. Find **Adobe Acrobat DC (64-bit) - Cloud & AI Disabled**
3. Click on it

### Step 2: Monitor Installation Status

1. Click **Device install status** in the left menu
2. You'll see a list of devices with installation status:
   - **Installed**: Success
   - **Not installed**: Pending or device offline
   - **Failed**: Error occurred (check logs)

### Step 3: Monitor User Install Status

1. Click **User install status**
2. View installation status per user

### Step 4: View Installation Logs (if needed)

**On the client device:**

1. Open Event Viewer
2. Navigate to: **Applications and Services Logs** > **Microsoft** > **Windows** > **DeviceManagement-Enterprise-Diagnostics-Provider** > **Admin**
3. Look for Intune Management Extension events

**Intune log location on device:**
```
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log
```

**Adobe installation log:**
```
C:\Windows\Temp\AcroPro.msi.install.log
```

---

## Part 4: Verify Installation on Client Device

### Automated Verification (PowerShell)

Run this on a test device:

```powershell
# Check if Adobe Acrobat is installed
$productCode = "{AC76BA86-1033-FFFF-7760-BC15014EA700}"
$installed = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$productCode" -ErrorAction SilentlyContinue

if ($installed) {
    Write-Host "✓ Adobe Acrobat DC is installed" -ForegroundColor Green
    Write-Host "  Version: $($installed.DisplayVersion)"
    Write-Host "  Install Date: $($installed.InstallDate)"
} else {
    Write-Host "✗ Adobe Acrobat DC is NOT installed" -ForegroundColor Red
}

# Check cloud/AI lockdown settings
Write-Host "`nChecking lockdown settings..."

$lockdown = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" -ErrorAction SilentlyContinue

if ($lockdown) {
    Write-Host "✓ FeatureLockDown policies applied" -ForegroundColor Green
    
    if ($lockdown.bDisableAI -eq 1) {
        Write-Host "  ✓ AI features disabled" -ForegroundColor Green
    }
    
    if ($lockdown.bDisableAcrobatAssistant -eq 1) {
        Write-Host "  ✓ Acrobat Assistant disabled" -ForegroundColor Green
    }
} else {
    Write-Host "⚠ FeatureLockDown policies NOT applied" -ForegroundColor Yellow
}

$services = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices" -ErrorAction SilentlyContinue

if ($services) {
    if ($services.bToggleAdobeDocumentServices -eq 0) {
        Write-Host "  ✓ Adobe Document Cloud disabled" -ForegroundColor Green
    }
    
    if ($services.bToggleAdobeSign -eq 0) {
        Write-Host "  ✓ Adobe Sign disabled" -ForegroundColor Green
    }
}
```

### Manual Verification

1. **Launch Adobe Acrobat DC**

2. **Check Services are Disabled:**
   - Go to **Edit** > **Preferences**
   - Click **Services** in left panel
   - You should see: "Services are disabled by your administrator"

3. **Verify AI Assistant is Hidden:**
   - Look for AI Assistant icon in toolbar (should NOT be present)
   - Check Help menu (AI features should be absent)

4. **Test Cloud Features Blocked:**
   - Try to access **File** > **Share** (should be disabled or missing)
   - Try **Tools** > **Fill & Sign** (cloud features should be disabled)

5. **Check Version:**
   - Go to **Help** > **About Adobe Acrobat DC**
   - Verify version: `21.001.20135`

---

## Part 5: Troubleshooting

### Issue: Installation Failed with Error 1603

**Symptoms:** Installation shows "Failed" in Intune with exit code 1603

**Solutions:**
1. Check if older version is installed:
   ```powershell
   Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -like "*Acrobat*" }
   ```

2. Uninstall old version first (via Intune or manually)

3. Check disk space:
   ```powershell
   Get-PSDrive C | Select-Object Used,Free
   ```

4. Review installation log:
   ```
   C:\Windows\Temp\AcroPro.msi.install.log
   ```

### Issue: Detection Not Working

**Symptoms:** App installs but Intune shows "Not detected"

**Solutions:**
1. Verify Product Code matches:
   ```powershell
   Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{AC76BA86-1033-FFFF-7760-BC15014EA700}"
   ```

2. Check if 32-bit vs 64-bit registry:
   ```powershell
   Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{AC76BA86-1033-FFFF-7760-BC15014EA700}"
   ```

3. Use file-based detection instead (see Step 7 alternatives)

### Issue: Cloud/AI Features Not Disabled

**Symptoms:** Adobe still shows cloud/AI features after installation

**Solutions:**
1. Check if registry settings were applied:
   ```powershell
   Get-ItemProperty "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown"
   ```

2. Manually import registry file:
   ```powershell
   reg import "C:\IntuneWin\msi-builders\msi-with-mst\source\adobe-disable-cloud-ai.reg"
   ```

3. Deploy Apply-AdobeLockdown.ps1 as separate PowerShell script:
   - **Devices** > **Scripts** > **Add** > **Windows 10 and later**
   - Upload `Apply-AdobeLockdown.ps1`
   - Run as: System
   - Run in 64-bit: Yes

### Issue: App Not Showing in Company Portal

**Symptoms:** Users can't find Adobe in Company Portal

**Solutions:**
1. Check assignment type (Required vs Available)
2. Verify user is in assigned group
3. Sync device: **Settings** > **Accounts** > **Access work or school** > **Info** > **Sync**

### Issue: Installation Stuck in "Pending"

**Symptoms:** Installation status shows "Pending" for extended period

**Solutions:**
1. Check device is online and connected to Intune
2. Restart Intune Management Extension service on device:
   ```powershell
   Restart-Service -Name IntuneManagementExtension
   ```

3. Manually sync device (see above)

4. Check Intune logs:
   ```
   C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log
   ```

---

## Part 6: Post-Deployment Tasks

### 1. Communication to Users

Send an email or Teams message:

```
Subject: Adobe Acrobat DC Installed on Your Device

Hello,

Adobe Acrobat DC has been installed on your device. You can now use it to create, edit, and manage PDF documents.

Important notes:
• Cloud services (Document Cloud, Adobe Sign) are disabled for security and privacy
• AI features are disabled per company policy
• All features for local PDF editing remain available
• Updates are managed by IT

If you have any questions or issues, please contact IT Support.

Thank you,
IT Department
```

### 2. Create Compliance Report

Monitor deployment success:

1. Go to **Apps** > **Windows** > **Adobe Acrobat DC**
2. Click **Device install status**
3. Export to CSV for reporting
4. Track success rate (target: >95%)

### 3. Schedule Follow-up Review

- **Week 1**: Check pilot deployment (5-10 devices)
- **Week 2**: Expand to 10% of users
- **Week 3**: Expand to 50% of users
- **Week 4**: Deploy to remaining users

### 4. Document Deployment

Create internal documentation:
- Deployment date
- Number of devices
- Success rate
- Issues encountered
- Version deployed
- Product Code for reference

---

## Quick Reference Commands

### Package App
```powershell
C:\IntuneTools\IntuneWinAppUtil.exe -c ".\source" -s "install-enhanced.cmd" -o ".\intune-packages"
```

### Check Installation
```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{AC76BA86-1033-FFFF-7760-BC15014EA700}"
```

### Verify Lockdown
```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown"
```

### Manual Install (Testing)
```cmd
install-enhanced.cmd
```

### Manual Uninstall
```cmd
msiexec /x {AC76BA86-1033-FFFF-7760-BC15014EA700} /qn
```

---

## Checklist

Use this checklist for deployment:

**Pre-Deployment:**
- [ ] Downloaded IntuneWinAppUtil.exe
- [ ] Verified all files in source\ folder
- [ ] Created .intunewin package
- [ ] Tested in sandbox/VM (optional but recommended)

**Intune Configuration:**
- [ ] Uploaded .intunewin package
- [ ] Configured app information
- [ ] Set install/uninstall commands
- [ ] Configured detection rules (MSI Product Code)
- [ ] Set requirements (64-bit, Windows 10 1607+)
- [ ] Created assignments (pilot group first)

**Monitoring:**
- [ ] Monitored device install status
- [ ] Verified installation on test device
- [ ] Checked cloud/AI lockdown settings
- [ ] Reviewed installation logs

**Post-Deployment:**
- [ ] Communicated to users
- [ ] Documented deployment
- [ ] Scheduled follow-up reviews
- [ ] Created compliance report

---

**Deployment Time Estimate:**
- Packaging: 5 minutes
- Intune configuration: 15 minutes
- Pilot testing: 1-2 days
- Full rollout: 1-2 weeks

**Success Criteria:**
- Installation success rate >95%
- Cloud/AI features confirmed disabled
- No user complaints about functionality
- Zero security incidents related to cloud sync

---

**Questions or Issues?**

Contact your Intune administrator or refer to:
- Microsoft Intune documentation: https://docs.microsoft.com/intune
- Adobe Enterprise deployment guides: https://helpx.adobe.com/enterprise

---

**Last Updated:** November 24, 2025  
**Version:** 1.0  
**Author:** IT Department
