# Win32 App Development for Microsoft Intune

This workspace is configured for developing Windows desktop applications (.exe files) that can be packaged and deployed through Microsoft Intune.

## Project Structure
- `Apps/<AppName>/Source/` - Installer + install.cmd/uninstall.cmd/detect.ps1 for each app (drop new installers here)
- `Apps/<AppName>/Output/` - Built, versioned .intunewin packages for each app
- `Tools/` - IntuneWinAppUtil.exe and generic build templates (wix/, nsis/)
- `Scripts/` - PowerShell scripts for packaging and testing (Create-IntunePackage.ps1)
- `Docs/` - Documentation and deployment guides not specific to one app

## Development Guidelines
- Use .NET Framework/Core for C# applications
- PowerShell scripts for system automation
- Follow Windows application development best practices
- Ensure applications are compatible with Intune deployment requirements
- Test packaging with Microsoft Win32 Content Prep Tool

## Deployment Process
1. Develop and test Win32 application
2. Package using Microsoft Win32 Content Prep Tool
3. Create .intunewin package
4. Upload and configure in Microsoft Intune admin center
5. Deploy to target device groups