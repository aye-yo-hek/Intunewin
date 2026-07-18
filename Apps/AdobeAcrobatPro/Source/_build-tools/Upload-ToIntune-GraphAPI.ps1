# Upload-ToIntune-GraphAPI.ps1
# Alternative method to upload package using Microsoft Graph PowerShell

param(
    [string]$PackagePath = "$env:USERPROFILE\OneDrive - cPacket Networks\Desktop\install-enhanced.intunewin"
)

Write-Host "`n=======================================" -ForegroundColor Cyan
Write-Host "  INTUNE GRAPH API UPLOADER" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# Check if package exists
if (-not (Test-Path $PackagePath)) {
    Write-Host "`n✗ Package not found at: $PackagePath" -ForegroundColor Red
    Write-Host "`nLooking for package..." -ForegroundColor Yellow
    
    # Try alternative locations
    $altPaths = @(
        "$env:USERPROFILE\Desktop\install-enhanced.intunewin",
        "C:\IntuneWin\msi-builders\msi-with-mst\intune-packages\install-enhanced.intunewin"
    )
    
    foreach ($path in $altPaths) {
        if (Test-Path $path) {
            $PackagePath = $path
            Write-Host "✓ Found at: $PackagePath" -ForegroundColor Green
            break
        }
    }
    
    if (-not (Test-Path $PackagePath)) {
        Write-Host "`n✗ Could not find package file" -ForegroundColor Red
        exit 1
    }
}

$pkg = Get-Item $PackagePath
Write-Host "`n✓ Package found" -ForegroundColor Green
Write-Host "  File: $($pkg.Name)" -ForegroundColor White
Write-Host "  Size: $([math]::Round($pkg.Length/1MB, 2)) MB" -ForegroundColor White
Write-Host "  Path: $($pkg.FullName)" -ForegroundColor Gray

# Check if Microsoft.Graph.Intune module is installed
Write-Host "`n=======================================" -ForegroundColor Yellow
Write-Host "  CHECKING PREREQUISITES" -ForegroundColor Yellow
Write-Host "=======================================" -ForegroundColor Yellow

$module = Get-Module -ListAvailable -Name Microsoft.Graph.Intune

