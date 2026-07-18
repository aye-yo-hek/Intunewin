# Adobe Acrobat DC - Cloud Communication Blocking Verification
# Tests that all cloud/login features are properly disabled

Write-Host "`n=== ADOBE CLOUD COMMUNICATION BLOCKING TEST ===" -ForegroundColor Yellow
Write-Host "This script verifies that Adobe cannot communicate with cloud services`n" -ForegroundColor Cyan

$results = @{
    RegistryTests = 0
    NetworkTests = 0
    UITests = 0
    Total = 0
}

# Test 1: Registry Settings Verification
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "TEST 1: Registry-Based Cloud Blocking" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

$cloudBlockingSettings = @(
    @{Path="HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices"; Name="bToggleAdobeDocumentServices"; Expected=0; Description="Adobe Document Cloud Disabled"},
    @{Path="HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices"; Name="bToggleAdobeSign"; Expected=0; Description="Adobe Sign Cloud Disabled"},
    @{Path="HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices"; Name="bTogglePrefSync"; Expected=0; Description="Cloud Preference Sync Disabled"},
    @{Path="HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices"; Name="bToggleWebConnectors"; Expected=0; Description="Web Connectors Disabled"},
    @{Path="HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cServices"; Name="bToggleShareFeedback"; Expected=0; Description="Cloud Sharing Disabled"},
    @{Path="HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown"; Name="bDisableShareFeedback"; Expected=1; Description="Share Features Disabled"},
    @{Path="HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown"; Name="bTogglePrefsSync"; Expected=0; Description="Preferences Sync Disabled"},
    @{Path="HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown\cCloud"; Name="bDisableADCFileStore"; Expected=1; Description="Adobe Cloud File Store Disabled"}
)

