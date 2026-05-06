# Updating an App in Intune

How to push a new version of an application that's already deployed through Intune.

## Steps

### 1. Replace the Installer

Drop the new `.exe` into your app folder, replacing the old one:

```
apps/MyApp/
├── NewVersion-Setup.exe    ← new installer
├── install.cmd
├── uninstall.cmd
└── detect.ps1
```

### 2. Update Your Scripts (if needed)

- **install.cmd** — Update the installer filename if it changed
- **uninstall.cmd** — Update if the uninstall GUID or method changed
- **detect.ps1** — Update the version number or detection path if the new version installs to a different location

### 3. Repackage

```powershell
.\Create-IntunePackage.ps1 -AppName "MyApp"
```

This overwrites the previous `.intunewin` file in `output/`.

### 4. Update in Intune

1. Go to [Microsoft Intune admin center](https://intune.microsoft.com)
2. Navigate to **Apps** > **All apps**
3. Find your existing app and click on it
4. Click **Properties**
5. Next to **App information**, click **Edit**
6. Update the **version** field
7. Next to **Program**, click **Edit**
8. Click the **App package file** link and upload the new `.intunewin` file
9. Click **Review + save**

> **Note:** You do NOT need to create a new app entry. Updating the existing one preserves your group assignments and deployment history.

### 5. Monitor the Rollout

- Go to **Apps** > **Monitor** > **App install status**
- Devices will pick up the update on their next Intune sync (typically every 8 hours, or on next check-in)
- Force a sync on a test device: **Settings** > **Accounts** > **Access work or school** > **Info** > **Sync**

## Tips

- **Detection script matters most** — If your `detect.ps1` checks for a specific version, Intune will automatically reinstall when the detection fails after you update it
- **Supersedence** — For major version changes (e.g., v1.x to v2.x), consider using Intune's **Supersedence** feature instead of updating in-place. This lets you uninstall the old version before installing the new one
- **Test first** — Assign the updated app to a test group before rolling out broadly
