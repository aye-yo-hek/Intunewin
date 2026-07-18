# Adobe Acrobat DC - Lockdown Verification Script
# Verifies that cloud, AI, telemetry, and collaboration features are disabled

Write-Host "`n=== ADOBE ACROBAT DC - LOCKDOWN VERIFICATION ===" -ForegroundColor Yellow
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor Gray
Write-Host "User: $env:USERNAME`n" -ForegroundColor Gray

$results = @{
    Passed = 0
    Failed = 0
    Details = @()
}

function Test-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [int]$ExpectedValue,
        [string]$Description
    )
    
    try {
        if (Test-Path $Path) {
            $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            if ($null -ne $value) {
                $actualValue = $value.$Name
                if ($actualValue -eq $ExpectedValue) {
                    Write-Host "  [✓] $Description" -ForegroundColor Green
                    Write-Host "      Registry: $Path\$Name = $actualValue" -ForegroundColor Gray
                    $script:results.Passed++
                    $script:results.Details += [PSCustomObject]@{
                        Status = "PASS"
                        Setting = $Description
                        Expected = $ExpectedValue
                        Actual = $actualValue
                        Path = "$Path\$Name"
                    }
                    return $true
                } else {
                    Write-Host "  [✗] $Description - INCORRECT VALUE" -ForegroundColor Red
                    Write-Host "      Registry: $Path\$Name" -ForegroundColor Gray
                    Write-Host "      Expected: $ExpectedValue, Found: $actualValue" -ForegroundColor Yellow
                    $script:results.Failed++
                    $script:results.Details += [PSCustomObject]@{
                        Status = "FAIL"
                        Setting = $Description
                        Expected = $ExpectedValue
                        Actual = $actualValue
                        Path = "$Path\$Name"
                    }
                    return $false
                }
            } else {
                Write-Host "  [✗] $Description - NOT CONFIGURED" -ForegroundColor Red
                Write-Host "      Registry: $Path\$Name (value not found)" -ForegroundColor Gray
                $script:results.Failed++
                $script:results.Details += [PSCustomObject]@{
                    Status = "FAIL"
                    Setting = $Description
                    Expected = $ExpectedValue
                    Actual = "Not Set"
                    Path = "$Path\$Name"
                }
                return $false
            }
        } else {
            Write-Host "  [✗] $Description - REGISTRY KEY MISSING" -ForegroundColor Red
            Write-Host "      Registry: $Path (key not found)" -ForegroundColor Gray
            $script:results.Failed++
            $script:results.Details += [PSCustomObject]@{
                Status = "FAIL"
                Setting = $Description
                Expected = $ExpectedValue
                Actual = "Key Missing"
                Path = "$Path\$Name"
            }
            return $false
        }
    } catch {
        Write-Host "  [✗] $Description - ERROR: $_" -ForegroundColor Red
        $script:results.Failed++
        return $false
    }
}

# Check if Adobe Acrobat DC is installed
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "STEP 1: Checking Adobe Acrobat DC Installation" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

$productCode = "{AC76BA86-1033-FFFF-7760-BC15014EA700}"
$installPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$productCode"

if (Test-Path $installPath) {
    $app = Get-ItemProperty -Path $installPath
    Write-Host "  [✓] Adobe Acrobat DC is installed" -ForegroundColor Green
    Write-Host "      Version: $($app.DisplayVersion)" -ForegroundColor Gray
    Write-Host "      Install Date: $($app.InstallDate)" -ForegroundColor Gray
    Write-Host "      Install Location: $($app.InstallLocation)" -ForegroundColor Gray
} else {
    Write-Host "  [✗] Adobe Acrobat DC is NOT installed" -ForegroundColor Red
    Write-Host "`nCannot verify lockdown settings without installation.`n" -ForegroundColor Yellow
    exit 1
}

# Base registry path
$basePath = "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown"

# 1. AI Assistant Settings
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "STEP 2: Verifying AI Assistant Disable Settings" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

Test-RegistryValue -Path $basePath -Name "bDisableAI" -ExpectedValue 1 -Description "AI Assistant Disabled"
Test-RegistryValue -Path $basePath -Name "bDisableAcrobatAssistant" -ExpectedValue 1 -Description "Acrobat Assistant Disabled"

# 2. Cloud Services Settings
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "STEP 3: Verifying Cloud Services Disable Settings" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

$cServicesPath = "$basePath\cServices"
Test-RegistryValue -Path $cServicesPath -Name "bToggleAdobeDocumentServices" -ExpectedValue 0 -Description "Adobe Document Cloud Disabled"
Test-RegistryValue -Path $cServicesPath -Name "bToggleAdobeSign" -ExpectedValue 0 -Description "Adobe Sign (Cloud Signing) Disabled"
Test-RegistryValue -Path $cServicesPath -Name "bTogglePrefSync" -ExpectedValue 0 -Description "Preference Sync Disabled"
Test-RegistryValue -Path $cServicesPath -Name "bToggleWebConnectors" -ExpectedValue 0 -Description "Web Connectors Disabled"

