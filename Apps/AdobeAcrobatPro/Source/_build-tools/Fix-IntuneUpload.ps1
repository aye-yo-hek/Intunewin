# Fix-IntuneUpload.ps1
# Solutions for Intune package upload issues

param(
    [switch]$RecreatePackage,
    [switch]$UseGraph,
    [switch]$ShowTroubleshooting
)

Write-Host "`n=======================================" -ForegroundColor Cyan
Write-Host "  INTUNE UPLOAD TROUBLESHOOTING" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

$packagePath = ".\intune-packages\install-enhanced.intunewin"

if (Test-Path $packagePath) {
    $pkg = Get-Item $packagePath
    Write-Host "`n✓ Package found" -ForegroundColor Green
    Write-Host "  Size: $([math]::Round($pkg.Length/1MB, 2)) MB" -ForegroundColor White
    Write-Host "  Created: $($pkg.CreationTime)" -ForegroundColor White
} else {
    Write-Host "`n✗ Package not found at: $packagePath" -ForegroundColor Red
    exit 1
}

Write-Host "`n=======================================" -ForegroundColor Yellow
Write-Host "  COMMON UPLOAD ISSUES & SOLUTIONS" -ForegroundColor Yellow
Write-Host "=======================================" -ForegroundColor Yellow

Write-Host "`n1. BROWSER TIMEOUT (Most Common)" -ForegroundColor Cyan
Write-Host "   Solutions:" -ForegroundColor White
Write-Host "   • Use Microsoft Edge browser (best for Intune)" -ForegroundColor Gray
Write-Host "   • Clear browser cache and cookies" -ForegroundColor Gray
Write-Host "   • Disable browser extensions" -ForegroundColor Gray
Write-Host "   • Try Incognito/InPrivate mode" -ForegroundColor Gray

Write-Host "`n2. FILE ACCESS ISSUES" -ForegroundColor Cyan
Write-Host "   Solutions:" -ForegroundColor White
Write-Host "   • Close File Explorer if viewing the folder" -ForegroundColor Gray
Write-Host "   • Copy file to Desktop and upload from there" -ForegroundColor Gray
Write-Host "   • Run browser as Administrator" -ForegroundColor Gray

Write-Host "`n3. NETWORK CONNECTIVITY" -ForegroundColor Cyan
Write-Host "   Solutions:" -ForegroundColor White
Write-Host "   • Check internet connection is stable" -ForegroundColor Gray
Write-Host "   • Disable VPN temporarily" -ForegroundColor Gray
Write-Host "   • Try from different network" -ForegroundColor Gray
Write-Host "   • Use wired connection instead of WiFi" -ForegroundColor Gray

Write-Host "`n4. INTUNE SERVICE ISSUES" -ForegroundColor Cyan
Write-Host "   Solutions:" -ForegroundColor White
Write-Host "   • Check Microsoft 365 Service Health" -ForegroundColor Gray
Write-Host "   • Try again in 10-15 minutes" -ForegroundColor Gray
Write-Host "   • Clear Intune portal cache (Ctrl+F5)" -ForegroundColor Gray

Write-Host "`n=======================================" -ForegroundColor Green
Write-Host "  RECOMMENDED FIX STEPS" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

Write-Host "`nStep 1: Copy package to Desktop" -ForegroundColor Yellow
$desktop = [Environment]::GetFolderPath("Desktop")
$desktopPackage = Join-Path $desktop "install-enhanced.intunewin"

