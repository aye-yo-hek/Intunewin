# Quick Reference: Intune Commands

## AXCodeSetup

### Intune Configuration:
- **Install command**: `install.cmd`
- **Uninstall command**: `uninstall.cmd`

### Actual Commands Executed:
- **Install**: `axcodesetup.exe /S`
- **Uninstall**: `axcodesetup.exe /S /uninstall`

### Detection Rule:
- **Registry**: `HKLM\SOFTWARE\YourCompany\IntuneApps\AXCodeSetup = "Installed"`

---

## Python 3.14

### Intune Configuration:
- **Install command**: `install.cmd`
- **Uninstall command**: `uninstall.cmd`

### Actual Commands Executed:
- **Install**: `python-3.14.0-amd64.exe /quiet InstallAllUsers=1 PrependPath=1`
- **Uninstall**: Uses Windows uninstaller + cleanup

### Detection Rule:
- **Registry**: `HKLM\SOFTWARE\YourCompany\IntuneApps\Python314 = "Installed"`

---

## Notes:
- In Intune, you always use the wrapper scripts (`install.cmd`, `uninstall.cmd`)
- The wrapper scripts handle the actual installer commands and detection registry entries
- This provides consistency and error handling across all deployments