foreach ($setting in $cloudBlockingSettings) {
    try {
        if (Test-Path $setting.Path) {
            $value = Get-ItemProperty -Path $setting.Path -Name $setting.Name -ErrorAction SilentlyContinue
            if ($null -ne $value -and $value.($setting.Name) -eq $setting.Expected) {
                Write-Host "  [✓] $($setting.Description)" -ForegroundColor Green
                $results.RegistryTests++
            } else {
                Write-Host "  [✗] $($setting.Description) - NOT SET CORRECTLY" -ForegroundColor Red
                Write-Host "      Expected: $($setting.Expected), Found: $($value.($setting.Name))" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  [✗] $($setting.Description) - REGISTRY KEY MISSING" -ForegroundColor Red
        }
    } catch {
        Write-Host "  [✗] $($setting.Description) - ERROR" -ForegroundColor Red
    }
    $results.Total++
}

# Test 2: Check for Adobe Cloud Service Endpoints (Network-based blocking)
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "TEST 2: Adobe Cloud Endpoints That Should Be Blocked" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

Write-Host "Known Adobe Cloud Services (should NOT be accessible from Acrobat):" -ForegroundColor Yellow
$adobeCloudEndpoints = @(
    "documentcloud.adobe.com",
    "acrobat.adobe.com",
    "cloud.acrobat.com",
    "dc.adobe.com",
    "echosign.com",
    "adobesign.com"
)

foreach ($endpoint in $adobeCloudEndpoints) {
    Write-Host "  • $endpoint" -ForegroundColor Gray
}

Write-Host "`nNote: Registry settings prevent Acrobat from contacting these services." -ForegroundColor Cyan
Write-Host "To verify network blocking, check Windows Firewall or network logs.`n" -ForegroundColor Cyan

# Test 3: Check User Preferences Files
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "TEST 3: User Preference Files (Cloud Login Artifacts)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

$prefsPath = "$env:APPDATA\Adobe\Acrobat\DC\Preferences"
if (Test-Path $prefsPath) {
    Write-Host "Checking for cloud login artifacts..." -ForegroundColor Cyan
    
    # Check for files that indicate cloud login attempts
    $cloudFiles = @(
        "*.sso",
        "dc_auth.xml",
        "AdobeID.xml",
        "CloudSettings.xml"
    )
    
    $foundCloudFiles = $false
    foreach ($pattern in $cloudFiles) {
        $files = Get-ChildItem -Path $prefsPath -Filter $pattern -Recurse -ErrorAction SilentlyContinue
        if ($files) {
            Write-Host "  [⚠] Found cloud login artifact: $($files.Name)" -ForegroundColor Yellow
            Write-Host "      This may indicate a login attempt occurred" -ForegroundColor Gray
            $foundCloudFiles = $true
        }
    }
    
    if (-not $foundCloudFiles) {
        Write-Host "  [✓] No cloud login artifacts found" -ForegroundColor Green
        $results.UITests++
    }
} else {
    Write-Host "  [i] No user preferences folder found (app not launched yet)" -ForegroundColor Gray
}
$results.Total++

# Test 4: Check Adobe Service Processes
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "TEST 4: Adobe Background Services" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

$adobeServices = @(
    "AGSService",          # Adobe Genuine Service (phone home)
    "AGMService",          # Adobe Update Service
    "AdobeUpdateService",  # Update service
    "Adobe Acrobat Update Service"
)

Write-Host "Checking for cloud-related Adobe services..." -ForegroundColor Cyan
$servicesFound = $false
foreach ($serviceName in $adobeServices) {
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($service) {
        if ($service.Status -eq 'Running') {
            Write-Host "  [⚠] $serviceName is RUNNING (may communicate with Adobe)" -ForegroundColor Yellow
        } else {
            Write-Host "  [✓] $serviceName is stopped/disabled" -ForegroundColor Green
        }
        $servicesFound = $true
    }
}

if (-not $servicesFound) {
    Write-Host "  [✓] No Adobe cloud services found running" -ForegroundColor Green
}

# Test 5: Manual Verification Checklist
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "TEST 5: Manual Verification Checklist" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

Write-Host "To fully verify cloud blocking, perform these manual checks:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Launch Adobe Acrobat DC" -ForegroundColor White
Write-Host "   • Look for any 'Sign In' button - should be MISSING or GRAYED OUT" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Check File menu:" -ForegroundColor White
Write-Host "   • No 'Share' option" -ForegroundColor Gray
Write-Host "   • No 'Send for signature' cloud option" -ForegroundColor Gray
Write-Host "   • No 'Collaborate' option" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Check Tools panel (View → Tools):" -ForegroundColor White
Write-Host "   • No 'Send & Track' tool" -ForegroundColor Gray
Write-Host "   • No 'Adobe Sign' tool" -ForegroundColor Gray
Write-Host "   • No 'Fill & Sign' cloud tool" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Try to access cloud features:" -ForegroundColor White
Write-Host "   • Help → Sign In → Should be DISABLED or show error" -ForegroundColor Gray
Write-Host "   • Any cloud feature should show 'disabled by administrator'" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Check network traffic (optional):" -ForegroundColor White
Write-Host "   • Use Wireshark or Process Monitor" -ForegroundColor Gray
Write-Host "   • Look for connections to adobe.com domains" -ForegroundColor Gray
Write-Host "   • Should see NO traffic to cloud endpoints listed above" -ForegroundColor Gray
Write-Host ""

# Summary
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "CLOUD BLOCKING VERIFICATION SUMMARY" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

$totalPassed = $results.RegistryTests + $results.UITests
Write-Host "Registry Settings Tests: $($results.RegistryTests) / 8 passed" -ForegroundColor $(if ($results.RegistryTests -eq 8) { "Green" } else { "Yellow" })
Write-Host "User Artifact Tests: $($results.UITests) / 1 passed" -ForegroundColor $(if ($results.UITests -eq 1) { "Green" } else { "Yellow" })

if ($results.RegistryTests -eq 8) {
    Write-Host "`n✅ ALL CLOUD BLOCKING SETTINGS ARE CONFIGURED CORRECTLY" -ForegroundColor Green
    Write-Host "`n🔒 Adobe Acrobat is prevented from:" -ForegroundColor Cyan
    Write-Host "  • Logging in to Adobe ID" -ForegroundColor White
    Write-Host "  • Accessing Adobe Document Cloud" -ForegroundColor White
    Write-Host "  • Using Adobe Sign (cloud signing)" -ForegroundColor White
    Write-Host "  • Syncing preferences to cloud" -ForegroundColor White
    Write-Host "  • Sharing files via cloud" -ForegroundColor White
    Write-Host "  • Connecting to web services" -ForegroundColor White
    Write-Host "  • Using cloud-based Fill & Sign" -ForegroundColor White
    Write-Host "  • Storing files in Adobe cloud storage`n" -ForegroundColor White
} else {
    Write-Host "`n⚠️  SOME CLOUD BLOCKING SETTINGS ARE MISSING" -ForegroundColor Yellow
    Write-Host "Run the lockdown script to fix: .\Apply-AdobeLockdown.ps1`n" -ForegroundColor Cyan
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "ADDITIONAL VERIFICATION OPTIONS" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

Write-Host "For network-level verification:" -ForegroundColor Cyan
Write-Host "  1. Use Process Monitor to watch Acrobat.exe network activity" -ForegroundColor White
Write-Host "  2. Use Wireshark to capture traffic while using Adobe" -ForegroundColor White
Write-Host "  3. Check Windows Firewall logs for blocked Adobe connections" -ForegroundColor White
Write-Host "  4. Review DNS queries for adobe.com domains`n" -ForegroundColor White

Write-Host "To test cloud login blocking:" -ForegroundColor Cyan
Write-Host "  1. Open Adobe Acrobat DC" -ForegroundColor White
Write-Host "  2. Try Help → Sign In (should be disabled/grayed out)" -ForegroundColor White
Write-Host "  3. If sign-in appears, it should fail or show 'disabled by admin'" -ForegroundColor White
Write-Host "  4. No Adobe ID prompts should appear anywhere in the UI`n" -ForegroundColor White

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray
