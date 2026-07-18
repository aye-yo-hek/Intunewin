@echo off
start /wait "" "%~dp0dotnet-sdk-8.0.423-win-x64.exe" /uninstall /quiet /norestart /log "%TEMP%\dotnet-sdk-8.0.423-uninstall.log"
exit /b %errorlevel%
