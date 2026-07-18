# Fix-MergedMSI.ps1
# Alternative approach: Don't merge, just ensure both files are packaged together

param(
    [string]$MsiPath = ".\source\AcroPro.msi",
    [string]$MstPath = ".\source\AcroPro.mst",
    [string]$OutputPath = ".\output"
)

Write-Host "`n=== MSI+MST Bundle Packager ===" -ForegroundColor Cyan
Write-Host "Note: Merging can break embedded CAB files" -ForegroundColor Yellow
Write-Host "Recommendation: Use bundle method instead`n" -ForegroundColor Yellow

# Check files exist
if (-not (Test-Path $MsiPath)) {
    Write-Host "ERROR: MSI not found: $MsiPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $MstPath)) {
    Write-Host "ERROR: MST not found: $MstPath" -ForegroundColor Red
    exit 1
}

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

Write-Host "=== ANALYSIS ===" -ForegroundColor Yellow
Write-Host "`nThe merged MSI error occurs because:" -ForegroundColor Cyan
Write-Host "  1. MSI contains embedded CAB files (core.cab)" -ForegroundColor Gray
Write-Host "  2. ApplyTransform changes file references" -ForegroundColor Gray
Write-Host "  3. Windows Installer can't find the CAB in new structure`n" -ForegroundColor Gray

Write-Host "=== RECOMMENDED SOLUTION ===" -ForegroundColor Green
Write-Host "`nDO NOT use merged MSI for Adobe Acrobat." -ForegroundColor Yellow
Write-Host "Instead, use the BUNDLE method:`n" -ForegroundColor Yellow

Write-Host "1. Keep MSI and MST separate in source\ folder" -ForegroundColor White
Write-Host "2. Use install-enhanced.cmd which runs:" -ForegroundColor White
Write-Host "   msiexec /i AcroPro.msi TRANSFORMS=AcroPro.mst /qn" -ForegroundColor Cyan
Write-Host "`n3. Package for Intune:" -ForegroundColor White
Write-Host "   IntuneWinAppUtil.exe -c "".\source"" -s ""install-enhanced.cmd"" -o "".\intune-packages""" -ForegroundColor Cyan

Write-Host "`n=== WHY BUNDLE METHOD WORKS ===" -ForegroundColor Yellow
Write-Host "  ✓ Preserves original MSI structure" -ForegroundColor Green
Write-Host "  ✓ CAB files remain embedded correctly" -ForegroundColor Green
Write-Host "  ✓ MST applied at install time by Windows Installer" -ForegroundColor Green
Write-Host "  ✓ No file corruption" -ForegroundColor Green
Write-Host "  ✓ Microsoft's recommended approach" -ForegroundColor Green

Write-Host "`n=== ALTERNATIVE: Extract and Repackage ===" -ForegroundColor Yellow
Write-Host "If you MUST have a single MSI file:" -ForegroundColor Cyan
Write-Host "  1. Extract MSI contents with: msiexec /a AcroPro.msi /qb TARGETDIR=C:\Extracted" -ForegroundColor Gray
Write-Host "  2. Apply MST changes manually" -ForegroundColor Gray
Write-Host "  3. Rebuild MSI with WiX or Advanced Installer" -ForegroundColor Gray
Write-Host "  4. This is complex and time-consuming`n" -ForegroundColor Gray

Write-Host "=== VERIFY BUNDLE METHOD FILES ===" -ForegroundColor Cyan

$msiFile = Get-Item $MsiPath
$mstFile = Get-Item $MstPath

Write-Host "`n✓ MSI: $($msiFile.Name) - $([math]::Round($msiFile.Length/1MB, 2)) MB" -ForegroundColor Green
Write-Host "✓ MST: $($mstFile.Name) - $([math]::Round($mstFile.Length/1KB, 2)) KB" -ForegroundColor Green

# Check if install-enhanced.cmd exists
$installCmd = ".\source\install-enhanced.cmd"
if (Test-Path $installCmd) {
    Write-Host "✓ install-enhanced.cmd found" -ForegroundColor Green
} else {
    Write-Host "⚠ install-enhanced.cmd not found in source folder" -ForegroundColor Yellow
}

Write-Host "`n=== RECOMMENDED ACTION ===" -ForegroundColor Cyan
Write-Host "Delete the merged MSI and use bundle method:" -ForegroundColor Yellow

$mergedMsi = Join-Path $OutputPath "AcroPro-Merged.msi"
if (Test-Path $mergedMsi) {
    $response = Read-Host "`nDelete corrupted merged MSI? (Y/N)"
    if ($response -eq "Y" -or $response -eq "y") {
        Remove-Item $mergedMsi -Force
        Write-Host "✓ Deleted: $mergedMsi" -ForegroundColor Green
    }
}

Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Cyan
Write-Host "1. Use bundle method (MSI + MST + install-enhanced.cmd)" -ForegroundColor White
Write-Host "2. Package for Intune:" -ForegroundColor White
Write-Host "   IntuneWinAppUtil.exe -c "".\source"" -s ""install-enhanced.cmd"" -o "".\intune-packages""" -ForegroundColor Cyan
Write-Host "3. Deploy to Intune as Win32 app" -ForegroundColor White
Write-Host "4. Install command: install-enhanced.cmd" -ForegroundColor Cyan

Write-Host "`n=== BUNDLE METHOD IS THE CORRECT APPROACH ===" -ForegroundColor Green
