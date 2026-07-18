# detect.ps1
# File-based detection script for Python 3.14 following Andrew Taylor best practices
# Simple, reliable detection using file existence check

# Check if Python 3.14 executable exists at the standard installation location
$pythonPath = "$env:ProgramFiles\Python314\python.exe"

if (Test-Path $pythonPath) {
    Write-Host "Python 3.14 detected at: $pythonPath"
    exit 0
} else {
    Write-Host "Python 3.14 not detected"
    exit 1
}