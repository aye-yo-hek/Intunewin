@echo off
REM MSI + MST Installation Script
REM This script applies an MST transform during MSI installation

REM ===================================
REM Configuration - Update these names
REM ===================================
set MSI_FILE=AcroPro.msi
set MST_FILE=AcroPro.mst

REM ===================================
REM Installation Logic
REM ===================================

echo Installing %MSI_FILE% with transform %MST_FILE%...

REM Get the directory where this script is located
set SCRIPT_DIR=%~dp0

REM Check if MSI file exists
if not exist "%SCRIPT_DIR%%MSI_FILE%" (
    echo ERROR: MSI file not found: %MSI_FILE%
    exit /b 1
)

REM Check if MST file exists
if not exist "%SCRIPT_DIR%%MST_FILE%" (
    echo ERROR: MST file not found: %MST_FILE%
    exit /b 1
)

REM Install MSI with MST transform
REM /i = install
REM TRANSFORMS = apply transform file
REM /qn = silent (no UI)
REM /norestart = don't restart automatically

msiexec.exe /i "%SCRIPT_DIR%%MSI_FILE%" TRANSFORMS="%SCRIPT_DIR%%MST_FILE%" /qn /norestart /l*v "%TEMP%\%MSI_FILE%.install.log"

REM Capture exit code
set EXIT_CODE=%ERRORLEVEL%

if %EXIT_CODE% EQU 0 (
    echo Installation completed successfully.
) else if %EXIT_CODE% EQU 3010 (
    echo Installation completed. Restart required.
) else (
    echo Installation failed with exit code: %EXIT_CODE%
    echo Check log file: %TEMP%\%MSI_FILE%.install.log
)

exit /b %EXIT_CODE%
