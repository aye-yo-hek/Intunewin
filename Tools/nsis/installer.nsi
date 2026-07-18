; NSIS Installer Script
; Creates an executable installer for Windows applications
; Compatible with Microsoft Intune Win32 app deployment

;--------------------------------
; Includes

!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "x64.nsh"

;--------------------------------
; General Configuration

; Name and file
Name "YourAppName"
OutFile "..\output\YourAppSetup.exe"

; Default installation folder
InstallDir "$PROGRAMFILES64\YourCompany\YourAppName"

; Get installation folder from registry if available
InstallDirRegKey HKLM "Software\YourCompany\YourAppName" "InstallPath"

; Request application privileges
RequestExecutionLevel admin

; Branding
BrandingText "Your Company - YourAppName Installer"

; Version Information
VIProductVersion "1.0.0.0"
VIAddVersionKey "ProductName" "YourAppName"
VIAddVersionKey "CompanyName" "Your Company"
VIAddVersionKey "FileDescription" "YourAppName Installer"
VIAddVersionKey "FileVersion" "1.0.0"
VIAddVersionKey "LegalCopyright" "© 2025 Your Company"

;--------------------------------
; Interface Settings

!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

;--------------------------------
; Pages

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "license.txt"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

;--------------------------------
; Languages

!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Installer Sections

Section "MainSection" SEC01

  SetOutPath "$INSTDIR"
  
  ; Add your files here
  ; File "source\YourApp.exe"
  ; File "source\*.dll"
  ; File /r "source\*.*"
  
  ; Example: Copy files
  File "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
  
  ; Store installation folder
  WriteRegStr HKLM "Software\YourCompany\YourAppName" "InstallPath" $INSTDIR
  WriteRegStr HKLM "Software\YourCompany\YourAppName" "Version" "1.0.0"
  
  ; Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  
  ; Add to Add/Remove Programs
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\YourAppName" "DisplayName" "YourAppName"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\YourAppName" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\YourAppName" "DisplayIcon" "$INSTDIR\modern-install.ico"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\YourAppName" "Publisher" "Your Company"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\YourAppName" "DisplayVersion" "1.0.0"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\YourAppName" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\YourAppName" "NoRepair" 1

SectionEnd

;--------------------------------
; Start Menu Shortcuts Section (Optional)

Section "Start Menu Shortcuts" SEC02

  CreateDirectory "$SMPROGRAMS\YourAppName"
  
  ; Example shortcuts (uncomment and modify)
  ; CreateShortcut "$SMPROGRAMS\YourAppName\YourAppName.lnk" "$INSTDIR\YourApp.exe"
  CreateShortcut "$SMPROGRAMS\YourAppName\Uninstall.lnk" "$INSTDIR\Uninstall.exe"

SectionEnd

;--------------------------------
; Desktop Shortcut Section (Optional)

Section "Desktop Shortcut" SEC03

  ; Example desktop shortcut (uncomment and modify)
  ; CreateShortcut "$DESKTOP\YourAppName.lnk" "$INSTDIR\YourApp.exe"

SectionEnd

;--------------------------------
; Uninstaller Section

Section "Uninstall"

  ; Remove files and directories
  Delete "$INSTDIR\Uninstall.exe"
  Delete "$INSTDIR\modern-install.ico"
  ; Add more Delete commands for your files
  ; Delete "$INSTDIR\YourApp.exe"
  ; Delete "$INSTDIR\*.dll"
  
  RMDir "$INSTDIR"
  
  ; Remove shortcuts
  Delete "$SMPROGRAMS\YourAppName\*.*"
  RMDir "$SMPROGRAMS\YourAppName"
  Delete "$DESKTOP\YourAppName.lnk"
  
  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\YourAppName"
  DeleteRegKey HKLM "Software\YourCompany\YourAppName"

SectionEnd

;--------------------------------
; Section Descriptions

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC01} "Main application files"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC02} "Start Menu shortcuts"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC03} "Desktop shortcut"
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
; Functions

Function .onInit
  ; Check if running on 64-bit Windows (optional)
  ${If} ${RunningX64}
    ; Running on 64-bit Windows
  ${Else}
    MessageBox MB_OK|MB_ICONEXCLAMATION "This application requires 64-bit Windows."
    Abort
  ${EndIf}
FunctionEnd
