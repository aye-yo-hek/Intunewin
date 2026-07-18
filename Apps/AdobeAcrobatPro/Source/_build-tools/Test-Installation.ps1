# Test-Installation.ps1
# Tests installation and uninstallation of Adobe Acrobat DC with MST transforms

param(
    [ValidateSet("Bundle", "Merged", "Both")]
    [string]$Method = "Both",
    [switch]$SkipUninstall
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== ADOBE ACROBAT DC INSTALLATION TEST ===" -ForegroundColor Cyan
Write-Host "Test Method: $Method`n" -ForegroundColor Cyan

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ This script must be run as Administrator" -ForegroundColor Red
    Write-Host "   Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Running as Administrator`n" -ForegroundColor Green

# Product information
$productCode = "{AC76BA86-1033-FFFF-7760-BC15014EA700}"
$productName = "Adobe Acrobat DC"
$installPath = "C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe"

# Function to check if product is installed
function Test-ProductInstalled {
    param([string]$Code)
    
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$Code",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$Code"
    )
    
    foreach ($path in $regPaths) {
        if (Test-Path $path) {
            $props = Get-ItemProperty $path -ErrorAction SilentlyContinue
            if ($props) {
                return @{
                    Installed = $true
                    DisplayName = $props.DisplayName
                    Version = $props.DisplayVersion
                    InstallDate = $props.InstallDate
                    Publisher = $props.Publisher
                }
            }
        }
    }
    
    return @{ Installed = $false }
}

# Function to verify cloud/AI settings
function Test-AdobeSettings {
    Write-Host "`n=== VERIFYING ADOBE SETTINGS ===" -ForegroundColor Yellow
    
    $settingsOK = $true
    
    # Check FeatureLockDown registry
    $featureLockDown = "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown"
    
    if (Test-Path $featureLockDown) {
        Write-Host "✓ FeatureLockDown policies exist" -ForegroundColor Green
        
        $settings = Get-ItemProperty $featureLockDown -ErrorAction SilentlyContinue
        
        # Check for common disable flags
        $expectedSettings = @{
            "bDisableShareFeedback" = 1
            "bDisableTrustedSites" = 1
            "bDisableAcrobatUpdate" = 0  # We want updates enabled
            "bToggleFillSign" = 0
            "bTogglePrefsSync" = 0
        }
        
        foreach ($key in $expectedSettings.Keys) {
            if ($settings.PSObject.Properties.Name -contains $key) {
                $value = $settings.$key
                Write-Host "  $key = $value" -ForegroundColor Cyan
            }
        }
    } else {
        Write-Host "⚠️  FeatureLockDown policies not found" -ForegroundColor Yellow
        Write-Host "   (This may be expected if MST doesn't include these)" -ForegroundColor Gray
    }
    
    # Check Services registry
    $servicesKey = "HKLM:\SOFTWARE\Adobe\Adobe Acrobat\DC\Preferences"
    
    if (Test-Path $servicesKey) {
        Write-Host "`n✓ Preferences registry key exists" -ForegroundColor Green
        $prefs = Get-ItemProperty $servicesKey -ErrorAction SilentlyContinue
        
        # Display all preferences
        $prefs.PSObject.Properties | Where-Object { $_.Name -notmatch "^PS" } | ForEach-Object {
            Write-Host "  $($_.Name) = $($_.Value)" -ForegroundColor Cyan
        }
    }
    
    # Check for HKCU settings (these may not exist until user runs app)
    Write-Host "`n⚠️  User-level settings (HKCU) will only appear after first launch" -ForegroundColor Yellow
    
    return $settingsOK
}

