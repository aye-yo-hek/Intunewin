# MSI Builders

This folder contains templates and tools for building Windows installers (MSI and EXE) for deployment via Intune.

## Contents

### `/wix` - WiX Toolset (MSI Builder)
- Creates native Windows Installer (.msi) packages
- Industry standard, Microsoft-recommended
- Full Windows Installer features
- Best for: Complex installations, enterprise deployments

### `/nsis` - Nullsoft Scriptable Install System
- Creates executable installers (.exe)
- Lightweight and flexible
- Can be converted to MSI if needed
- Best for: Simple applications, custom workflows

## Quick Start

Choose the tool based on your needs:

| Feature | WiX | NSIS |
|---------|-----|------|
| Output Format | .msi | .exe (can wrap as .msi) |
| Complexity | Medium-High | Low-Medium |
| Windows Installer | Native | Wrapper |
| Intune Support | Excellent | Good (via Win32) |
| Learning Curve | Steeper | Easier |

## Prerequisites

### For WiX
- **WiX Toolset 3.x or 4.x**: https://wixtoolset.org/
- Visual Studio (optional, for advanced features)
- .NET Framework

### For NSIS
- **NSIS 3.x**: https://nsis.sourceforge.io/
- Text editor (VS Code works great)

## Next Steps

1. Navigate to the appropriate folder (`wix` or `nsis`)
2. Read the README in that folder
3. Customize the template for your application
4. Build your installer
5. Test locally
6. Package with IntuneWinAppUtil
7. Deploy via Intune

---

**Created**: November 24, 2025  
**Purpose**: Intune MSI/EXE creation and deployment
