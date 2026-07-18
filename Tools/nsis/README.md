# NSIS - Executable Installer Builder

Build lightweight Windows installers (.exe) using NSIS (Nullsoft Scriptable Install System).

## Prerequisites

**Install NSIS:**
- **Download**: https://nsis.sourceforge.io/Download
- **Version**: 3.x recommended
- **Plugins** (optional): https://nsis.sourceforge.io/Category:Plugins

## Project Structure

```
nsis/
├── installer.nsi         # Main NSIS script
├── Build-Installer.ps1   # PowerShell build script
├── license.txt           # License/EULA text
├── source/               # Place your application files here
│   ├── YourApp.exe
│   └── ...
└── README.md             # This file
```

Output goes to: `..\output\YourAppSetup.exe`

## Quick Start

### 1. Prepare Application Files

Create a `source` folder with your application files:

```powershell
New-Item -ItemType Directory -Path ".\source"
# Copy your app files to .\source\
```

### 2. Customize installer.nsi

Edit `installer.nsi` and update:

```nsis
; Basic Info
Name "YourAppName"                          ; Application name
OutFile "..\output\YourAppSetup.exe"       ; Output filename
InstallDir "$PROGRAMFILES64\YourCompany\YourAppName"  ; Install location

; Version Info
VIProductVersion "1.0.0.0"                  ; Must be X.X.X.X format
VIAddVersionKey "ProductName" "YourAppName"
VIAddVersionKey "CompanyName" "Your Company"
```

### 3. Add Your Files

In the `MainSection`, add your files:

```nsis
Section "MainSection" SEC01
  SetOutPath "$INSTDIR"
  
  ; Add your files
  File "source\YourApp.exe"
  File "source\*.dll"
  File /r "source\config\*.*"
  
  ; ... rest of section
SectionEnd
```

### 4. Build the Installer

```powershell
# Build using the script
.\Build-Installer.ps1

# Or manually with makensis
makensis.exe installer.nsi
```

### 5. Test the Installer

```powershell
# Interactive install
..\output\YourAppSetup.exe

# Silent install
..\output\YourAppSetup.exe /S

# Silent install with log
..\output\YourAppSetup.exe /S /D=C:\CustomPath

# Silent uninstall
"C:\Program Files\YourCompany\YourAppName\Uninstall.exe" /S
```

## Common Customizations

### Add More Sections

```nsis
Section "Additional Tools" SEC04
  SetOutPath "$INSTDIR\Tools"
  File "source\tools\*.exe"
SectionEnd
```

### Create Registry Entries

```nsis
; Write registry values
WriteRegStr HKLM "Software\YourCompany\YourAppName" "Setting1" "Value1"
WriteRegDWORD HKLM "Software\YourCompany\YourAppName" "Setting2" 1
```

### Environment Variables

```nsis
; Add to PATH
EnVar::AddValue "PATH" "$INSTDIR\bin"

; Create new environment variable
WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "MYAPP_HOME" "$INSTDIR"
```

### Services

```nsis
; Install a Windows service
nsExec::ExecToLog '"$INSTDIR\YourService.exe" --install'
SimpleSC::InstallService "YourService" "Your Service Name" "16" "2" "$INSTDIR\YourService.exe" "" "" ""
SimpleSC::StartService "YourService" ""
```

### Prerequisites Check

```nsis
Function .onInit
  ; Check for .NET Framework
  ReadRegStr $0 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Version"
  ${If} $0 == ""
    MessageBox MB_OK|MB_ICONEXCLAMATION "This application requires .NET Framework 4.0 or later."
    Abort
  ${EndIf}
FunctionEnd
```

## Silent Installation

NSIS supports standard silent install switches:

| Switch | Description |
|--------|-------------|
| `/S` | Silent install |
| `/D=C:\Path` | Set installation directory (must be last parameter) |
| `/NCRC` | Skip CRC check |

**Example:**
```cmd
YourAppSetup.exe /S /D=C:\Program Files\MyApp
```

## Deploy to Intune

### Method 1: As Win32 App

```powershell
# Package the EXE
.\IntuneWinAppUtil.exe -c ".\output" -s "YourAppSetup.exe" -o ".\intune-package"
```

