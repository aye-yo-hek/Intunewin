# Inspect-MST.ps1
# Extracts and displays MST transform contents to verify customizations

param(
    [string]$MstPath = ".\source\AcroPro.mst",
    [string]$MsiPath = ".\source\AcroPro.msi"
)

Write-Host "`n=== MST INSPECTION TOOL ===" -ForegroundColor Cyan
Write-Host "Analyzing: $MstPath`n" -ForegroundColor Cyan

# Check if files exist
if (-not (Test-Path $MstPath)) {
    Write-Host "❌ MST file not found: $MstPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $MsiPath)) {
    Write-Host "❌ MSI file not found: $MsiPath" -ForegroundColor Red
    exit 1
}

try {
    # Create Windows Installer object
    $installer = New-Object -ComObject WindowsInstaller.Installer
    
    # Convert to absolute paths
    $MsiPath = (Resolve-Path $MsiPath).Path
    $MstPath = (Resolve-Path $MstPath).Path
    
    # Open database in read-only mode (0)
    $database = $installer.OpenDatabase($MsiPath, 0)
    
    Write-Host "✓ Opened MSI database" -ForegroundColor Green
    
    # Apply the transform to see what changes it makes
    try {
        $database.ApplyTransform($MstPath, 0)
        Write-Host "✓ Applied MST transform to database" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️  Could not apply transform: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "   Continuing with base MSI analysis..." -ForegroundColor Gray
    }
    
    # Get file info
    $mstFile = Get-Item $MstPath
    Write-Host "✓ MST Size: $([math]::Round($mstFile.Length/1KB, 2)) KB" -ForegroundColor Green
    Write-Host "✓ MST Modified: $($mstFile.LastWriteTime)`n" -ForegroundColor Green
    
    # List of Adobe Acrobat tables that typically contain preferences
    $tablesToCheck = @(
        "Property",
        "Registry", 
        "Feature",
        "CustomAction",
        "InstallExecuteSequence"
    )
    
    Write-Host "=== CHECKING KEY TABLES ===" -ForegroundColor Yellow
    
    foreach ($tableName in $tablesToCheck) {
        try {
            $query = "SELECT * FROM $tableName"
            $view = $database.OpenView($query)
            $view.Execute()
            
            $recordCount = 0
            while ($record = $view.Fetch()) {
                $recordCount++
                if ($recordCount -le 50) {  # Limit output
                    Write-Host "`n--- $tableName Record $recordCount ---" -ForegroundColor Cyan
                    
                    # Get field count
                    $fieldCount = $record.FieldCount
                    for ($i = 1; $i -le $fieldCount; $i++) {
                        try {
                            $value = $record.StringData($i)
                            if ($value) {
                                Write-Host "  Field $i : $value"
                                
                                # Flag important settings
                                if ($value -match "cloud|AI|assistant|services|sync|collaboration|review|share|acrobat.com|documentcloud|creative.adobe.com" -and 
                                    $value -notmatch "\\CloudDocs\\|Local\\") {
                                    Write-Host "    ⚠️  CLOUD/AI RELATED SETTING DETECTED" -ForegroundColor Magenta
                                }
                            }
                        }
                        catch {
                            # Some fields might not be strings
                        }
                    }
                }
            }
            
            if ($recordCount -gt 0) {
                Write-Host "`n✓ $tableName : $recordCount records" -ForegroundColor Green
                if ($recordCount -gt 50) {
                    Write-Host "  (Showing first 50 records)" -ForegroundColor Gray
                }
            }
            
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($view) | Out-Null
        }
        catch {
            # Table doesn't exist or can't be read
            Write-Host "⚠️  $tableName : Not accessible or empty" -ForegroundColor Gray
        }
    }
    
    Write-Host "`n=== SEARCHING FOR KEY PROPERTIES ===" -ForegroundColor Yellow
    
    # Common Adobe properties to disable cloud/AI features
    $keyProperties = @(
        "DISABLE_ARM_SERVICE_UPLOADS",
        "DISABLE_DISTILLER_ADVERT", 
        "DISABLE_PDFMAKER_STAMPING",
        "DISABLE_PRODUCT_TOUR",
        "DISABLE_ACROBAT_COM",
        "DISABLE_DOCUMENT_CLOUD",
        "DISABLE_SERVICES",
        "EULA_ACCEPT",
        "ENABLE_CHROMEEXT",
        "ENABLE_OPTIMIZATION",
        "ENABLE_USAGE_STATS",
        "SUPPRESS_APP_OPEN_ON_INSTALL_COMPLETE",
        "UPDATE_MODE",
        "REMOVE_PREVIOUS",
        "IGNOREVCRT64"
    )
    
    try {
        $view = $database.OpenView("SELECT Property, Value FROM Property")
        $view.Execute()
        
        $foundProperties = @{}
        while ($record = $view.Fetch()) {
            $prop = $record.StringData(1)
            $val = $record.StringData(2)
            
            if ($keyProperties -contains $prop) {
                $foundProperties[$prop] = $val
                Write-Host "✓ $prop = $val" -ForegroundColor Green
            }
        }
        
        # Check which expected properties are missing
        Write-Host "`nMissing Properties:" -ForegroundColor Yellow
        foreach ($prop in $keyProperties) {
            if (-not $foundProperties.ContainsKey($prop)) {
                Write-Host "  - $prop" -ForegroundColor Gray
            }
        }
        
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($view) | Out-Null
    }
    catch {
        Write-Host "⚠️  Unable to read Property table" -ForegroundColor Yellow
    }
    
    Write-Host "`n=== REGISTRY ANALYSIS ===" -ForegroundColor Yellow
    
    try {
        $view = $database.OpenView("SELECT Registry, Root, Key, Name, Value FROM Registry")
        $view.Execute()
        
        $registryCount = 0
        while ($record = $view.Fetch()) {
            $registryCount++
            $regKey = $record.StringData(3)
            $regName = $record.StringData(4)
            $regValue = $record.StringData(5)
            
            # Look for cloud/AI related registry keys
            if ($regKey -match "DC\\|Preferences|Settings|Features" -and 
                ($regName -match "cloud|AI|services|sync|assistant|share|collab" -or
                 $regValue -match "cloud|AI|services|sync|assistant|share|collab")) {
                Write-Host "`nRegistry Entry:" -ForegroundColor Cyan
                Write-Host "  Key: $regKey" -ForegroundColor White
                Write-Host "  Name: $regName" -ForegroundColor White  
                Write-Host "  Value: $regValue" -ForegroundColor White
            }
        }
        
        Write-Host "`n✓ Total Registry Entries: $registryCount" -ForegroundColor Green
        
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($view) | Out-Null
    }
    catch {
        Write-Host "⚠️  Unable to read Registry table" -ForegroundColor Yellow
    }
    
}
catch {
    Write-Host "`n❌ Error reading MST/MSI: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
finally {
    if ($database) {
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($database) | Out-Null
    }
    if ($installer) {
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($installer) | Out-Null
    }
}

Write-Host "`n=== MST ANALYSIS COMPLETE ===" -ForegroundColor Cyan
Write-Host "`nNOTE: To verify cloud/AI features are disabled, check:" -ForegroundColor Yellow
Write-Host "  1. Registry: HKLM\SOFTWARE\Policies\Adobe\Adobe Acrobat\DC\FeatureLockDown" -ForegroundColor Gray
Write-Host "  2. Registry: HKLM\SOFTWARE\Adobe\Adobe Acrobat\DC\Preferences" -ForegroundColor Gray
Write-Host "  3. File: C:\Program Files\Adobe\Acrobat DC\Acrobat\Javascripts\*.js" -ForegroundColor Gray
Write-Host "  4. Post-install: Launch Acrobat and check Edit > Preferences > Services" -ForegroundColor Gray
