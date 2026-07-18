# Test-AXCodeSetup.ps1
# Diagnostic script to identify correct installation parameters for AXCodeSetup

$installerPath = ".\exe files\axcodesetup.exe"

if (-not (Test-Path $installerPath)) {
    Write-Host "ERROR: axcodesetup.exe not found in exe files folder!" -ForegroundColor Red
    exit 1
}

Write-Host "AXCodeSetup Diagnostic Information" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green

# Get file information
$fileInfo = Get-ItemProperty $installerPath
Write-Host "File Size: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor Cyan
Write-Host "File Path: $installerPath" -ForegroundColor Cyan

# Check file type
$fileHeader = Get-Content $installerPath -Encoding Byte -ReadCount 100 | Select-Object -First 100
$headerString = [System.Text.Encoding]::ASCII.GetString($fileHeader)

Write-Host "`nInstaller Type Detection:" -ForegroundColor Yellow
if ($headerString -match "Inno Setup") {
    Write-Host "✓ Detected: Inno Setup installer" -ForegroundColor Green
    Write-Host "  Recommended parameters: /SILENT /NORESTART" -ForegroundColor Gray
} elseif ($headerString -match "NSIS") {
    Write-Host "✓ Detected: NSIS installer" -ForegroundColor Green
    Write-Host "  Recommended parameters: /S" -ForegroundColor Gray
} elseif ($headerString -match "InstallShield") {
    Write-Host "✓ Detected: InstallShield installer" -ForegroundColor Green
    Write-Host "  Recommended parameters: /s /v\"/qn\"" -ForegroundColor Gray
} elseif ($headerString -match "WiX") {
    Write-Host "✓ Detected: WiX installer" -ForegroundColor Green
    Write-Host "  Recommended parameters: /quiet" -ForegroundColor Gray
} else {
    Write-Host "? Unknown installer type" -ForegroundColor Yellow
}

# Test common parameters (non-destructive)
Write-Host "`nTesting Help Parameters:" -ForegroundColor Yellow
$helpParams = @("/help", "/h", "/?", "-help", "-h", "--help")

foreach ($param in $helpParams) {
    try {
        $output = & $installerPath $param 2>&1
        if ($output -and $output.Length -lt 1000) {
            Write-Host "✓ $param works:" -ForegroundColor Green
            Write-Host "  $($output[0..3] -join ' ')" -ForegroundColor Gray
            break
        }
    } catch {
        # Ignore errors for help parameter testing
    }
}

Write-Host "`nRecommended Installation Script Update:" -ForegroundColor Yellow
Write-Host "Try these parameters in order:" -ForegroundColor Gray
Write-Host "1. /SILENT /NORESTART" -ForegroundColor White
Write-Host "2. /quiet" -ForegroundColor White  
Write-Host "3. /S" -ForegroundColor White
Write-Host "4. -silent" -ForegroundColor White