try {
    Copy-Item $packagePath $desktopPackage -Force
    Write-Host "  ✓ Copied to: $desktopPackage" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Failed to copy: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nStep 2: Open Intune in Microsoft Edge" -ForegroundColor Yellow
Write-Host "  1. Close all browser windows" -ForegroundColor White
Write-Host "  2. Open Microsoft Edge" -ForegroundColor White
Write-Host "  3. Go to: https://intune.microsoft.com" -ForegroundColor Cyan
Write-Host "  4. Clear cache: Ctrl+Shift+Delete > Clear All" -ForegroundColor White

Write-Host "`nStep 3: Upload from Desktop" -ForegroundColor Yellow
Write-Host "  1. Apps > Windows > Add > Windows app (Win32)" -ForegroundColor White
Write-Host "  2. Select app package file" -ForegroundColor White
Write-Host "  3. Browse to Desktop" -ForegroundColor White
Write-Host "  4. Select: install-enhanced.intunewin" -ForegroundColor Cyan
Write-Host "  5. Wait patiently (may take 2-5 minutes)" -ForegroundColor White

Write-Host "`n=======================================" -ForegroundColor Cyan
Write-Host "  ALTERNATIVE: USE POWERSHELL UPLOAD" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

Write-Host "`nIf browser upload fails, use Microsoft Graph PowerShell:" -ForegroundColor Yellow

Write-Host "`n# Install module (one-time)" -ForegroundColor Gray
Write-Host "Install-Module Microsoft.Graph.Intune -Force" -ForegroundColor White

Write-Host "`n# Connect to Intune" -ForegroundColor Gray
Write-Host "Connect-MSGraph" -ForegroundColor White

Write-Host "`n# Upload package" -ForegroundColor Gray
Write-Host "New-IntuneWin32App -FilePath '$desktopPackage'" -ForegroundColor White

Write-Host "`n=======================================" -ForegroundColor Magenta
Write-Host "  ALTERNATIVE: REDUCE PACKAGE SIZE" -ForegroundColor Magenta
Write-Host "=======================================" -ForegroundColor Magenta

if ($RecreatePackage) {
    Write-Host "`nRecreating package with maximum compression..." -ForegroundColor Yellow
    
    # Remove old package
    Remove-Item $packagePath -Force -ErrorAction SilentlyContinue
    
    # Recreate with quiet mode
    Write-Host "  Running IntuneWinAppUtil..." -ForegroundColor Cyan
    & "C:\IntuneTools\IntuneWinAppUtil.exe" -c ".\source" -s "install-enhanced.cmd" -o ".\intune-packages" -q
    
    if (Test-Path $packagePath) {
        $newPkg = Get-Item $packagePath
        Write-Host "  ✓ New package created: $([math]::Round($newPkg.Length/1MB, 2)) MB" -ForegroundColor Green
        
        # Copy to desktop
        Copy-Item $packagePath $desktopPackage -Force
        Write-Host "  ✓ Copied to Desktop" -ForegroundColor Green
    }
}

Write-Host "`n=======================================" -ForegroundColor Green
Write-Host "  TRY THESE IN ORDER:" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

Write-Host "`n1. Use Microsoft Edge browser (not Chrome/Firefox)" -ForegroundColor White
Write-Host "2. Upload from Desktop: $desktopPackage" -ForegroundColor Cyan
Write-Host "3. Wait 5-10 minutes (don't close browser)" -ForegroundColor White
Write-Host "4. If still failing, try from different network" -ForegroundColor White
Write-Host "5. Last resort: Use PowerShell Graph API upload" -ForegroundColor White

Write-Host "`n=======================================" -ForegroundColor Cyan
Write-Host "  MONITORING UPLOAD PROGRESS" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

Write-Host "`nWhile uploading, you should see:" -ForegroundColor Yellow
Write-Host "  1. 'Uploading...' with progress bar" -ForegroundColor Gray
Write-Host "  2. Progress: 0% → 50% → 100%" -ForegroundColor Gray
Write-Host "  3. Green checkmark when complete" -ForegroundColor Gray

Write-Host "`nIf upload freezes at 0% or 50%:" -ForegroundColor Yellow
Write-Host "  • Don't close browser, wait 5 minutes" -ForegroundColor Gray
Write-Host "  • If no progress, refresh page (Ctrl+F5)" -ForegroundColor Gray
Write-Host "  • Try again with file from Desktop" -ForegroundColor Gray

Write-Host "`n=======================================" -ForegroundColor Green
Write-Host "  PACKAGE READY ON DESKTOP!" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

Write-Host "`nFile: $desktopPackage" -ForegroundColor Cyan
Write-Host "`nGood luck with the upload! 🚀" -ForegroundColor Yellow
Write-Host ""