# Function to install using bundle method
function Install-Bundle {
    Write-Host "`n=== METHOD 1: BUNDLE INSTALLATION ===" -ForegroundColor Cyan
    
    $msiPath = ".\source\AcroPro.msi"
    $mstPath = ".\source\AcroPro.mst"
    
    if (-not (Test-Path $msiPath)) {
        Write-Host "❌ MSI not found: $msiPath" -ForegroundColor Red
        return $false
    }
    
    if (-not (Test-Path $mstPath)) {
        Write-Host "❌ MST not found: $mstPath" -ForegroundColor Red
        return $false
    }
    
    Write-Host "Installing with MST transform..." -ForegroundColor Yellow
    
    $logPath = "$env:TEMP\AcroPro-Bundle-Install.log"
    
    # Build command
    $msiFullPath = (Resolve-Path $msiPath).Path
    $mstFullPath = (Resolve-Path $mstPath).Path
    
    $arguments = @(
        "/i"
        "`"$msiFullPath`""
        "TRANSFORMS=`"$mstFullPath`""
        "/qn"
        "/norestart"
        "/l*v"
        "`"$logPath`""
    )
    
    Write-Host "Command: msiexec $($arguments -join ' ')" -ForegroundColor Gray
    
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -PassThru -NoNewWindow
    
    Write-Host "`nInstallation exit code: $($process.ExitCode)" -ForegroundColor $(if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) { "Green" } else { "Red" })
    Write-Host "Log file: $logPath" -ForegroundColor Gray
    
    if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
        Write-Host "✓ Installation completed successfully" -ForegroundColor Green
        
        # Wait for installation to settle
        Start-Sleep -Seconds 5
        
        # Verify installation
        $status = Test-ProductInstalled -Code $productCode
        if ($status.Installed) {
            Write-Host "✓ Product detected in registry" -ForegroundColor Green
            Write-Host "  Name: $($status.DisplayName)" -ForegroundColor Cyan
            Write-Host "  Version: $($status.Version)" -ForegroundColor Cyan
        }
        
        if (Test-Path $installPath) {
            Write-Host "✓ Executable found: $installPath" -ForegroundColor Green
        }
        
        # Check settings
        Test-AdobeSettings
        
        return $true
    } else {
        Write-Host "❌ Installation failed with code: $($process.ExitCode)" -ForegroundColor Red
        
        # Show last 20 lines of log
        if (Test-Path $logPath) {
            Write-Host "`nLast 20 lines of log:" -ForegroundColor Yellow
            Get-Content $logPath -Tail 20 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        }
        
        return $false
    }
}

# Function to install using merged method
function Install-Merged {
    Write-Host "`n=== METHOD 2: MERGED MSI INSTALLATION ===" -ForegroundColor Cyan
    
    $msiPath = ".\output\AcroPro-Merged.msi"
    
    if (-not (Test-Path $msiPath)) {
        Write-Host "❌ Merged MSI not found: $msiPath" -ForegroundColor Red
        return $false
    }
    
    Write-Host "Installing merged MSI..." -ForegroundColor Yellow
    
    $logPath = "$env:TEMP\AcroPro-Merged-Install.log"
    
    $msiFullPath = (Resolve-Path $msiPath).Path
    
    $arguments = @(
        "/i"
        "`"$msiFullPath`""
        "/qn"
        "/norestart"
        "/l*v"
        "`"$logPath`""
    )
    
    Write-Host "Command: msiexec $($arguments -join ' ')" -ForegroundColor Gray
    
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -PassThru -NoNewWindow
    
    Write-Host "`nInstallation exit code: $($process.ExitCode)" -ForegroundColor $(if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) { "Green" } else { "Red" })
    Write-Host "Log file: $logPath" -ForegroundColor Gray
    
    if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
        Write-Host "✓ Installation completed successfully" -ForegroundColor Green
        
        Start-Sleep -Seconds 5
        
        $status = Test-ProductInstalled -Code $productCode
        if ($status.Installed) {
            Write-Host "✓ Product detected in registry" -ForegroundColor Green
            Write-Host "  Name: $($status.DisplayName)" -ForegroundColor Cyan
            Write-Host "  Version: $($status.Version)" -ForegroundColor Cyan
        }
        
        if (Test-Path $installPath) {
            Write-Host "✓ Executable found: $installPath" -ForegroundColor Green
        }
        
        Test-AdobeSettings
        
        return $true
    } else {
        Write-Host "❌ Installation failed with code: $($process.ExitCode)" -ForegroundColor Red
        
        if (Test-Path $logPath) {
            Write-Host "`nLast 20 lines of log:" -ForegroundColor Yellow
            Get-Content $logPath -Tail 20 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        }
        
        return $false
    }
}

