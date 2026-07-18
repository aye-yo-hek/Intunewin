@echo off
start /wait "" "%~dp0dotnet-sdk-8.0.423-win-x64.exe" /install /quiet /norestart /log "%TEMP%\dotnet-sdk-8.0.423-install.log"
exit /b %errorlevel%
