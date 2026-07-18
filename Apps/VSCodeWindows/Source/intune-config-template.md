# VS Code Auto-Update Configuration - Intune Setup

## Quick Deployment Guide

### Method 1: Using ADMX Templates (Recommended for Group Policy Management)

#### Prerequisites
- Access to Microsoft Intune Admin Center
- VS Code installed on at least one machine to extract ADMX templates

#### Steps

1. **Extract ADMX Templates**
   
   On a machine with VS Code installed, locate:
   ```
   C:\Program Files\Microsoft VS Code\resources\app\policies\
   ```
   
   Copy these files:
   - `vscode.admx`
   - `vscode.adml` (from the language-specific subfolder)

2. **Import to Intune (Settings Catalog Method)**
   
   a. Sign in to [Microsoft Intune admin center](https://intune.microsoft.com)
   
   b. Navigate to: **Devices** → **Configuration profiles** → **Create** → **New Policy**
   
   c. Select:
      - **Platform**: Windows 10 and later
      - **Profile type**: Settings catalog
      - Click **Create**
   
   d. **Basics** tab:
      - **Name**: VS Code Auto-Update Policy
      - **Description**: Enables automatic updates for Visual Studio Code
      - Click **Next**
   
   e. **Configuration settings** tab:
      - Click **+ Add settings**
      - Search for: "Visual Studio Code" or "UpdateMode"
      - Expand **Administrative Templates** → **Visual Studio Code**
      - Check the box for **UpdateMode**
      - In the settings pane, set **UpdateMode** to: **default**
      - Click **Next**
   
   f. **Assignments** tab:
      - Select the groups to deploy to (e.g., "All Devices" or "VS Code Users")
      - Click **Next**
   
   g. **Review + create** tab:
      - Review settings
      - Click **Create**

3. **Alternative: Administrative Templates Method**
   
   If Settings Catalog doesn't show VS Code settings:
   
   a. Import ADMX templates:
      - **Devices** → **Configuration** → **Administrative templates** → **Import**
      - Upload `vscode.admx` and `vscode.adml`
   
   b. Create profile:
      - **Devices** → **Configuration profiles** → **Create**
      - **Platform**: Windows 10 and later
      - **Profile type**: Templates → Administrative Templates
      - Configure **Visual Studio Code** → **UpdateMode** → **Enabled** → Value: **default**

4. **Monitor Deployment**
   
   - Go to the policy you created
   - Click **Device status** to see deployment progress
   - Devices typically receive the policy within 8 hours (can be forced with sync)

---

### Method 2: Win32 App Deployment (Registry-Based)

#### Prerequisites
- Microsoft Win32 Content Prep Tool
- Access to Microsoft Intune Admin Center

#### Steps

1. **Create the Package**
   
   ```powershell
   # From the repository root
   .\Create-IntunePackage.ps1 -SourcePath ".\src\VSCodeUpdates" -OutputPath ".\packages"
   ```
   
   Output: `packages\VSCodeUpdates.intunewin`

2. **Upload to Intune**
   
   a. Sign in to [Microsoft Intune admin center](https://intune.microsoft.com)
   
   b. Navigate to: **Apps** → **All apps** → **Add**
   
   c. **Select app type**: Windows app (Win32) → **Select**

3. **Configure App Information**
   
   **App information** tab:
   ```
   Name:               VS Code Auto-Update Configuration
   Description:        Configures Visual Studio Code to automatically download and install updates
   Publisher:          IT Department
   App version:        1.0
   Category:           (Optional) Computer Management
   Show as featured:   No
   Information URL:    https://code.visualstudio.com/docs/setup/enterprise
   Privacy URL:        (Leave blank)
   Developer:          (Leave blank)
   Owner:              (Leave blank)
   Notes:              Configures UpdateMode policy to 'default' via registry
   Logo:               (Optional - upload VS Code icon)
   ```
   
   Click **Next**

4. **Configure Program**
   
   **Program** tab:
   ```
   Install command:            install.cmd
   Uninstall command:          uninstall.cmd
   Install behavior:           System
   Device restart behavior:    No specific action
   Return codes:               (Use defaults)
   ```
   
   Click **Next**

5. **Configure Requirements**
   
   **Requirements** tab:
   ```
   Operating system architecture:      64-bit
   Minimum operating system:           Windows 10 1607
   ```
   
   **Additional requirements**: (Optional)
   - Add requirement rule: File exists
   - Path: `C:\Program Files\Microsoft VS Code\Code.exe`
   - This ensures VS Code is installed before applying the policy
   
   Click **Next**

6. **Configure Detection Rules**
   
   **Detection rules** tab:
   ```
   Rules format:           Use a custom detection script
   Script file:            [Upload detect.ps1]
   Run script as 32-bit:   No
   Enforce script signature check:  No
   ```
   
   Click **Next**

7. **Configure Dependencies**
   
   **Dependencies** tab:
   - (Optional) Add VS Code installation as a dependency if you're also deploying VS Code
   
   Click **Next**

8. **Configure Supersedence**
   
   **Supersedence** tab:
   - Leave blank unless replacing an older version
   
   Click **Next**

9. **Assignments**
   
   **Assignments** tab:
   
   **Required assignments**:
   - Click **+ Add group**
   - Select groups (e.g., "All Devices", "VS Code Users", or "Developers")
   - **End user notifications**: Hide all toast notifications
   
   **Available for enrolled devices**: (Optional)
   - Add groups if you want users to install on-demand
   
   Click **Next**

10. **Review + Create**
    
    - Review all settings
    - Click **Create**

11. **Monitor Deployment**
    
    - Go to **Apps** → **All apps** → **VS Code Auto-Update Configuration**
    - Click **Device install status**
    - Monitor installation progress

---

## Verification

### On Managed Device

1. **Check Registry**:
   ```powershell
   Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Code" -Name UpdateMode
   ```
   
   Expected output:
   ```
   UpdateMode : default
   ```

2. **Check in VS Code**:
   - Open VS Code
   - Press `Ctrl+,` (Settings)
   - Search: `update.mode`
   - Should show: "Setting is managed by your organization"
   - Value: `default`

3. **Test Detection Script Locally**:
   ```powershell
   C:\Path\To\detect.ps1
   echo $LASTEXITCODE
   # Should output: 0 (success)
   ```

---

## Configuration Options

### UpdateMode Values

| Value | Behavior |
|-------|----------|
| `default` | ✅ Automatic background updates (recommended) |
| `start` | Check for updates only when VS Code starts |
| `manual` | User must manually check for updates |
| `none` | Disable all automatic updates |

To change the behavior, modify the value in:
- **ADMX method**: Change policy value in Settings Catalog
- **Win32 app method**: Edit `install.ps1` and change `$PolicyValue = "default"` to desired value, then repackage

---

## Troubleshooting

### Policy Not Showing in Settings Catalog

If you don't see VS Code settings in Settings Catalog:
1. Ensure ADMX templates are from VS Code 1.67 or later
2. Use the Administrative Templates method instead
3. Or use the Win32 app method (doesn't require ADMX import)

### Device Not Receiving Policy

1. Force device sync:
   - **Devices** → **All devices** → Select device → **Sync**

2. Check policy assignment:
   - Verify device is in assigned group
   - Check for conflicting policies

3. Review Intune logs on device:
   ```powershell
   # View recent Intune activity
   Get-WinEvent -LogName "Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin" -MaxEvents 50
   ```

### Installation Failed (Win32 App)

1. Check Intune Management Extension logs:
   ```
   C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log
   ```

2. Common issues:
   - Detection script failing (exit code should be 0)
   - Insufficient permissions (ensure System install behavior)
   - VS Code not installed (add as requirement)

### Updates Not Working After Policy Applied

1. Verify network connectivity to update servers:
   ```powershell
   Test-NetConnection -ComputerName update.code.visualstudio.com -Port 443
   ```

2. Check VS Code version supports auto-updates:
   ```powershell
   & "C:\Program Files\Microsoft VS Code\Code.exe" --version
   ```

3. Manually trigger update check in VS Code:
   - Press `Ctrl+Shift+P`
   - Type: "Check for Updates"
   - See if updates are detected

---

## Rolling Back

### ADMX Method
1. Delete or disable the configuration profile in Intune
2. Devices will revert to default VS Code behavior on next policy refresh

### Win32 App Method
1. In Intune, go to the app
2. Change assignment from **Required** to **Uninstall**
3. Or manually remove registry key:
   ```powershell
   Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Code" -Name UpdateMode
   ```

---

## Additional Resources

- [VS Code Enterprise Documentation](https://code.visualstudio.com/docs/setup/enterprise)
- [Intune Win32 App Management](https://learn.microsoft.com/en-us/mem/intune/apps/apps-win32-app-management)
- [Settings Catalog](https://learn.microsoft.com/en-us/mem/intune/configuration/settings-catalog)

---

**Deployment Time**: ~15 minutes  
**Typical Rollout**: 2-8 hours across organization  
**User Impact**: None (silent background process)
