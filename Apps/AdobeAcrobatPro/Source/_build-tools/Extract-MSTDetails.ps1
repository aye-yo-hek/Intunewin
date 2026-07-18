# Extract-MSTDetails.ps1
# Comprehensive extraction of all MST customizations

param(
    [string]$MsiPath = ".\source\AcroPro.msi",
    [string]$MstPath = ".\source\AcroPro.mst"
)

$ErrorActionPreference = "Stop"

Write-Host "`n=======================================" -ForegroundColor Cyan
Write-Host "   MST CUSTOMIZATION EXTRACTOR" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "MSI: $MsiPath" -ForegroundColor Yellow
Write-Host "MST: $MstPath`n" -ForegroundColor Yellow

if (-not (Test-Path $MsiPath)) {
    Write-Host "ERROR: MSI not found" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $MstPath)) {
    Write-Host "ERROR: MST not found" -ForegroundColor Red
    exit 1
}

try {
    # Create Windows Installer object
    $installer = New-Object -ComObject WindowsInstaller.Installer
    
    # Get full paths
    $MsiPath = (Resolve-Path $MsiPath).Path
    $MstPath = (Resolve-Path $MstPath).Path
    
    # Open database
    $database = $installer.OpenDatabase($MsiPath, 0)
    Write-Host "✓ Opened MSI database" -ForegroundColor Green
    
    # Apply transform
    try {
        $database.ApplyTransform($MstPath, 0)
        Write-Host "✓ Applied MST transform`n" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠ Could not apply transform: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # ============================================
    # EXTRACT ALL PROPERTIES
    # ============================================
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host "   INSTALLATION PROPERTIES" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Cyan
    
    try {
        $view = $database.OpenView("SELECT Property, Value FROM Property ORDER BY Property")
        $view.Execute()
        
        $properties = @{}
        $importantProps = @()
        
        while ($record = $view.Fetch()) {
            $prop = $record.StringData(1)
            $val = $record.StringData(2)
            
            if ($prop -and $val) {
                $properties[$prop] = $val
                
                # Flag important properties
                if ($prop -match "DISABLE|ENABLE|EULA|SUPPRESS|UPDATE|REMOVE|CLOUD|SERVICES|AI|ASSISTANT|TELEMETRY|USAGE") {
                    $importantProps += [PSCustomObject]@{
                        Property = $prop
                        Value = $val
                    }
                    Write-Host "  $prop = " -NoNewline -ForegroundColor White
                    Write-Host "$val" -ForegroundColor Green
                }
            }
        }
        
        Write-Host "`nTotal Properties: $($properties.Count)" -ForegroundColor Gray
        
        if ($importantProps.Count -eq 0) {
            Write-Host "`n⚠ No cloud/AI disable properties found" -ForegroundColor Yellow
        }
        
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($view) | Out-Null
    }
    catch {
        Write-Host "ERROR reading Property table: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # ============================================
    # EXTRACT REGISTRY ENTRIES
    # ============================================
    Write-Host "`n=======================================" -ForegroundColor Cyan
    Write-Host "   REGISTRY CUSTOMIZATIONS" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Cyan
    
    try {
        $view = $database.OpenView("SELECT Registry, Root, Key, Name, Value FROM Registry ORDER BY Key")
        $view.Execute()
        
        $regCount = 0
        $cloudAIRegs = @()
        
        while ($record = $view.Fetch()) {
            $regCount++
            $root = $record.StringData(2)
            $key = $record.StringData(3)
            $name = $record.StringData(4)
            $value = $record.StringData(5)
            
            # Look for cloud/AI related entries
            if ($key -match "FeatureLockDown|cServices|cCloud|Preferences|Settings" -or
                $name -match "cloud|AI|services|sync|assistant|share|collab|telemetry|usage|feedback" -or
                $value -match "cloud|AI|services|sync|assistant|share|collab") {
                
                $rootName = switch ($root) {
                    "0" { "HKCR" }
                    "1" { "HKCU" }
                    "2" { "HKLM" }
                    "3" { "HKU" }
                    default { "Root $root" }
                }
                
                $cloudAIRegs += [PSCustomObject]@{
                    Root = $rootName
                    Key = $key
                    Name = $name
                    Value = $value
                }
                
                Write-Host "`n[$rootName]" -ForegroundColor Yellow
                Write-Host "  Key: " -NoNewline -ForegroundColor Gray
                Write-Host "$key" -ForegroundColor White
                if ($name) {
                    Write-Host "  Name: " -NoNewline -ForegroundColor Gray
                    Write-Host "$name" -ForegroundColor Cyan
                }
                if ($value) {
                    Write-Host "  Value: " -NoNewline -ForegroundColor Gray
                    Write-Host "$value" -ForegroundColor Green
                }
            }
        }
        
        Write-Host "`nTotal Registry Entries: $regCount" -ForegroundColor Gray
        Write-Host "Cloud/AI Related Entries: $($cloudAIRegs.Count)" -ForegroundColor $(if ($cloudAIRegs.Count -gt 0) { "Green" } else { "Yellow" })
        
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($view) | Out-Null
    }
    catch {
        Write-Host "ERROR reading Registry table: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # ============================================
    # EXTRACT FEATURES
    # ============================================
    Write-Host "`n=======================================" -ForegroundColor Cyan
    Write-Host "   FEATURE CUSTOMIZATIONS" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Cyan
    
    try {
        $view = $database.OpenView("SELECT Feature, Feature_Parent, Title, Description, Display, Level FROM Feature ORDER BY Feature")
        $view.Execute()
        
        $features = @()
        
        while ($record = $view.Fetch()) {
            $feature = $record.StringData(1)
            $parent = $record.StringData(2)
            $title = $record.StringData(3)
            $desc = $record.StringData(4)
            $display = $record.StringData(5)
            $level = $record.StringData(6)
            
            # Look for cloud/AI related features
            if ($feature -match "cloud|AI|services|sync|assistant|online" -or
                $title -match "cloud|AI|services|sync|assistant|online" -or
                $desc -match "cloud|AI|services|sync|assistant|online") {
                
                $features += [PSCustomObject]@{
                    Feature = $feature
                    Title = $title
                    Level = $level
                    Description = $desc
                }
                
                Write-Host "`nFeature: " -NoNewline -ForegroundColor Gray
                Write-Host "$feature" -ForegroundColor White
                if ($title) {
                    Write-Host "  Title: " -NoNewline -ForegroundColor Gray
                    Write-Host "$title" -ForegroundColor Cyan
                }
                Write-Host "  Install Level: " -NoNewline -ForegroundColor Gray
                Write-Host "$level" -ForegroundColor $(if ($level -eq "0") { "Yellow" } else { "Green" })
                if ($desc) {
                    Write-Host "  Description: $desc" -ForegroundColor Gray
                }
            }
        }
        
        if ($features.Count -eq 0) {
            Write-Host "No cloud/AI related features found (or all features installed)" -ForegroundColor Gray
        }
        
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($view) | Out-Null
    }
    catch {
        Write-Host "ERROR reading Feature table: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # ============================================
    # SUMMARY
    # ============================================
    Write-Host "`n=======================================" -ForegroundColor Cyan
    Write-Host "   VERIFICATION SUMMARY" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Cyan
    
    Write-Host "`nChecking for required cloud/AI disable settings:`n" -ForegroundColor Yellow
    
    $checks = @(
        @{ Name = "DISABLE_DOCUMENT_CLOUD"; Found = $properties.ContainsKey("DISABLE_DOCUMENT_CLOUD") },
        @{ Name = "DISABLE_SERVICES"; Found = $properties.ContainsKey("DISABLE_SERVICES") },
        @{ Name = "DISABLE_ARM_SERVICE_UPLOADS"; Found = $properties.ContainsKey("DISABLE_ARM_SERVICE_UPLOADS") },
        @{ Name = "bDisableAI (Registry)"; Found = $cloudAIRegs | Where-Object { $_.Name -eq "bDisableAI" } },
        @{ Name = "bDisableAcrobatAssistant (Registry)"; Found = $cloudAIRegs | Where-Object { $_.Name -eq "bDisableAcrobatAssistant" } },
        @{ Name = "bToggleAdobeDocumentServices (Registry)"; Found = $cloudAIRegs | Where-Object { $_.Name -eq "bToggleAdobeDocumentServices" } }
    )
    
    foreach ($check in $checks) {
        $icon = if ($check.Found) { "✓" } else { "✗" }
        $color = if ($check.Found) { "Green" } else { "Red" }
        Write-Host "  $icon $($check.Name)" -ForegroundColor $color
    }
    
    # Final verdict
    Write-Host "`n=======================================" -ForegroundColor Cyan
    $foundCount = ($checks | Where-Object { $_.Found }).Count
    
    if ($foundCount -ge 4) {
        Write-Host "✓ MST CONTAINS CLOUD/AI DISABLE SETTINGS" -ForegroundColor Green
    } elseif ($foundCount -gt 0) {
        Write-Host "⚠ MST PARTIALLY CONFIGURED" -ForegroundColor Yellow
        Write-Host "Some cloud/AI settings present, but not all" -ForegroundColor Yellow
    } else {
        Write-Host "✗ MST MISSING CLOUD/AI DISABLE SETTINGS" -ForegroundColor Red
        Write-Host "You need to add these settings to your MST" -ForegroundColor Yellow
    }
    
    Write-Host "=======================================" -ForegroundColor Cyan
    
}
catch {
    Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    if ($database) {
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($database) | Out-Null
    }
    if ($installer) {
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($installer) | Out-Null
    }
    [System.GC]::Collect()
}

Write-Host "`nPress any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