# 3. Collaboration & Sharing Settings
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "STEP 4: Verifying Collaboration Features Disabled" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

Test-RegistryValue -Path $basePath -Name "bDisableShareFeedback" -ExpectedValue 1 -Description "Share & Feedback Disabled"
Test-RegistryValue -Path $basePath -Name "bToggleFillSign" -ExpectedValue 0 -Description "Fill & Sign Cloud Features Disabled"
Test-RegistryValue -Path $cServicesPath -Name "bToggleShareFeedback" -ExpectedValue 0 -Description "Cloud Feedback Sharing Disabled"

# 4. Telemetry Settings
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "STEP 5: Verifying Telemetry Disable Settings" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

Test-RegistryValue -Path "$basePath\cIPM" -Name "bDontShowMsgWhenViewingDoc" -ExpectedValue 1 -Description "In-Product Messaging Disabled"
Test-RegistryValue -Path "$basePath\cCloud" -Name "bDisableADCFileStore" -ExpectedValue 1 -Description "Adobe Document Cloud File Store Disabled"

# Additional important lockdown settings
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "STEP 6: Verifying Additional Lockdown Settings" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

Test-RegistryValue -Path $basePath -Name "bTogglePrefsSync" -ExpectedValue 0 -Description "Preferences Sync Disabled"
Test-RegistryValue -Path $cServicesPath -Name "bUpdater" -ExpectedValue 0 -Description "Automatic Updates Disabled"
Test-RegistryValue -Path $basePath -Name "bProtectedMode" -ExpectedValue 1 -Description "Protected Mode Enabled (Security)"

# Summary
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "VERIFICATION SUMMARY" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

Write-Host "Total Tests: $($results.Passed + $results.Failed)" -ForegroundColor Cyan
Write-Host "Passed: $($results.Passed)" -ForegroundColor Green
Write-Host "Failed: $($results.Failed)" -ForegroundColor $(if ($results.Failed -eq 0) { "Green" } else { "Red" })

$percentage = [math]::Round(($results.Passed / ($results.Passed + $results.Failed)) * 100, 1)
Write-Host "Success Rate: $percentage%`n" -ForegroundColor $(if ($percentage -eq 100) { "Green" } elseif ($percentage -ge 80) { "Yellow" } else { "Red" })

if ($results.Failed -gt 0) {
    Write-Host "⚠️  FAILED CHECKS - ACTION REQUIRED:" -ForegroundColor Red
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray
    
    $failures = $results.Details | Where-Object { $_.Status -eq "FAIL" }
    foreach ($failure in $failures) {
        Write-Host "  Setting: $($failure.Setting)" -ForegroundColor Yellow
        Write-Host "  Path: $($failure.Path)" -ForegroundColor Gray
        Write-Host "  Expected: $($failure.Expected), Actual: $($failure.Actual)`n" -ForegroundColor Gray
    }
    
    Write-Host "To fix these issues, run:" -ForegroundColor Yellow
    Write-Host "  .\Apply-AdobeLockdown.ps1`n" -ForegroundColor Cyan
} else {
    Write-Host "✅ ALL LOCKDOWN SETTINGS VERIFIED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "`n🔒 Adobe Acrobat DC is properly locked down:" -ForegroundColor Cyan
    Write-Host "  • AI features are disabled" -ForegroundColor White
    Write-Host "  • Cloud services are disabled" -ForegroundColor White
    Write-Host "  • Document Cloud is disabled" -ForegroundColor White
    Write-Host "  • Telemetry is disabled" -ForegroundColor White
    Write-Host "  • Collaboration features are disabled`n" -ForegroundColor White
}

# Manual verification instructions
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "MANUAL VERIFICATION STEPS (OPTIONAL)" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

Write-Host "1. Launch Adobe Acrobat DC" -ForegroundColor Cyan
Write-Host "2. Go to: Edit → Preferences → Services" -ForegroundColor White
Write-Host "   Expected: 'Services are disabled by your administrator'`n" -ForegroundColor Gray

Write-Host "3. Check the toolbar:" -ForegroundColor Cyan
Write-Host "   • No AI Assistant icon should be visible" -ForegroundColor White
Write-Host "   • No 'Share to cloud' button" -ForegroundColor White
Write-Host "   • No Adobe Sign features`n" -ForegroundColor White

Write-Host "4. Go to: Help menu" -ForegroundColor Cyan
Write-Host "   • AI features should be absent or grayed out`n" -ForegroundColor White

Write-Host "5. Check: View → Tools" -ForegroundColor Cyan
Write-Host "   • Cloud-related tools should be missing or disabled`n" -ForegroundColor White

# Export results
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "EXPORTING RESULTS" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

$exportPath = "$env:TEMP\Adobe_Lockdown_Verification_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$results.Details | Format-Table -AutoSize | Out-File -FilePath $exportPath
Write-Host "Results exported to: $exportPath`n" -ForegroundColor Green

# Return exit code
if ($results.Failed -eq 0) {
    Write-Host "Exit Code: 0 (SUCCESS)`n" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Exit Code: 1 (FAILED - Some settings not configured)`n" -ForegroundColor Red
    exit 1
}
