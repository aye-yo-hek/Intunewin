# IntuneWin Packager

Create `.intunewin` packages for Microsoft Intune — as easy as dropping an `.exe` into a folder and running a command.

## Quick Start

```powershell
# 1. Create a new app template
.\New-AppTemplate.ps1 -AppName "MyApp"

# 2. Drop your installer into the created folder
#    apps/MyApp/  <-- place your .exe here

# 3. Edit install.cmd, uninstall.cmd, and detect.ps1 for your app

# 4. Package it
.\Create-IntunePackage.ps1 -AppName "MyApp"

# 5. Upload the .intunewin file from output/ to Microsoft Intune
```

## Project Structure

```
IntuneWin/
├── apps/                          # One folder per application
│   └── MyApp/                     # Your app folder
│       ├── setup.exe              # Your installer (you provide this)
│       ├── install.cmd            # Silent install command
│       ├── uninstall.cmd          # Silent uninstall command
│       └── detect.ps1             # Intune detection script
├── mac/                           # (Future) macOS .pkg packages
├── tools/                         # IntuneWinAppUtil.exe (auto-downloaded)
├── output/                        # Generated .intunewin packages
├── docs/                          # Deployment guides
│   ├── INTUNE-DEPLOYMENT-GUIDE.md
│   └── UPDATING-APPS.md
├── Create-IntunePackage.ps1       # Main packaging script
└── New-AppTemplate.ps1            # App template generator
```

## How It Works

1. **Create an app folder** under `apps/` with your app name
2. **Place your `.exe` installer** in that folder
3. **Configure the scripts** — edit the template `install.cmd`, `uninstall.cmd`, and `detect.ps1` for your specific installer
4. **Run the packager** — it wraps everything into a `.intunewin` file
5. **Upload to Intune** — use the Microsoft Intune admin center to deploy

## Requirements

- Windows 10/11
- PowerShell 5.1+
- Internet connection (for auto-downloading the Win32 Content Prep Tool on first run)

The [Microsoft Win32 Content Prep Tool](https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool) is downloaded automatically on first use. You can also place `IntuneWinAppUtil.exe` in the `tools/` folder manually.

## Creating a New App

```powershell
.\New-AppTemplate.ps1 -AppName "Firefox"
```

This creates `apps/Firefox/` with template scripts you can customize:

| File | Purpose |
|------|---------|
| `install.cmd` | Runs your installer silently |
| `uninstall.cmd` | Removes the application |
| `detect.ps1` | Tells Intune if the app is installed |

## Packaging

```powershell
# Package a specific app
.\Create-IntunePackage.ps1 -AppName "Firefox"

# Interactive mode — choose from available apps
.\Create-IntunePackage.ps1
```

The `.intunewin` file is generated in the `output/` folder, ready to upload to Microsoft Intune.

## Intune Configuration

When uploading to Intune, use these settings:

| Setting | Value |
|---------|-------|
| Install command | `install.cmd` |
| Uninstall command | `uninstall.cmd` |
| Detection rule | Custom script → `detect.ps1` |
| Install behavior | System |
| Return codes | 0 = Success, 1707 = Success, 3010 = Soft reboot, 1641 = Hard reboot |

See [docs/INTUNE-DEPLOYMENT-GUIDE.md](docs/INTUNE-DEPLOYMENT-GUIDE.md) for the full deployment walkthrough.

## Updating an App

Already deployed an app and need to push a new version? See [docs/UPDATING-APPS.md](docs/UPDATING-APPS.md).

## macOS Packages

macOS `.pkg` support is planned for the `mac/` folder. Stay tuned.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

[MIT](LICENSE)
