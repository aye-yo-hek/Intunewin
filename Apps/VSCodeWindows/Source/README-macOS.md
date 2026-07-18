# VS Code Auto-Update Configuration for macOS

## Deployment Options for macOS

macOS uses **Configuration Profiles** (`.mobileconfig`) instead of ADMX templates.

---

## Option 1: Configuration Profile (Recommended)

### What You Need
- `vscode-autoupdate.mobileconfig` file (included in this folder)
- Intune admin access
- macOS devices enrolled in Intune MDM

### Step-by-Step Deployment

#### 1. Customize the Configuration Profile (Optional)

Edit `vscode-autoupdate.mobileconfig` if needed:
- Update `PayloadOrganization` with your company name
- Generate new UUIDs (run `uuidgen` on Mac/Linux or use an online UUID generator)
- Optionally enable additional policies (telemetry, feedback - see comments in file)

#### 2. Deploy via Intune

**A. Sign in to Intune**
1. Go to [Microsoft Intune Admin Center](https://intune.microsoft.com)

**B. Create Configuration Profile**
1. Navigate to: **Devices** → **Configuration** → **Create** → **New Policy**

2. Select:
   - **Platform**: macOS
   - **Profile type**: Templates → **Custom**
   - Click **Create**

3. **Basics** tab:
   ```
   Name:        VS Code - Auto Update (macOS)
   Description: Enables automatic updates for Visual Studio Code on macOS devices
   ```
   Click **Next**

4. **Configuration settings** tab:
   ```
   Custom configuration profile name: VS Code Auto Update
   Deployment channel:                 Device channel
   Configuration profile file:         [Upload vscode-autoupdate.mobileconfig]
   ```
   Click **Next**

5. **Scope tags** (optional):
   - Add if your organization uses scope tags
   Click **Next**

6. **Assignments** tab:
   - **Include**: Add groups with macOS devices/users
     - Example: "macOS Devices - All"
     - Example: "Developers - macOS"
   - **Exclude**: (Optional) Exclude specific groups
   Click **Next**

7. **Review + create**:
   - Review all settings
   - Click **Create**

#### 3. Monitor Deployment

1. Go to: **Devices** → **Configuration** → Select your profile
2. Click **Device status** to see installation progress
3. Typical deployment time: 2-8 hours (or force sync on device)

---

## Option 2: Shell Script Deployment

If you prefer using scripts instead of configuration profiles:

### Step-by-Step

#### 1. Upload Script to Intune

**A. Navigate to Scripts**
1. **Devices** → **macOS** → **Scripts** → **Add**

**B. Configure Script**
1. **Basics** tab:
   ```
   Name:        VS Code Auto-Update Configuration
   Description: Sets UpdateMode policy to enable automatic updates
   ```
   Click **Next**

2. **Script settings** tab:
   ```
   Script file:                    [Upload configure-vscode-autoupdate-macos.sh]
   Run script as signed-in user:   No
   Hide script notifications:      Yes
   Script frequency:               Once
   Max number of times to retry:   3
   ```
   Click **Next**

3. **Assignments** tab:
   - Select macOS device groups
   Click **Next**

4. **Review + create**

#### 2. Optional: Add Detection Script

For ongoing compliance monitoring:

1. **Devices** → **macOS** → **Scripts** → **Add**
2. Upload `detect-macos.sh`
3. Configure to run periodically (e.g., daily)
4. View compliance in script execution reports

---

## Verification on macOS

### Method 1: Check via Terminal

```bash
# Check the preference setting
defaults read /Library/Preferences/com.microsoft.VSCode UpdateMode

# Expected output: default
```

### Method 2: Check in VS Code

1. Open Visual Studio Code
2. Go to: **Code** → **Preferences** → **Settings** (or press `⌘,`)
3. Search for: `update.mode`
4. Should display:
   - "Setting is managed by your organization"
   - Value: `default`

### Method 3: View Configuration Profile

```bash
# List installed configuration profiles
sudo profiles list

# Show details of VS Code profile
sudo profiles show -type configuration
```

---

## Configuration Profile Details

The `.mobileconfig` file configures:

**Primary Setting**:
```xml
<key>UpdateMode</key>
<string>default</string>
```

**Storage Location**: `/Library/Preferences/com.microsoft.VSCode.plist`

**Scope**: System-wide (all users)

### UpdateMode Values

| Value | Behavior |
|-------|----------|
| `default` | ✅ Automatic background updates (recommended) |
| `start` | Check only on VS Code startup |
| `manual` | User must manually check |
| `none` | Disable all updates |

---

## Additional Policies (Optional)

You can add these to the same `.mobileconfig` file:

### Control Telemetry
```xml
<key>TelemetryLevel</key>
<string>error</string>
<!-- Options: all, error, crash, off -->
```

### Disable Feedback
```xml
<key>EnableFeedback</key>
<false/>
```

### Restrict Extensions
```xml
<key>AllowedExtensions</key>
<string>{"microsoft": true, "github": true}</string>
```

---

## Troubleshooting

### Profile Not Installing

**Check enrollment status**:
```bash
sudo profiles status
```

**Force profile installation**:
1. On device: **System Settings** → **Privacy & Security** → **Profiles**
2. Or force sync from Intune portal

**View installation logs**:
```bash
log show --predicate 'subsystem == "com.apple.ManagedClient"' --last 1h
```

### Policy Not Applying

**Verify profile is installed**:
```bash
sudo profiles list | grep -i vscode
```

**Check preference file**:
```bash
defaults read /Library/Preferences/com.microsoft.VSCode
```

**Restart VS Code**:
```bash
killall "Visual Studio Code"
# Then reopen VS Code
```

### Users Can Still Change Settings

**Expected**: When managed by configuration profile, users cannot override.

**If users can change**:
- Profile may not be installed (check `sudo profiles list`)
- Profile scope might be "User" instead of "System"
- VS Code version too old (need 1.99+ for macOS policy support)

### Updates Not Installing

**Check network connectivity**:
```bash
curl -I https://update.code.visualstudio.com
```

**Check VS Code version**:
```bash
code --version
# Must be 1.99 or later for macOS configuration profile support
```

**Manually trigger update**:
- In VS Code: **Code** → **Check for Updates**

---

## Comparison: Profile vs. Script

| Method | Pros | Cons |
|--------|------|------|
| **Configuration Profile** | ✅ Native MDM management<br>✅ Automatic removal<br>✅ Better compliance reporting | Requires MDM enrollment<br>More complex XML syntax |
| **Shell Script** | ✅ Simpler to understand<br>✅ More flexible<br>✅ Easier to modify | Manual cleanup needed<br>Less integrated with MDM |

**Recommendation**: Use **Configuration Profile** for enterprise deployments, **Shell Script** for quick testing or specific use cases.

---

## Platform Comparison

| Feature | Windows (ADMX) | macOS (Config Profile) |
|---------|----------------|------------------------|
| **Method** | Settings Catalog | Custom Profile |
| **File Type** | Registry/ADMX | .mobileconfig |
| **Deployment** | Intune Config Profile | Intune Config Profile |
| **Policy Path** | `HKLM\SOFTWARE\Policies\...` | `/Library/Preferences/...` |
| **VS Code Version** | 1.67+ | 1.99+ |

---

## Files Included

- ✅ `vscode-autoupdate.mobileconfig` - Configuration profile for Intune
- ✅ `configure-vscode-autoupdate-macos.sh` - Shell script alternative
- ✅ `detect-macos.sh` - Detection/compliance script
- ✅ `README-macOS.md` - This documentation

---

## Next Steps

1. **Choose deployment method**:
   - Configuration Profile (recommended) OR Shell Script

2. **For Configuration Profile**:
   - Customize `vscode-autoupdate.mobileconfig` if needed
   - Upload to Intune (Devices → Configuration → Custom profile)
   - Assign to macOS device groups

3. **For Shell Script**:
   - Upload `configure-vscode-autoupdate-macos.sh` to Intune
   - Configure as system-level script
   - Assign to macOS device groups

4. **Verify**:
   - Check deployment status in Intune
   - Test on a macOS device
   - Verify policy in VS Code settings

---

**Platform**: macOS 10.15+  
**VS Code Version**: 1.99+ (configuration profile support)  
**Intune**: Custom Configuration Profile or Shell Scripts  
**Last Updated**: November 21, 2025
