# Extract CAB files from Adobe Acrobat MSI
# This resolves Error 1311 when deploying via Intune

Write-Host "`n=== EXTRACTING CAB FILES FROM MSI ===" -ForegroundColor Yellow
Write-Host "This will extract embedded CAB files so they can be deployed alongside the MSI`n" -ForegroundColor Cyan

$msiPath = ".\source\AcroPro.msi"
$outputDir = ".\source"

if (-not (Test-Path $msiPath)) {
    Write-Host "ERROR: MSI file not found: $msiPath" -ForegroundColor Red
    exit 1
}

try {
    Write-Host "Opening MSI database..." -ForegroundColor Cyan
    $windowsInstaller = New-Object -ComObject WindowsInstaller.Installer
    $database = $windowsInstaller.OpenDatabase($msiPath, 0)
    
    Write-Host "Searching for embedded CAB files..." -ForegroundColor Cyan
    $view = $database.OpenView("SELECT Name, Data FROM _Streams WHERE Name LIKE '%.cab'")
    $view.Execute()
    
    $cabCount = 0
    while ($true) {
        $record = $view.Fetch()
        if ($record -eq $null) { break }
        
        $cabName = $record.StringData(1)
        $cabPath = Join-Path $outputDir $cabName
        
        Write-Host "  Extracting: $cabName..." -ForegroundColor Yellow
        
        # Get the binary data
        $dataSize = $record.DataSize(2)
        $stream = $record.ReadStream(2, $dataSize, 1)
        
        # Write to file
        $bytes = @()
        for ($i = 0; $i -lt $dataSize; $i++) {
            $bytes += $stream[$i]
        }
        [System.IO.File]::WriteAllBytes($cabPath, $bytes)
        
        Write-Host "    [✓] Saved to: $cabPath" -ForegroundColor Green
        Write-Host "    [✓] Size: $([math]::Round($dataSize/1MB, 2)) MB`n" -ForegroundColor Green
        $cabCount++
    }
    
    # Cleanup COM objects
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($view) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($database) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($windowsInstaller) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    if ($cabCount -eq 0) {
        Write-Host "No embedded CAB files found in MSI." -ForegroundColor Yellow
        Write-Host "The MSI might be using external CAB files already.`n" -ForegroundColor Yellow
        
        # Check for existing CAB files
        $existingCabs = Get-ChildItem $outputDir -Filter "*.cab" -ErrorAction SilentlyContinue
        if ($existingCabs) {
            Write-Host "Found existing CAB files:" -ForegroundColor Green
            $existingCabs | ForEach-Object {
                Write-Host "  [✓] $($_.Name) - $([math]::Round($_.Length/1MB, 2)) MB" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "`n=== EXTRACTION COMPLETE ===" -ForegroundColor Green
        Write-Host "Extracted $cabCount CAB file(s)" -ForegroundColor Green
        Write-Host "CAB files are now in: $outputDir`n" -ForegroundColor Green
    }
    
} catch {
    Write-Host "`nERROR: Failed to extract CAB files" -ForegroundColor Red
    Write-Host "Details: $_" -ForegroundColor Red
    Write-Host "`nTrying alternative method (lessmsi tool)...`n" -ForegroundColor Yellow
    
    # Check if lessmsi is available
    if (Get-Command lessmsi -ErrorAction SilentlyContinue) {
        Write-Host "Using lessmsi to extract MSI contents..." -ForegroundColor Cyan
        lessmsi x $msiPath "$outputDir\extracted\"
        Write-Host "Check the extracted folder for CAB files`n" -ForegroundColor Green
    } else {
        Write-Host "Alternative: Install lessmsi tool:" -ForegroundColor Yellow
        Write-Host "  winget install LessMsi" -ForegroundColor Cyan
        Write-Host "  Then run this script again`n" -ForegroundColor Cyan
    }
}

Write-Host "Next step: Recreate the Intune package with CAB files included`n" -ForegroundColor Yellow
