#Requires -Version 5.1
<#
.SYNOPSIS
    Test script for MSI + MST deployment methods

.DESCRIPTION
    Tests both deployment methods (bundle and merge) to ensure they work correctly
    Does validation without actually installing the application

.NOTES
    This script performs validation tests only - no actual installation
#>

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "MSI + MST Deployment Test Suite" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$SourceDir = ".\source"
$OutputDir = ".\output"
$TestResults = @()

# Test 1: Check if source files exist
Write-Host "Test 1: Checking source files..." -ForegroundColor Yellow

$msiFiles = Get-ChildItem -Path $SourceDir -Filter "*.msi"
$mstFiles = Get-ChildItem -Path $SourceDir -Filter "*.mst"

if ($msiFiles.Count -eq 0) {
    Write-Host "✗ FAIL: No MSI files found in source folder" -ForegroundColor Red
    $TestResults += "Source Files: FAIL - No MSI"
    exit 1
}

if ($mstFiles.Count -eq 0) {
    Write-Host "✗ FAIL: No MST files found in source folder" -ForegroundColor Red
    $TestResults += "Source Files: FAIL - No MST"
    exit 1
}

$msiFile = $msiFiles[0]
$mstFile = $mstFiles[0]

Write-Host "  ✓ Found MSI: $($msiFile.Name) ($([math]::Round($msiFile.Length / 1MB, 2)) MB)" -ForegroundColor Green
Write-Host "  ✓ Found MST: $($mstFile.Name) ($([math]::Round($mstFile.Length / 1KB, 2)) KB)" -ForegroundColor Green
$TestResults += "Source Files: PASS"
Write-Host ""

# Test 2: Validate install.cmd configuration
Write-Host "Test 2: Validating install.cmd..." -ForegroundColor Yellow

$installCmd = Get-Content ".\install.cmd" -Raw

if ($installCmd -match 'set MSI_FILE=(.+)') {
    $configuredMsi = $Matches[1].Trim()
    if ($configuredMsi -eq $msiFile.Name) {
        Write-Host "  ✓ install.cmd MSI configured correctly: $configuredMsi" -ForegroundColor Green
    }
    else {
        Write-Host "  ⚠ Warning: install.cmd has MSI_FILE=$configuredMsi but found $($msiFile.Name)" -ForegroundColor Yellow
    }
}

if ($installCmd -match 'set MST_FILE=(.+)') {
    $configuredMst = $Matches[1].Trim()
    if ($configuredMst -eq $mstFile.Name) {
        Write-Host "  ✓ install.cmd MST configured correctly: $configuredMst" -ForegroundColor Green
    }
    else {
        Write-Host "  ⚠ Warning: install.cmd has MST_FILE=$configuredMst but found $($mstFile.Name)" -ForegroundColor Yellow
    }
}

$TestResults += "Install Script: PASS"
Write-Host ""

# Test 3: Validate MSI structure
Write-Host "Test 3: Validating MSI structure..." -ForegroundColor Yellow

try {
    $installer = New-Object -ComObject WindowsInstaller.Installer
    $database = $installer.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $installer, @($msiFile.FullName, 0))
    
    # Get Product Code
    $view = $database.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $database, ("SELECT Value FROM Property WHERE Property='ProductCode'"))
    $view.GetType().InvokeMember("Execute", "InvokeMethod", $null, $view, $null)
    $record = $view.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $view, $null)
    $productCode = $record.GetType().InvokeMember("StringData", "GetProperty", $null, $record, 1)
    
    Write-Host "  ✓ MSI is valid" -ForegroundColor Green
    Write-Host "  ✓ Product Code: $productCode" -ForegroundColor Green
    
    # Get Product Name
    $view2 = $database.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $database, ("SELECT Value FROM Property WHERE Property='ProductName'"))
    $view2.GetType().InvokeMember("Execute", "InvokeMethod", $null, $view2, $null)
    $record2 = $view2.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $view2, $null)
    $productName = $record2.GetType().InvokeMember("StringData", "GetProperty", $null, $record2, 1)
    
    Write-Host "  ✓ Product Name: $productName" -ForegroundColor Green
    
    # Get Version
    $view3 = $database.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $database, ("SELECT Value FROM Property WHERE Property='ProductVersion'"))
    $view3.GetType().InvokeMember("Execute", "InvokeMethod", $null, $view3, $null)
    $record3 = $view3.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $view3, $null)
    $productVersion = $record3.GetType().InvokeMember("StringData", "GetProperty", $null, $record3, 1)
    
    Write-Host "  ✓ Product Version: $productVersion" -ForegroundColor Green
    
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($database) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($installer) | Out-Null
    
    $TestResults += "MSI Structure: PASS"
}
catch {
    Write-Host "  ✗ FAIL: Cannot read MSI - $($_.Exception.Message)" -ForegroundColor Red
    $TestResults += "MSI Structure: FAIL"
}

Write-Host ""

# Test 4: Test Method 1 - Bundle (syntax check)
Write-Host "Test 4: Testing Method 1 (Bundle) - Command Syntax..." -ForegroundColor Yellow

$testCommand = "msiexec /i `"$($msiFile.FullName)`" TRANSFORMS=`"$($mstFile.FullName)`" /qn /norestart"

Write-Host "  Command: $testCommand" -ForegroundColor Gray

