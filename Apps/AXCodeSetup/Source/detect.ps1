# detect.ps1
# Detection script for AXCodeSetup - User Context Installation
# Checking actual installation location: %LOCALAPPDATA%\Programs\AX Code

# Check for AX Code executable in user's local appdata (actual installation location)
$axcodePath = "$env:LOCALAPPDATA\Programs\AX Code\AX Code.exe"

if (Test-Path $axcodePath) {
    Write-Host "AX Code detected at: $axcodePath"
    exit 0
} else {
    Write-Host "AX Code not detected at: $axcodePath"
    exit 1
}