Upload to Intune:
- **Install command**: `YourAppSetup.exe /S`
- **Uninstall command**: `"$INSTDIR\Uninstall.exe" /S` or use registry UninstallString
- **Detection**: Check for file existence or registry key

### Method 2: Convert to MSI (Optional)

Use a tool like `exe2msi` or `MSI Wrapper` to convert the EXE to MSI format if required.

## Advanced Features

### Custom Pages

```nsis
; Add custom page
Page custom CustomPageFunction

Function CustomPageFunction
  ; Your custom page logic
FunctionEnd
```

### Modern UI 2

The script already uses MUI2 for modern look:

```nsis
!include "MUI2.nsh"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "license.txt"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
```

### Compression

```nsis
; Best compression
SetCompressor /SOLID lzma
SetCompressorDictSize 64
```

### Multiple Languages

```nsis
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "Spanish"
!insertmacro MUI_LANGUAGE "French"
```

## Troubleshooting

### Build Errors

**"Can't open script file"**
- Check file paths are correct
- Ensure NSI script exists

**"Invalid command"**
- Check NSIS syntax
- Ensure plugins are installed if using plugin commands

**"File not found"**
- Verify source files exist
- Use absolute paths or `${NSISDIR}` for NSIS files

### Runtime Issues

**UAC Prompt**
```nsis
RequestExecutionLevel admin  ; Requires admin
RequestExecutionLevel user   ; No admin needed
```

**Files not copied**
- Check `SetOutPath` before `File` commands
- Verify source paths

**Shortcuts not working**
- Ensure target file exists
- Check working directory

## Detection Rules for Intune

Choose one detection method:

### File Detection
```
Path: C:\Program Files\YourCompany\YourAppName\YourApp.exe
```

### Registry Detection
```
Key: HKLM\Software\YourCompany\YourAppName
Value: Version
Type: String
Operator: Equals
Data: 1.0.0
```

### Script Detection
```powershell
$path = "C:\Program Files\YourCompany\YourAppName\YourApp.exe"
if (Test-Path $path) {
    $version = (Get-Item $path).VersionInfo.FileVersion
    if ($version -eq "1.0.0") {
        Write-Output "Installed"
        exit 0
    }
}
exit 1
```

## Useful NSIS Commands

```nsis
; File operations
File "source\file.exe"              ; Copy one file
File /r "source\folder\*.*"         ; Copy recursively
Delete "$INSTDIR\file.txt"          ; Delete file
RMDir "$INSTDIR\folder"             ; Remove directory

; Registry
WriteRegStr HKLM "key" "name" "value"
ReadRegStr $0 HKLM "key" "name"
DeleteRegKey HKLM "key"

; Shortcuts
CreateShortcut "$DESKTOP\App.lnk" "$INSTDIR\App.exe"
CreateDirectory "$SMPROGRAMS\MyApp"

; Execution
Exec '"$INSTDIR\app.exe"'           ; Launch app
ExecWait '"$INSTDIR\setup.exe"'     ; Wait for completion
nsExec::ExecToLog "cmd.exe /c dir"  ; Execute with output

; Conditions
${If} ${RunningX64}
  ; 64-bit code
${Else}
  ; 32-bit code
${EndIf}
```

## Resources

- **NSIS Documentation**: https://nsis.sourceforge.io/Docs/
- **NSIS Wiki**: https://nsis.sourceforge.io/
- **Examples**: https://nsis.sourceforge.io/Category:Examples
- **Plugins**: https://nsis.sourceforge.io/Category:Plugins
- **Modern UI 2**: https://nsis.sourceforge.io/Docs/Modern%20UI%202/Readme.html

## Tips

- **Use absolute paths** or proper NSIS variables
- **Test both install and uninstall** thoroughly
- **Use `/S` switch** for silent deployment
- **Add proper version info** for better management
- **Create detailed uninstaller** that removes everything
- **Check return codes** when executing external programs

---

**Created**: November 24, 2025  
**NSIS Version**: 3.x compatible  
**Purpose**: Lightweight installer creation for Intune deployment
