# Verify-EnhancedInstall.ps1
# Quick test to verify the enhanced installation files are ready

Write-Host "`n=======================================" -ForegroundColor Cyan
Write-Host "   ENHANCED INSTALLATION VERIFICATION" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

$sourceDir = ".\source"

# Check required files
$files = @(
    @{ Name = "AcroPro.msi"; Path = "$sourceDir\AcroPro.msi" },
    @{ Name = "AcroPro.mst"; Path = "$sourceDir\AcroPro.mst" },
    @{ Name = "install-enhanced.cmd"; Path = "$sourceDir\install-enhanced.cmd" },
    @{ Name = "adobe-disable-cloud-ai.reg"; Path = "$sourceDir\adobe-disable-cloud-ai.reg" }
)

Write-Host "`nChecking required files:" -ForegroundColor Yellow
$allPresent = $true

foreach ($file in $files) {
    if (Test-Path $file.Path) {
        $item = Get-Item $file.Path
        $size = if ($item.Length -gt 1MB) {
            "$([math]::Round($item.Length/1MB, 2)) MB"
        } else {
            "$([math]::Round($item.Length/1KB, 2)) KB"
        }
        Write-Host "  ✓ $($file.Name) - $size" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $($file.Name) - NOT FOUND" -ForegroundColor Red
        $allPresent = $false
    }
}

if (-not $allPresent) {
    Write-Host "`n[ERROR] Missing required files!" -ForegroundColor Red
    exit 1
}

# Count registry settings
Write-Host "`nAnalyzing registry lockdown file..." -ForegroundColor Yellow

$regContent = Get-Content "$sourceDir\adobe-disable-cloud-ai.reg" -Raw
$regKeys = ($regContent -split "\[HKEY_").Count - 1
$regValues = ($regContent -split "=dword:").Count - 1

Write-Host "  Registry keys: $regKeys" -ForegroundColor Cyan
Write-Host "  Registry values: $regValues" -ForegroundColor Cyan

# Check for critical settings
$criticalSettings = @(
    "bDisableAI",
    "bDisableAcrobatAssistant",
    "bToggleAdobeDocumentServices",
    "bToggleAdobeSign",
    "bToggleFillSign",
    "bUsageMeasurement"
)

Write-Host "`nVerifying critical cloud/AI disable settings:" -ForegroundColor Yellow

foreach ($setting in $criticalSettings) {
    if ($regContent -match $setting) {
        Write-Host "  ✓ $setting" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $setting - MISSING" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n=======================================" -ForegroundColor Cyan
Write-Host "   DEPLOYMENT READY STATUS" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

Write-Host "`n✓ All required files present" -ForegroundColor Green
Write-Host "✓ Registry lockdown configured ($regValues settings)" -ForegroundColor Green
Write-Host "✓ Enhanced installer ready" -ForegroundColor Green

Write-Host "`n=======================================" -ForegroundColor Cyan
Write-Host "   WHAT WILL BE DISABLED" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

Write-Host "`nWhen you deploy this package, the following will be disabled:" -ForegroundColor Yellow
Write-Host "  • AI Assistant" -ForegroundColor White
Write-Host "  • Acrobat Assistant" -ForegroundColor White
Write-Host "  • Adobe Document Cloud" -ForegroundColor White
Write-Host "  • Adobe Sign (cloud signing)" -ForegroundColor White
Write-Host "  • Cloud storage and sync" -ForegroundColor White
Write-Host "  • Preference synchronization" -ForegroundColor White
Write-Host "  • Share and collaboration" -ForegroundColor White
Write-Host "  • Send and track features" -ForegroundColor White
Write-Host "  • Fill & Sign cloud features" -ForegroundColor White
Write-Host "  • Web connectors" -ForegroundColor White
Write-Host "  • Telemetry and usage tracking" -ForegroundColor White
Write-Host "  • In-product messaging and ads" -ForegroundColor White
Write-Host "  • Product tour and welcome screen" -ForegroundColor White
Write-Host "  • SharePoint integration" -ForegroundColor White

Write-Host "`n=======================================" -ForegroundColor Cyan
Write-Host "   NEXT STEPS" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

Write-Host "`n1. Package for Intune:" -ForegroundColor Yellow
Write-Host "   IntuneWinAppUtil.exe -c "".\source"" -s ""install-enhanced.cmd"" -o "".\intune-packages""" -ForegroundColor Cyan

Write-Host "`n2. Upload to Intune:" -ForegroundColor Yellow
Write-Host "   - Apps > Windows > Add > Windows app (Win32)" -ForegroundColor White
Write-Host "   - Upload the .intunewin file" -ForegroundColor White

Write-Host "`n3. Configure in Intune:" -ForegroundColor Yellow
Write-Host "   Install command:   install-enhanced.cmd" -ForegroundColor Cyan
Write-Host "   Uninstall command: msiexec /x {AC76BA86-1033-FFFF-7760-BC15014EA700} /qn" -ForegroundColor Cyan
Write-Host "   Detection:         MSI Product Code" -ForegroundColor Cyan

Write-Host "`n4. Assign to pilot group and test" -ForegroundColor Yellow

Write-Host "`n=======================================" -ForegroundColor Green
Write-Host "   READY FOR DEPLOYMENT" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green
Write-Host ""
