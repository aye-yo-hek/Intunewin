@echo off
REM AXCodeSetup Diagnostic Install Script
REM This version includes more detailed error reporting

echo Starting AXCodeSetup installation with diagnostics...
echo Current user: %USERNAME%
echo Current directory: %CD%
echo Current time: %DATE% %TIME%

REM Check if installer exists
if not exist "%~dp0..\..\exe files\axcodesetup.exe" (
    echo ERROR: AXCode installer not found at: %~dp0..\..\exe files\axcodesetup.exe
    exit /b 2
)

echo Installer found: %~dp0..\..\exe files\axcodesetup.exe

REM Get installer file info
for %%F in ("%~dp0..\..\exe files\axcodesetup.exe") do (
    echo Installer size: %%~zF bytes
    echo Installer date: %%~tF
)

echo Starting installation with parameters: /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /MERGETASKS="!runcode"

REM Run installer with detailed error capture
"%~dp0..\..\exe files\axcodesetup.exe" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /MERGETASKS="!runcode"
set INSTALL_EXIT_CODE=%ERRORLEVEL%

echo Installer exit code: %INSTALL_EXIT_CODE%

if %INSTALL_EXIT_CODE% neq 0 (
    echo Installation failed with exit code: %INSTALL_EXIT_CODE%
    echo Trying alternative parameters...
    
    "%~dp0..\..\exe files\axcodesetup.exe" /SILENT /SUPPRESSMSGBOXES /NORESTART /SP-
    set ALT_EXIT_CODE=%ERRORLEVEL%
    echo Alternative installation exit code: %ALT_EXIT_CODE%
    
    if %ALT_EXIT_CODE% neq 0 (
        echo Both installation attempts failed
        echo Primary exit code: %INSTALL_EXIT_CODE%
        echo Alternative exit code: %ALT_EXIT_CODE%
        exit /b %INSTALL_EXIT_CODE%
    )
)

echo Waiting for installation to complete...
timeout /t 45 /nobreak > nul

echo Checking installation results...

REM Check primary installation location
if exist "%LOCALAPPDATA%\Programs\AX Code\AX Code.exe" (
    echo SUCCESS: Found AX Code.exe at %LOCALAPPDATA%\Programs\AX Code\AX Code.exe
    goto create_registry
)

REM Check alternative locations
if exist "%ProgramFiles%\AX Code\AX Code.exe" (
    echo SUCCESS: Found AX Code.exe at %ProgramFiles%\AX Code\AX Code.exe
    goto create_registry
)

echo ERROR: AX Code.exe not found in expected locations
echo Checked: %LOCALAPPDATA%\Programs\AX Code\AX Code.exe
echo Checked: %ProgramFiles%\AX Code\AX Code.exe
exit /b 3

:create_registry
echo Creating registry detection entry...
reg add "HKLM\SOFTWARE\YourCompany\IntuneApps" /v "AXCodeSetup" /t REG_SZ /d "Installed" /f
if %ERRORLEVEL% neq 0 (
    echo WARNING: Could not create registry entry (exit code: %ERRORLEVEL%)
    echo This may be due to insufficient permissions
)

echo AXCodeSetup installation completed successfully at %DATE% %TIME%
exit /b 0