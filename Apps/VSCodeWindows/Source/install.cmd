@echo off
REM VS Code Auto-Update Configuration via Intune
REM This script configures the UpdateMode policy to enable automatic updates

echo Installing VS Code Auto-Update Policy...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
exit /b %ERRORLEVEL%