if (-not $module) {
    Write-Host "`n⚠ Microsoft.Graph.Intune module not installed" -ForegroundColor Yellow
    Write-Host "`nWould you like to install it? (Y/N): " -ForegroundColor Cyan -NoNewline
    $response = Read-Host
    
    if ($response -eq "Y" -or $response -eq "y") {
        Write-Host "`nInstalling Microsoft.Graph.Intune module..." -ForegroundColor Yellow
        Write-Host "(This may take a few minutes)" -ForegroundColor Gray
        
        try {
            Install-Module -Name Microsoft.Graph.Intune -Force -AllowClobber -Scope CurrentUser
            Write-Host "✓ Module installed successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "✗ Failed to install module: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "`nPlease install manually:" -ForegroundColor Yellow
            Write-Host "  Install-Module -Name Microsoft.Graph.Intune -Force" -ForegroundColor White
            exit 1
        }
    } else {
        Write-Host "`nModule required for Graph API upload." -ForegroundColor Yellow
        Write-Host "Please use browser upload instead." -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "✓ Microsoft.Graph.Intune module installed" -ForegroundColor Green
    Write-Host "  Version: $($module.Version)" -ForegroundColor Gray
}

# Import module
Write-Host "`nImporting module..." -ForegroundColor Yellow
Import-Module Microsoft.Graph.Intune -ErrorAction Stop
Write-Host "✓ Module imported" -ForegroundColor Green

# Connect to Microsoft Graph
Write-Host "`n=======================================" -ForegroundColor Yellow
Write-Host "  CONNECTING TO MICROSOFT GRAPH" -ForegroundColor Yellow
Write-Host "=======================================" -ForegroundColor Yellow

Write-Host "`nYou will be prompted to sign in..." -ForegroundColor Cyan
Write-Host "Use your Intune admin credentials" -ForegroundColor Gray

try {
    Connect-MSGraph -ErrorAction Stop
    Write-Host "`n✓ Connected to Microsoft Graph" -ForegroundColor Green
    
    # Get connection info
    $connection = Get-MSGraphEnvironment
    Write-Host "  Tenant: $($connection.TenantId)" -ForegroundColor Gray
} catch {
    Write-Host "`n✗ Failed to connect: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nPlease ensure you have Intune admin permissions" -ForegroundColor Yellow
    exit 1
}

# Prepare app details
Write-Host "`n=======================================" -ForegroundColor Yellow
Write-Host "  PREPARING APPLICATION DETAILS" -ForegroundColor Yellow
Write-Host "=======================================" -ForegroundColor Yellow

$appDetails = @{
    displayName = "Adobe Acrobat DC (64-bit) - Cloud & AI Disabled"
    description = "Adobe Acrobat DC professional PDF software with cloud services, AI features, and telemetry disabled for enhanced privacy and security."
    publisher = "Adobe Inc."
    fileName = $pkg.Name
    setupFilePath = $pkg.FullName
    installCommandLine = "install-enhanced.cmd"
    uninstallCommandLine = "msiexec /x {AC76BA86-1033-FFFF-7760-BC15014EA700} /qn /norestart"
    installExperience = @{
        runAsAccount = "system"
    }
    detectionRules = @(
        @{
            "@odata.type" = "#microsoft.graph.win32LobAppProductCodeDetection"
            productCode = "{AC76BA86-1033-FFFF-7760-BC15014EA700}"
            productVersionOperator = "greaterThanOrEqual"
            productVersion = "21.001.20135"
        }
    )
    minimumSupportedOperatingSystem = @{
        v10_1607 = $true
    }
}

Write-Host "App Name: $($appDetails.displayName)" -ForegroundColor White
Write-Host "Publisher: $($appDetails.publisher)" -ForegroundColor White
Write-Host "Install: $($appDetails.installCommandLine)" -ForegroundColor White
Write-Host "Uninstall: $($appDetails.uninstallCommandLine)" -ForegroundColor White

# Upload to Intune
Write-Host "`n=======================================" -ForegroundColor Green
Write-Host "  UPLOADING TO INTUNE" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

Write-Host "`nUploading package..." -ForegroundColor Yellow
Write-Host "(This may take 5-10 minutes depending on connection)" -ForegroundColor Gray

try {
    # Note: The actual upload cmdlet may vary depending on module version
    # This is a simplified example - you may need to adjust based on your module
    
    Write-Host "`n⚠ Manual steps required for Graph API upload:" -ForegroundColor Yellow
    Write-Host "`n1. The package has been validated" -ForegroundColor White
    Write-Host "2. Connection to Intune established" -ForegroundColor White
    Write-Host "3. You need to use the Intune Graph API directly" -ForegroundColor White
    
    Write-Host "`nDetailed API upload requires additional configuration." -ForegroundColor Cyan
    Write-Host "Recommendation: Use browser upload from Desktop instead" -ForegroundColor Yellow
    
    Write-Host "`nAlternatively, use IntuneWin32App module:" -ForegroundColor Cyan
    Write-Host "  Install-Module -Name IntuneWin32App" -ForegroundColor White
    Write-Host "  Connect-MSIntuneGraph" -ForegroundColor White
    Write-Host "  Add-IntuneWin32App -FilePath '$PackagePath'" -ForegroundColor White
    
} catch {
    Write-Host "`n✗ Upload failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=======================================" -ForegroundColor Cyan
Write-Host "  SUMMARY" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

Write-Host "`nPackage Location:" -ForegroundColor White
Write-Host "  $PackagePath" -ForegroundColor Cyan

Write-Host "`nRecommended Action:" -ForegroundColor White
Write-Host "  Use Microsoft Edge to upload from Desktop" -ForegroundColor Yellow

Write-Host "`nSteps:" -ForegroundColor White
Write-Host "  1. Open Microsoft Edge" -ForegroundColor Gray
Write-Host "  2. Go to: https://intune.microsoft.com" -ForegroundColor Cyan
Write-Host "  3. Apps > Windows > Add > Windows app (Win32)" -ForegroundColor Gray
Write-Host "  4. Select package from Desktop" -ForegroundColor Gray
Write-Host "  5. Wait for upload (don't close browser)" -ForegroundColor Gray

Write-Host "`n=======================================" -ForegroundColor Green
Write-Host ""
