@echo off
REM VS Code Auto-Update Policy Removal
REM This script removes the UpdateMode policy configuration

echo Removing VS Code Auto-Update Policy...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
exit /b %ERRORLEVEL%