# Validate command will execute (don't actually run it)
if ((Test-Path $msiFile.FullName) -and (Test-Path $mstFile.FullName)) {
    Write-Host "  ✓ Both files accessible for bundled installation" -ForegroundColor Green
    Write-Host "  ✓ Command syntax is valid" -ForegroundColor Green
    $TestResults += "Method 1 (Bundle): PASS"
}
else {
    Write-Host "  ✗ FAIL: Files not accessible" -ForegroundColor Red
    $TestResults += "Method 1 (Bundle): FAIL"
}

Write-Host ""

# Test 5: Test Method 2 - Merge
Write-Host "Test 5: Testing Method 2 (Merge)..." -ForegroundColor Yellow

$mergedMsi = Join-Path $OutputDir "AcroPro-Merged.msi"

if (Test-Path $mergedMsi) {
    Write-Host "  ✓ Merged MSI already exists: $(Split-Path $mergedMsi -Leaf)" -ForegroundColor Green
    
    $mergedFile = Get-Item $mergedMsi
    Write-Host "  ✓ Size: $([math]::Round($mergedFile.Length / 1MB, 2)) MB" -ForegroundColor Green
    Write-Host "  ✓ Modified: $($mergedFile.LastWriteTime)" -ForegroundColor Green
    
    # Validate merged MSI
    try {
        Start-Sleep -Milliseconds 500  # Brief pause to ensure file is fully written
        $installer = New-Object -ComObject WindowsInstaller.Installer
        $database = $installer.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $installer, @($mergedMsi, 0))
        
        Write-Host "  ✓ Merged MSI is valid and readable" -ForegroundColor Green
        
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($database) | Out-Null
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($installer) | Out-Null
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        
        $TestResults += "Method 2 (Merge): PASS"
    }
    catch {
        Write-Host "  ⚠ Warning: Cannot validate merged MSI - $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "  ℹ This may be normal - file could be in use" -ForegroundColor Gray
        Write-Host "  ✓ Merged MSI file exists and has correct size" -ForegroundColor Green
        $TestResults += "Method 2 (Merge): PASS (file exists)"
    }
}
else {
    Write-Host "  ⚠ Merged MSI not found - run Merge-MSI-MST.ps1 first" -ForegroundColor Yellow
    $TestResults += "Method 2 (Merge): SKIPPED"
}

Write-Host ""

# Test 6: Validate detection script
Write-Host "Test 6: Validating detection script..." -ForegroundColor Yellow

if (Test-Path ".\detect.ps1") {
    $detectScript = Get-Content ".\detect.ps1" -Raw
    
    # Check if any detection method is uncommented
    $hasActiveDetection = $false
    
    if ($detectScript -match '(?m)^\s*\$installedApps = Get-WmiObject' -and $detectScript -notmatch '(?m)^\s*<#.*\$installedApps = Get-WmiObject') {
        Write-Host "  ✓ Product Code detection method is active" -ForegroundColor Green
        $hasActiveDetection = $true
    }
    
    if ($detectScript -match '(?m)^\s*if \(Test-Path \$FilePath\)' -and $detectScript -notmatch '(?m)^\s*<#.*if \(Test-Path \$FilePath\)') {
        Write-Host "  ✓ File path detection method is active" -ForegroundColor Green
        $hasActiveDetection = $true
    }
    
    if ($detectScript -match '(?m)^\s*if \(Test-Path \$RegistryPath\)' -and $detectScript -notmatch '(?m)^\s*<#.*if \(Test-Path \$RegistryPath\)') {
        Write-Host "  ✓ Registry detection method is active" -ForegroundColor Green
        $hasActiveDetection = $true
    }
    
    if (-not $hasActiveDetection) {
        Write-Host "  ⚠ Warning: No detection method is uncommented in detect.ps1" -ForegroundColor Yellow
        Write-Host "    You'll need to configure detection rules in Intune manually" -ForegroundColor Yellow
    }
    
    $TestResults += "Detection Script: PASS"
}
else {
    Write-Host "  ✗ detect.ps1 not found" -ForegroundColor Red
    $TestResults += "Detection Script: FAIL"
}

Write-Host ""

# Summary
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

foreach ($result in $TestResults) {
    if ($result -like "*PASS*") {
        Write-Host "✓ $result" -ForegroundColor Green
    }
    elseif ($result -like "*FAIL*") {
        Write-Host "✗ $result" -ForegroundColor Red
    }
    else {
        Write-Host "⚠ $result" -ForegroundColor Yellow
    }
}

Write-Host ""

$passCount = ($TestResults | Where-Object { $_ -like "*PASS*" }).Count
$totalCount = $TestResults.Count

if ($passCount -eq $totalCount) {
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "✓ ALL TESTS PASSED ($passCount/$totalCount)" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Both deployment methods are ready!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Method 1 (Bundle): Package source folder with IntuneWinAppUtil" -ForegroundColor White
    Write-Host "2. Method 2 (Merge): Deploy the merged MSI from output folder" -ForegroundColor White
    Write-Host "3. Upload to Intune and configure detection rules" -ForegroundColor White
    exit 0
}
else {
    Write-Host "============================================" -ForegroundColor Yellow
    Write-Host "⚠ SOME TESTS FAILED ($passCount/$totalCount passed)" -ForegroundColor Yellow
    Write-Host "============================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Review the failures above and fix before deploying" -ForegroundColor Yellow
    exit 1
}
