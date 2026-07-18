# VS Code Auto-Update Configuration for Intune

This package configures Visual Studio Code to automatically check for and install updates using the `UpdateMode` policy.

## What This Does

Configures the VS Code `UpdateMode` policy to `default`, which:
- ✅ Automatically checks for updates in the background
- ✅ Downloads new versions automatically
- ✅ Installs updates automatically
- ✅ Prompts users to restart VS Code when updates are ready
- ✅ Applies to all users on the device

## Deployment Methods

### Option 1: ADMX-Based Policy (Recommended for Large Enterprises)

If you want to use Group Policy ADMX templates via Intune Administrative Templates:

#### Step 1: Get the ADMX Templates

1. On a machine with VS Code installed, locate the policy templates:
   ```
   C:\Program Files\Microsoft VS Code\resources\app\policies\
   ```
   or
   ```
   %LOCALAPPDATA%\Programs\Microsoft VS Code\resources\app\policies\
   ```

2. Copy these files:
   - `vscode.admx`
   - `vscode.adml` (from the appropriate language folder)

#### Step 2: Import to Intune

**Method A: Settings Catalog (Modern)**
1. In Intune Portal → **Devices** → **Configuration profiles**
2. Click **Create profile**
3. Platform: **Windows 10 and later**
4. Profile type: **Settings catalog**
5. Search for "VS Code" or "Visual Studio Code"
6. Find and configure **UpdateMode** setting
7. Set value to: **default**
8. Assign to device groups

**Method B: Administrative Templates (Traditional)**
1. Upload ADMX files to Intune:
   - Intune Portal → **Devices** → **Configuration profiles** → **Import ADMX**
2. Create new configuration profile:
   - Profile type: **Administrative Templates**
3. Find **Visual Studio Code** → **UpdateMode**
4. Set to: **Enabled** with value **default**
5. Assign to device groups

### Option 2: Win32 App Deployment (This Package)

Use the provided PowerShell scripts to deploy via Intune Win32 app:

#### Advantages
- ✅ No ADMX template management needed
- ✅ Works immediately without additional setup
- ✅ Includes detection logic for compliance
- ✅ Easy rollback with uninstall script

#### Files Included
- `install.cmd` - Entry point for installation
- `install.ps1` - PowerShell script that configures registry policy
- `uninstall.cmd` - Entry point for removal
- `uninstall.ps1` - Removes the policy configuration
- `detect.ps1` - Detection script for Intune

## Quick Start - Win32 App Deployment

### Step 1: Create the Intune Package

```powershell
# Run from the repository root
.\Create-IntunePackage.ps1 -SourcePath ".\src\VSCodeUpdates" -OutputPath ".\packages"
```

This creates: `packages\VSCodeUpdates.intunewin`

### Step 2: Upload to Intune

1. Navigate to **Intune Portal** → **Apps** → **Windows** → **Add**
2. Select **Windows app (Win32)**

#### Basic Information
- **Name**: VS Code Auto-Update Configuration
- **Description**: Configures Visual Studio Code to automatically check for and install updates
- **Publisher**: IT Department

#### Program Settings
- **Install command**: `install.cmd`
- **Uninstall command**: `uninstall.cmd`
- **Install behavior**: System
- **Device restart behavior**: No specific action

#### Requirements
- **Operating system architecture**: 64-bit
- **Minimum operating system**: Windows 10 1607

#### Detection Rules
- **Rules format**: Use a custom detection script
- **Script file**: Upload `detect.ps1`
- **Run script as 32-bit**: No
- **Enforce signature check**: No

#### Return Codes
Use default return codes (0 = Success, 1707 = Success)

### Step 3: Assign

1. **Required** assignment to device groups where VS Code is deployed
2. This ensures the policy is applied to all managed devices

## Registry Configuration Details

The script configures the following registry setting:

```
Path:  HKLM\SOFTWARE\Policies\Microsoft\Code
Name:  UpdateMode
Type:  REG_SZ
Value: default
```

### UpdateMode Values

- `default` - Auto-check and install (recommended)
- `start` - Check only on VS Code startup
- `manual` - User must manually check
- `none` - Disable all updates

## Testing

### Local Testing

Test the installation locally before deploying:

```powershell
# Test installation
.\src\VSCodeUpdates\install.cmd

# Verify detection
.\src\VSCodeUpdates\detect.ps1
echo $LASTEXITCODE  # Should be 0 if successful

# Test uninstallation
.\src\VSCodeUpdates\uninstall.cmd
```

### Verify in VS Code

1. Open Visual Studio Code
2. Go to **File** → **Preferences** → **Settings**
3. Search for "update mode"
4. The setting should show: **"Managed by your organization"**
5. The value should be: **default**

Or check via registry:

```powershell
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Code" -Name UpdateMode
```

## Compliance and Monitoring

### Check Deployment Status

In Intune Portal:
1. Navigate to **Apps** → **Windows**
2. Select **VS Code Auto-Update Configuration**
3. Click **Device install status**
4. Review installation status across devices

### Create Compliance Policy (Optional)

Create a custom compliance policy to ensure the setting stays configured:

1. **Devices** → **Compliance policies** → **Create Policy**
2. Platform: **Windows 10 and later**
3. Add custom script detection using `detect.ps1`

## User Impact

- **No UI changes** - Users won't see any difference in VS Code behavior
- **Automatic updates** - VS Code will update silently in the background
- **Restart prompt** - Users will be notified when a restart is needed to complete an update
- **Cannot override** - Users cannot change this setting as it's managed by policy

## Troubleshooting

### Policy Not Applied

1. Verify the registry key exists:
   ```powershell
   Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Code"
   Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Code"
   ```

2. Check Intune app installation logs:
   - Location: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\`
   - File: `IntuneManagementExtension.log`

3. Verify VS Code version supports policies:
   - UpdateMode policy available since VS Code 1.67
   - Check VS Code version: `code --version`

### Updates Still Not Working

1. Verify VS Code can reach update servers:
   - Required domain: `update.code.visualstudio.com`
   - Check firewall/proxy settings

2. Check VS Code update channel:
   - Ensure not using the "Insiders" build if targeting stable updates

### Remove Policy for Testing

```powershell
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Code" -Name UpdateMode -Force
```

Then restart VS Code.

## Additional Policies

You can extend this deployment to configure other VS Code policies:

- **TelemetryLevel** - Control telemetry data collection
- **AllowedExtensions** - Restrict which extensions can be installed
- **EnableFeedback** - Enable/disable feedback mechanisms

See the [VS Code Enterprise Documentation](https://code.visualstudio.com/docs/setup/enterprise) for all available policies.

## Related Resources

- [VS Code Enterprise Support](https://code.visualstudio.com/docs/setup/enterprise)
- [VS Code Update Documentation](https://code.visualstudio.com/docs/supporting/faq#_how-do-i-opt-out-of-vs-code-autoupdates)
- [Microsoft Intune Win32 App Management](https://learn.microsoft.com/en-us/mem/intune/apps/apps-win32-app-management)

## Support

For issues with this deployment package, check:
1. Intune deployment logs
2. Windows Event Viewer → Application logs
3. VS Code settings to verify policy is active

---

**Version**: 1.0  
**Last Updated**: November 21, 2025  
**Compatibility**: VS Code 1.67+, Windows 10/11
