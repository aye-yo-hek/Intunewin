# Test Detection Script for AXCodeSetup User Context Installation
# This script verifies the detection logic works correctly

Write-Host "=== TESTING AXCODESETUP DETECTION ===" -ForegroundColor Cyan

# Test the actual detection script
Write-Host "`n1. Running detection script..." -ForegroundColor Yellow
Push-Location "src\AXCodeSetup"
try {
    & .\detect.ps1
    $detectionResult = $LASTEXITCODE
    Write-Host "Detection script exit code: $detectionResult" -ForegroundColor $(if($detectionResult -eq 0){"Green"}else{"Red"})
} catch {
    Write-Host "Error running detection script: $($_.Exception.Message)" -ForegroundColor Red
}
Pop-Location

# Check the specific path we're looking for
Write-Host "`n2. Manual path verification..." -ForegroundColor Yellow
$startMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\AX Code"
$pathExists = Test-Path $startMenuPath

Write-Host "Checking path: $startMenuPath"
Write-Host "Path exists: " -NoNewline
Write-Host $pathExists -ForegroundColor $(if($pathExists){"Green"}else{"Red"})

if ($pathExists) {
    Write-Host "Contents of AX Code folder:" -ForegroundColor Green
    Get-ChildItem $startMenuPath -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  - $($_.Name)" }
}

# Check alternative locations for troubleshooting
Write-Host "`n3. Checking alternative locations..." -ForegroundColor Yellow
$altPaths = @(
    "$env:LOCALAPPDATA\Programs\AX Code",
    "$env:ProgramFiles\AX Code", 
    "$env:ProgramFiles(x86)\AX Code",
    "$env:USERPROFILE\Desktop\AX Code.lnk"
)

foreach ($path in $altPaths) {
    $exists = Test-Path $path
    Write-Host "$path : " -NoNewline
    Write-Host $exists -ForegroundColor $(if($exists){"Green"}else{"Gray"})
}

# Provide fix recommendation
Write-Host "`n=== RESULTS AND RECOMMENDATIONS ===" -ForegroundColor Cyan

if ($detectionResult -eq 0) {
    Write-Host "✅ DETECTION WORKING: Upload AXCodeSetup-FIXED-DETECTION.intunewin" -ForegroundColor Green
    Write-Host "   The detection script correctly found AX Code installation" -ForegroundColor Green
} else {
    Write-Host "❌ DETECTION ISSUE: Further investigation needed" -ForegroundColor Red
    Write-Host "   Recommendations:" -ForegroundColor Yellow
    Write-Host "   1. Verify AX Code is actually installed" -ForegroundColor Yellow
    Write-Host "   2. Check if installation created shortcuts in Start Menu" -ForegroundColor Yellow
    Write-Host "   3. Consider using registry-based detection as alternative" -ForegroundColor Yellow
}

Write-Host "`n📋 INTUNE CONFIGURATION:" -ForegroundColor Yellow
Write-Host "Detection Method: Custom PowerShell Script"
Write-Host "Detection Script File: detect.ps1 (from the package)"
Write-Host "Installation Context: User"
Write-Host "Expected Install Location: %APPDATA%\Microsoft\Windows\Start Menu\Programs\AX Code"