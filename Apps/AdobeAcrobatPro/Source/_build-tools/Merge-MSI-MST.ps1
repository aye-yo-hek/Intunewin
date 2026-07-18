#Requires -Version 5.1
<#
.SYNOPSIS
    Merges an MSI file with an MST transform file into a single MSI

.DESCRIPTION
    This script uses the Windows Installer COM API to apply an MST transform
    to an MSI file and save it as a new merged MSI file.

.PARAMETER MsiPath
    Path to the original MSI file

.PARAMETER MstPath
    Path to the MST transform file

.PARAMETER OutputPath
    Path where the merged MSI will be saved

.EXAMPLE
    .\Merge-MSI-MST.ps1 -MsiPath ".\YourApp.msi" -MstPath ".\YourApp.mst" -OutputPath ".\YourApp-Merged.msi"

.NOTES
    Requires: Windows Installer COM API
    Author: IT Admin
    Date: 2025-11-24
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$MsiPath,
    
    [Parameter(Mandatory=$true)]
    [string]$MstPath,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "MSI + MST Merger" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Resolve full paths
$MsiPath = Resolve-Path $MsiPath -ErrorAction Stop
$MstPath = Resolve-Path $MstPath -ErrorAction Stop
$OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)

Write-Host "Source MSI: $MsiPath" -ForegroundColor Gray
Write-Host "Transform:  $MstPath" -ForegroundColor Gray
Write-Host "Output MSI: $OutputPath" -ForegroundColor Gray
Write-Host ""

try {
    # Step 1: Copy original MSI to output location
    Write-Host "Step 1: Copying MSI file..." -ForegroundColor Yellow
    Copy-Item -Path $MsiPath -Destination $OutputPath -Force
    Write-Host "✓ MSI copied" -ForegroundColor Green
    
    # Step 2: Open MSI database
    Write-Host ""
    Write-Host "Step 2: Opening MSI database..." -ForegroundColor Yellow
    
    $installer = New-Object -ComObject WindowsInstaller.Installer
    $database = $installer.GetType().InvokeMember(
        "OpenDatabase",
        [System.Reflection.BindingFlags]::InvokeMethod,
        $null,
        $installer,
        @($OutputPath, 1)  # 1 = msiOpenDatabaseModeTransact (read/write)
    )
    
    Write-Host "✓ Database opened" -ForegroundColor Green
    
    # Step 3: Apply transform
    Write-Host ""
    Write-Host "Step 3: Applying transform..." -ForegroundColor Yellow
    
    $database.GetType().InvokeMember(
        "ApplyTransform",
        [System.Reflection.BindingFlags]::InvokeMethod,
        $null,
        $database,
        @($MstPath, 0)
    )
    
    Write-Host "✓ Transform applied" -ForegroundColor Green
    
    # Step 4: Commit changes
    Write-Host ""
    Write-Host "Step 4: Committing changes..." -ForegroundColor Yellow
    
    $database.GetType().InvokeMember(
        "Commit",
        [System.Reflection.BindingFlags]::InvokeMethod,
        $null,
        $database,
        $null
    )
    
    Write-Host "✓ Changes committed" -ForegroundColor Green
    
    # Step 5: Cleanup
    Write-Host ""
    Write-Host "Step 5: Cleaning up..." -ForegroundColor Yellow
    
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($database) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($installer) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    Write-Host "✓ Cleanup complete" -ForegroundColor Green
    
    # Success
    Write-Host ""
    Write-Host "==================================" -ForegroundColor Green
    Write-Host "✓ MSI Merge Complete!" -ForegroundColor Green
    Write-Host "==================================" -ForegroundColor Green
    Write-Host ""
    
    if (Test-Path $OutputPath) {
        $fileInfo = Get-Item $OutputPath
        Write-Host "Output File: $OutputPath" -ForegroundColor Cyan
        Write-Host "File Size:   $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor Gray
        Write-Host "Modified:    $($fileInfo.LastWriteTime)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Next Steps:" -ForegroundColor Cyan
        Write-Host "1. Test the merged MSI: msiexec /i `"$OutputPath`" /l*v test.log" -ForegroundColor White
        Write-Host "2. Deploy via Intune as Line-of-Business app or Win32 app" -ForegroundColor White
    }
    
    exit 0
}
catch {
    Write-Host ""
    Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "- Ensure MSI is not open in another program" -ForegroundColor White
    Write-Host "- Check MSI and MST file paths are correct" -ForegroundColor White
    Write-Host "- Verify MST is compatible with this MSI version" -ForegroundColor White
    Write-Host "- Try using Orca or InstEd as an alternative" -ForegroundColor White
    
    exit 1
}
