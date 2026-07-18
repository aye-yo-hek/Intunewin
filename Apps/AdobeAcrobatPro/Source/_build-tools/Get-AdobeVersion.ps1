# Get-AdobeVersion.ps1
# Extracts version information from Adobe Acrobat MSI file

param(
    [Parameter(Mandatory=$true)]
    [string]$MsiPath
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== Adobe MSI Version Extractor ===" -ForegroundColor Cyan

# Verify file exists
if (-not (Test-Path $MsiPath)) {
    Write-Host "ERROR: MSI file not found: $MsiPath" -ForegroundColor Red
    exit 1
}

$msiFile = Get-Item $MsiPath
Write-Host "Analyzing: $($msiFile.Name)" -ForegroundColor Yellow
Write-Host "Size: $([math]::Round($msiFile.Length/1MB, 2)) MB" -ForegroundColor Gray
Write-Host "Modified: $($msiFile.LastWriteTime)`n" -ForegroundColor Gray

try {
    # Create Windows Installer object
    $installer = New-Object -ComObject WindowsInstaller.Installer
    
    # Open database in read-only mode
    $msiFullPath = $msiFile.FullName
    $database = $installer.OpenDatabase($msiFullPath, 0)
    
    Write-Host "✓ Opened MSI database`n" -ForegroundColor Green
    
    # Properties to extract
    $properties = @(
        "ProductCode",
        "ProductVersion",
        "ProductName",
        "Manufacturer",
        "ProductLanguage",
        "UpgradeCode"
    )
    
    $versionInfo = @{}
    
    Write-Host "=== PRODUCT INFORMATION ===" -ForegroundColor Yellow
    
    foreach ($prop in $properties) {
        try {
            $query = "SELECT Value FROM Property WHERE Property='$prop'"
            $view = $database.OpenView($query)
            $view.Execute()
            $record = $view.Fetch()
            
            if ($record) {
                $value = $record.StringData(1)
                $versionInfo[$prop] = $value
                
                $color = switch ($prop) {
                    "ProductCode" { "Cyan" }
                    "ProductVersion" { "Green" }
                    "ProductName" { "White" }
                    default { "Gray" }
                }
                
                Write-Host "$prop : $value" -ForegroundColor $color
                
                [System.Runtime.Interopservices.Marshal]::ReleaseComObject($view) | Out-Null
            }
        }
        catch {
            Write-Host "$prop : Not found" -ForegroundColor Gray
        }
    }
    
    # Get install properties
    Write-Host "`n=== INSTALLATION PROPERTIES ===" -ForegroundColor Yellow
    
    $installProps = @(
        "EULA_ACCEPT",
        "ENABLE_OPTIMIZATION",
        "REMOVE_PREVIOUS",
        "DISABLE_DOCUMENT_CLOUD",
        "DISABLE_SERVICES",
        "DISABLE_ARM_SERVICE_UPLOADS"
    )
    
    foreach ($prop in $installProps) {
        try {
            $query = "SELECT Value FROM Property WHERE Property='$prop'"
            $view = $database.OpenView($query)
            $view.Execute()
            $record = $view.Fetch()
            
            if ($record) {
                $value = $record.StringData(1)
                $versionInfo[$prop] = $value
                Write-Host "  $prop = $value" -ForegroundColor Cyan
                [System.Runtime.Interopservices.Marshal]::ReleaseComObject($view) | Out-Null
            }
        }
        catch {
            # Property doesn't exist
        }
    }
    
    # Generate summary
    Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
    Write-Host "File: $($msiFile.Name)" -ForegroundColor White
    Write-Host "Product: $($versionInfo['ProductName'])" -ForegroundColor White
    Write-Host "Version: $($versionInfo['ProductVersion'])" -ForegroundColor Green
    Write-Host "Product Code: $($versionInfo['ProductCode'])" -ForegroundColor Cyan
    Write-Host "Manufacturer: $($versionInfo['Manufacturer'])" -ForegroundColor Gray
    
    # Generate uninstall command
    Write-Host "`n=== UNINSTALL COMMAND ===" -ForegroundColor Yellow
    Write-Host "msiexec /x $($versionInfo['ProductCode']) /qn /norestart" -ForegroundColor White
    
    # Generate detection script snippet
    Write-Host "`n=== DETECTION SCRIPT SNIPPET ===" -ForegroundColor Yellow
    Write-Host @"
`$productCode = "$($versionInfo['ProductCode'])"
`$expectedVersion = "$($versionInfo['ProductVersion'])"

`$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\`$productCode",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\`$productCode"
)

foreach (`$path in `$regPaths) {
    if (Test-Path `$path) {
        `$props = Get-ItemProperty `$path
        if (`$props.DisplayVersion -ge `$expectedVersion) {
            Write-Host "Detected: `$(`$props.DisplayName) v`$(`$props.DisplayVersion)"
            exit 0
        }
    }
}

exit 1
"@ -ForegroundColor Gray
    
    # Generate VERSION.txt content
    Write-Host "`n=== VERSION.txt CONTENT ===" -ForegroundColor Yellow
    $versionContent = @"
$($versionInfo['ProductName'])
Version: $($versionInfo['ProductVersion'])
Product Code: $($versionInfo['ProductCode'])
Upgrade Code: $($versionInfo['UpgradeCode'])
Manufacturer: $($versionInfo['Manufacturer'])
Extracted Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
MSI File: $($msiFile.Name)
MSI Size: $([math]::Round($msiFile.Length/1MB, 2)) MB
"@
    
    Write-Host $versionContent -ForegroundColor Gray
    
    # Save to file
    $versionFile = Join-Path $msiFile.DirectoryName "VERSION.txt"
    $versionContent | Out-File $versionFile -Encoding UTF8
    Write-Host "`n✓ Saved to: $versionFile" -ForegroundColor Green
    
    # Return object for scripting
    Write-Host "`n=== POWERSHELL OBJECT ===" -ForegroundColor Cyan
    $resultObject = [PSCustomObject]@{
        FileName = $msiFile.Name
        FilePath = $msiFile.FullName
        FileSize = $msiFile.Length
        ProductName = $versionInfo['ProductName']
        ProductVersion = $versionInfo['ProductVersion']
        ProductCode = $versionInfo['ProductCode']
        UpgradeCode = $versionInfo['UpgradeCode']
        Manufacturer = $versionInfo['Manufacturer']
        Language = $versionInfo['ProductLanguage']
    }
    
    $resultObject | Format-List
    
    return $resultObject
    
}
catch {
    Write-Host "`nERROR: Failed to read MSI file" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
finally {
    # Cleanup COM objects
    if ($database) {
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($database) | Out-Null
    }
    if ($installer) {
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($installer) | Out-Null
    }
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}