# Function to uninstall
function Uninstall-Product {
    Write-Host "`n=== UNINSTALLATION ===" -ForegroundColor Cyan
    
    $status = Test-ProductInstalled -Code $productCode
    if (-not $status.Installed) {
        Write-Host "⚠️  Product is not installed, nothing to uninstall" -ForegroundColor Yellow
        return $true
    }
    
    Write-Host "Uninstalling $productName..." -ForegroundColor Yellow
    
    $logPath = "$env:TEMP\AcroPro-Uninstall.log"
    
    $arguments = @(
        "/x"
        $productCode
        "/qn"
        "/norestart"
        "/l*v"
        "`"$logPath`""
    )
    
    Write-Host "Command: msiexec $($arguments -join ' ')" -ForegroundColor Gray
    
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -PassThru -NoNewWindow
    
    Write-Host "`nUninstallation exit code: $($process.ExitCode)" -ForegroundColor $(if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) { "Green" } else { "Red" })
    Write-Host "Log file: $logPath" -ForegroundColor Gray
    
    if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
        Write-Host "✓ Uninstallation completed successfully" -ForegroundColor Green
        
        Start-Sleep -Seconds 5
        
        # Verify removal
        $status = Test-ProductInstalled -Code $productCode
        if (-not $status.Installed) {
            Write-Host "✓ Product removed from registry" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Product still appears in registry" -ForegroundColor Yellow
        }
        
        if (-not (Test-Path $installPath)) {
            Write-Host "✓ Executable removed: $installPath" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Executable still exists (may be normal for shared components)" -ForegroundColor Yellow
        }
        
        # Check for leftover files
        $installDir = "C:\Program Files\Adobe\Acrobat DC"
        if (Test-Path $installDir) {
            $remainingFiles = Get-ChildItem $installDir -Recurse -ErrorAction SilentlyContinue
            if ($remainingFiles) {
                Write-Host "⚠️  $($remainingFiles.Count) files/folders remain in install directory" -ForegroundColor Yellow
                Write-Host "   (This may be expected for shared Adobe components)" -ForegroundColor Gray
            }
        } else {
            Write-Host "✓ Install directory removed completely" -ForegroundColor Green
        }
        
        return $true
    } else {
        Write-Host "❌ Uninstallation failed with code: $($process.ExitCode)" -ForegroundColor Red
        
        if (Test-Path $logPath) {
            Write-Host "`nLast 20 lines of log:" -ForegroundColor Yellow
            Get-Content $logPath -Tail 20 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        }
        
        return $false
    }
}

# Main test flow
Write-Host "=== PRE-TEST CHECK ===" -ForegroundColor Yellow
$preStatus = Test-ProductInstalled -Code $productCode

if ($preStatus.Installed) {
    Write-Host "⚠️  $productName is already installed" -ForegroundColor Yellow
    Write-Host "   Version: $($preStatus.Version)" -ForegroundColor Cyan
    
    $response = Read-Host "Uninstall existing version? (Y/N)"
    if ($response -eq "Y" -or $response -eq "y") {
        Uninstall-Product
        Start-Sleep -Seconds 3
    } else {
        Write-Host "Skipping installation test (product already installed)" -ForegroundColor Yellow
        exit 0
    }
}

# Run tests based on method
$testResults = @()

if ($Method -eq "Bundle" -or $Method -eq "Both") {
    $result = Install-Bundle
    $testResults += @{ Method = "Bundle"; Success = $result }
    
    if ($result -and -not $SkipUninstall) {
        Start-Sleep -Seconds 3
        Uninstall-Product
        Start-Sleep -Seconds 3
    }
}

if ($Method -eq "Merged" -or $Method -eq "Both") {
    # Only test merged if bundle succeeded and was uninstalled, or if testing merged only
    if ($Method -eq "Merged" -or ($testResults[-1].Success -and -not $SkipUninstall)) {
        $result = Install-Merged
        $testResults += @{ Method = "Merged"; Success = $result }
        
        if ($result -and -not $SkipUninstall) {
            Start-Sleep -Seconds 3
            Uninstall-Product
        }
    }
}

# Summary
Write-Host "`n=== TEST SUMMARY ===" -ForegroundColor Cyan

foreach ($result in $testResults) {
    $icon = if ($result.Success) { "✓" } else { "❌" }
    $color = if ($result.Success) { "Green" } else { "Red" }
    Write-Host "$icon $($result.Method) Method: $(if ($result.Success) { 'PASS' } else { 'FAIL' })" -ForegroundColor $color
}

Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Yellow
Write-Host "1. Review installation logs in $env:TEMP" -ForegroundColor Gray
Write-Host "2. If installed, launch Acrobat manually to verify settings:" -ForegroundColor Gray
Write-Host "   - Edit > Preferences > Services (should be disabled/limited)" -ForegroundColor Gray
Write-Host "   - Help > Check for Updates (verify update behavior)" -ForegroundColor Gray
Write-Host "3. Check for AI Assistant or cloud features in the UI" -ForegroundColor Gray
Write-Host "4. Package successful method for Intune deployment" -ForegroundColor Gray

Write-Host "`n=== TEST COMPLETE ===" -ForegroundColor Cyan
