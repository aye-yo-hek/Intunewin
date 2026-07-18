@echo off
REM Uninstall Script
REM Replace {PRODUCT-CODE-GUID} with your actual MSI Product Code

REM ===================================
REM Configuration
REM ===================================
REM Product Code for Adobe Acrobat DC (64-bit) v21.001.20135
set PRODUCT_CODE={AC76BA86-1033-FFFF-7760-BC15014EA700}

REM ===================================
REM Uninstallation Logic
REM ===================================

echo Uninstalling application...

REM Uninstall MSI by Product Code
REM /x = uninstall
REM /qn = silent (no UI)
REM /norestart = don't restart automatically

msiexec.exe /x "%PRODUCT_CODE%" /qn /norestart /l*v "%TEMP%\uninstall.log"

set EXIT_CODE=%ERRORLEVEL%

if %EXIT_CODE% EQU 0 (
    echo Uninstallation completed successfully.
) else if %EXIT_CODE% EQU 3010 (
    echo Uninstallation completed. Restart required.
) else if %EXIT_CODE% EQU 1605 (
    echo Application not found or already uninstalled.
    set EXIT_CODE=0
) else (
    echo Uninstallation failed with exit code: %EXIT_CODE%
    echo Check log file: %TEMP%\uninstall.log
)

exit /b %EXIT_CODE%
