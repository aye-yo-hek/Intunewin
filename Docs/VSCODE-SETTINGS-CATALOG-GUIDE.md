# VS Code Auto-Update via Intune Settings Catalog

## Quick Deployment Guide - Settings Catalog Method

This is the **simplest and recommended method** for configuring VS Code to automatically download and install updates.

---

## What You'll Configure

**Policy**: `UpdateMode`  
**Value**: `default` (enables automatic background updates and installation)

**Effect**: VS Code will automatically:
- ✅ Check for updates in the background
- ✅ Download new versions automatically
- ✅ Install updates automatically
- ✅ Prompt users to restart when ready

---

## Step-by-Step Deployment

### Step 1: Sign in to Intune

1. Go to [Microsoft Intune Admin Center](https://intune.microsoft.com)
2. Sign in with your admin credentials

### Step 2: Create Configuration Profile

1. Navigate to: **Devices** → **Configuration** → **Policies** (or **Configuration profiles**)

2. Click **+ Create** or **+ Create profile**

3. Select:
   - **Platform**: Windows 10 and later
   - **Profile type**: Settings catalog
   - Click **Create**

### Step 3: Configure Basic Information

On the **Basics** tab:
- **Name**: `VS Code - Auto Update Configuration`
- **Description**: `Enables automatic download and installation of VS Code updates`
- Click **Next**

### Step 4: Add Settings

On the **Configuration settings** tab:

1. Click **+ Add settings**

2. In the settings picker, you have two options:

   **Option A: If VS Code shows in the catalog**
   - Search for: `Visual Studio Code` or `UpdateMode`
   - Browse to: **Administrative Templates** → **Visual Studio Code**
   - Check the box next to **Update Mode** or **UpdateMode**
   - Close the picker

   **Option B: If VS Code doesn't appear (most common)**
   - You'll need to configure via registry instead - see Alternative Method below

3. Once the setting is added:
   - In the settings pane on the right, locate **Update Mode**
   - Set the value to: **`default`**

4. Click **Next**

### Step 5: Scope Tags (Optional)

- Add scope tags if your organization uses them
- Click **Next**

### Step 6: Assignments

1. Under **Assign to**, select **Add groups** or **Add all devices**

2. Recommended options:
   - **All Devices** - if all devices have VS Code
   - **Specific Groups** - target only devices/users with VS Code installed
   
   Example groups:
   - "Developers - All"
   - "VS Code Users"
   - "Engineering Department"

3. Click **Next**

### Step 7: Review + Create

1. Review all your settings:
   ```
   Name: VS Code - Auto Update Configuration
   Platform: Windows 10 and later
   Profile type: Settings catalog
   Setting: UpdateMode = default
   Assigned to: [Your selected groups]
   ```

2. Click **Create**

---

## Alternative Method: Custom Registry Configuration

If **VS Code policies don't appear in Settings Catalog**, use this registry-based approach:

### Option 1: Settings Catalog with Custom Registry

1. Create a new **Settings catalog** profile (follow steps 1-3 above)

2. In **Configuration settings**:
   - Click **+ Add settings**
   - Search for: `Registry`
   - Browse to: **Registry** → **Add registry setting**
   - Configure:
     ```
     Key Path:      SOFTWARE\Policies\Microsoft\Code
     Value Name:    UpdateMode
     Value Type:    String
     Value Data:    default
     ```

3. Continue with Assignment and Create

### Option 2: Custom Configuration Profile (OMA-URI)

1. Create profile: **Devices** → **Configuration** → **Create**
   - Platform: Windows 10 and later
   - Profile type: **Templates** → **Custom**

2. Add OMA-URI Setting:
   ```
   Name:          VS Code UpdateMode
   Description:   Enable automatic updates
   OMA-URI:       ./Device/Vendor/MSFT/Policy/Config/ADMX_VSCode/UpdateMode
   Data type:     String
   Value:         <enabled/><data id="UpdateMode" value="default"/>
   ```
   
   OR use registry OMA-URI:
   ```
   OMA-URI:       ./Device/Vendor/MSFT/Registry/HKLM/SOFTWARE/Policies/Microsoft/Code/UpdateMode
   Data type:     String
   Value:         default
   ```

3. Assign and create

---

## Verification

### Check Deployment Status in Intune

1. Navigate to **Devices** → **Configuration** → **Policies**
2. Click on: **VS Code - Auto Update Configuration**
3. Click **Device status** to see deployment progress
4. Wait for devices to sync (typically within 8 hours, or force sync)

### Verify on a Managed Device

#### Method 1: Check in VS Code
1. Open Visual Studio Code
2. Press `Ctrl + ,` (or File → Preferences → Settings)
3. Search for: `update.mode`
4. You should see:
   - ✅ "Setting is managed by your organization"
   - Value shows: `default`

#### Method 2: Check Registry
Open PowerShell and run:
```powershell
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Code" -Name UpdateMode
```

Expected output:
```
UpdateMode : default
```

#### Method 3: Check Group Policy Result
```powershell
# View applied policies
gpresult /r /scope computer
```

Look for VS Code policies in the output.

---

## Troubleshooting

### Issue: VS Code Settings Not in Settings Catalog

**Cause**: ADMX templates may not be imported to Intune yet

**Solution**: Use the Alternative Method (Custom Registry or OMA-URI) shown above

### Issue: Policy Not Applying to Devices

**Check these:**

1. **Device Sync**:
   - Devices → All devices → Select device → Sync
   - Wait 5-10 minutes for policy to apply

2. **Assignment**:
   - Verify device/user is in assigned group
   - Check assignment filters aren't blocking

3. **Device Compliance**:
   - Ensure device is enrolled and compliant
   - Check last check-in time

4. **VS Code Version**:
   ```powershell
   code --version
   ```
   Must be version 1.67 or later (UpdateMode policy introduced in 1.67)

### Issue: Users Can Still Change Update Settings

**Expected Behavior**: When managed by policy, users cannot override the setting.

**If users can still change it:**
- Registry key may not be in the correct location (must be `HKLM\SOFTWARE\Policies\...`)
- Policy hasn't applied yet (check deployment status)
- Conflicting user-level policy

### Issue: Updates Still Not Installing

1. **Check network connectivity**:
   ```powershell
   Test-NetConnection -ComputerName update.code.visualstudio.com -Port 443
   ```

2. **Verify no proxy/firewall blocking**:
   - Domain required: `update.code.visualstudio.com`
   - Port: 443 (HTTPS)

3. **Check VS Code update channel**:
   - Ensure using stable VS Code, not Insiders build
   - Check: Help → About in VS Code

4. **Manually trigger update**:
   - In VS Code: Help → Check for Updates
   - Should show "Checking for updates..." then download if available

---

## Understanding UpdateMode Values

| Value | Behavior | Use Case |
|-------|----------|----------|
| **`default`** | ✅ Automatic background updates | **Recommended** - keeps VS Code current |
| `start` | Check only on startup | Less frequent checks, more user control |
| `manual` | User must manually check | High security environments, controlled updates |
| `none` | Disable all updates | Air-gapped environments, manual update process |

---

## Additional Configuration (Optional)

You can configure other VS Code policies in the same Settings Catalog profile:

### Telemetry Control
- **Policy**: `TelemetryLevel`
- **Values**: `all`, `error`, `crash`, `off`
- **Recommendation**: `error` (balance between privacy and diagnostics)

### Extension Control
- **Policy**: `AllowedExtensions`
- **Value**: JSON string defining allowed extensions
- **Example**: `{"microsoft": true, "github": true}`

### Disable Feedback
- **Policy**: `EnableFeedback`
- **Value**: `false` (disables issue reporter and surveys)

To add these, simply add more settings to your existing profile.

---

## Rollback

To remove the auto-update policy:

1. **Option 1 - Delete Profile**:
   - Devices → Configuration → Policies
   - Select the profile
   - Click **Delete**
   - Devices will revert to default behavior

2. **Option 2 - Remove Assignment**:
   - Edit the profile
   - Go to Assignments
   - Remove all group assignments
   - Policy will no longer apply

3. **Option 3 - Change Value**:
   - Edit the profile
   - Change UpdateMode to `manual` or `none`
   - Save changes

---

## Timeline

- **Configuration time**: 5-10 minutes
- **Policy propagation**: 2-8 hours (or immediate with device sync)
- **User impact**: None (transparent to users)
- **Restart required**: No (policy applies on next VS Code start)

---

## Support Resources

- [VS Code Enterprise Documentation](https://code.visualstudio.com/docs/setup/enterprise)
- [Intune Settings Catalog](https://learn.microsoft.com/en-us/mem/intune/configuration/settings-catalog)
- [VS Code Update Documentation](https://code.visualstudio.com/docs/supporting/faq#_how-do-i-opt-out-of-vs-code-autoupdates)

---

## Summary

✅ **Simplest method**: Settings Catalog with native VS Code policies  
✅ **Fallback method**: Settings Catalog with custom registry settings  
✅ **No packaging required**: Everything configured in Intune UI  
✅ **No scripts needed**: Pure policy-based configuration  
✅ **Automatic compliance**: Policy enforced at system level  

---

## macOS Deployment

For macOS devices, use **Configuration Profiles** instead of ADMX templates.

### Step 1: Get the Sample Configuration Profile

VS Code includes a sample `.mobileconfig` file:

**Location on Mac**:
```
/Applications/Visual Studio Code.app/Contents/Resources/app/policies/
```

Or download from a Windows installation if you have VS Code installed.

### Step 2: Create/Edit the .mobileconfig File

Create a file named `vscode-autoupdate.mobileconfig`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>PayloadContent</key>
    <array>
        <dict>
            <key>PayloadDisplayName</key>
            <string>Visual Studio Code Auto-Update</string>
            <key>PayloadIdentifier</key>
            <string>com.microsoft.VSCode.policy</string>
            <key>PayloadType</key>
            <string>com.microsoft.VSCode</string>
            <key>PayloadUUID</key>
            <string>A1B2C3D4-E5F6-7890-ABCD-EF1234567890</string>
            <key>PayloadVersion</key>
            <integer>1</integer>
            
            <!-- Enable Automatic Updates -->
            <key>UpdateMode</key>
            <string>default</string>
        </dict>
    </array>
    <key>PayloadDescription</key>
    <string>Configures Visual Studio Code to automatically download and install updates</string>
    <key>PayloadDisplayName</key>
    <string>VS Code Auto-Update Policy</string>
    <key>PayloadIdentifier</key>
    <string>com.yourcompany.vscode.autoupdate</string>
    <key>PayloadOrganization</key>
    <string>Your Organization</string>
    <key>PayloadRemovalDisallowed</key>
    <false/>
    <key>PayloadScope</key>
    <string>System</string>
    <key>PayloadType</key>
    <string>Configuration</string>
    <key>PayloadUUID</key>
    <string>B2C3D4E5-F6A7-8901-BCDE-F12345678901</string>
    <key>PayloadVersion</key>
    <integer>1</integer>
</dict>
</plist>
```

**Important**: Replace the UUIDs with new unique ones:
```bash
uuidgen
```

### Step 3: Deploy via Intune

#### Option A: Device Configuration Profile

1. Sign in to [Microsoft Intune Admin Center](https://intune.microsoft.com)

2. Navigate to: **Devices** → **Configuration** → **Create** → **New Policy**

3. Select:
   - **Platform**: macOS
   - **Profile type**: Templates → **Custom**
   - Click **Create**

4. **Basics** tab:
   - **Name**: `VS Code - Auto Update (macOS)`
   - **Description**: `Enables automatic updates for VS Code on macOS`
   - Click **Next**

5. **Configuration settings** tab:
   - **Custom configuration profile name**: `VS Code Auto Update`
   - **Deployment channel**: Device channel
   - **Configuration profile file**: Upload your `vscode-autoupdate.mobileconfig`
   - Click **Next**

6. **Assignments** tab:
   - Select macOS device groups or users
   - Click **Next**

7. **Review + Create**

#### Option B: Shell Script (Alternative)

If you prefer a script approach:

1. **Devices** → **macOS** → **Scripts** → **Add**

2. Create `configure-vscode-autoupdate.sh`:
```bash
#!/bin/bash
# Configure VS Code Auto-Update on macOS

PLIST_PATH="/Library/Preferences/com.microsoft.VSCode.plist"

# Set UpdateMode to default
defaults write /Library/Preferences/com.microsoft.VSCode UpdateMode -string "default"

# Verify
if [ "$(defaults read /Library/Preferences/com.microsoft.VSCode UpdateMode 2>/dev/null)" = "default" ]; then
    echo "VS Code UpdateMode successfully configured"
    exit 0
else
    echo "Failed to configure VS Code UpdateMode"
    exit 1
fi
```

3. Configure:
   - **Run script as signed-in user**: No
   - **Hide script notifications**: Yes
   - **Script frequency**: Once
   - **Max retries**: 3

### Step 4: Verify on macOS

**Check via Terminal**:
```bash
# Check preference setting
defaults read /Library/Preferences/com.microsoft.VSCode UpdateMode

# Expected output: default
```

**Check in VS Code**:
1. Open VS Code
2. Preferences → Settings (⌘,)
3. Search: `update.mode`
4. Should show "Managed by your organization"

### macOS-Specific Notes

- **Scope**: Use `System` scope to apply to all users
- **Removal**: Set `PayloadRemovalDisallowed` to `true` to prevent users from removing
- **MDM Required**: Devices must be enrolled in Intune MDM
- **Privacy**: macOS may require additional permissions for management

---

**Created**: November 21, 2025  
**VS Code Version**: 1.67+ (UpdateMode policy support)  
**Intune Feature**: Settings Catalog / Configuration Profiles  
**Platforms**: Windows (ADMX/Registry), macOS (Configuration Profile)
