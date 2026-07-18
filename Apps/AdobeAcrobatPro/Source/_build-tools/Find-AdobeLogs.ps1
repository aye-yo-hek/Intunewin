# Find Adobe Installation Logs
# Run on the target machine where installation failed

Write-Host "`n🔍 SEARCHING FOR ADOBE INSTALLATION LOGS" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

$logLocations = @(
    "$env:TEMP\Acrobat.msi.install.log",
    "$env:TEMP\Acrobat.msi.install.log.patch",
    "C:\Windows\Temp\Acrobat.msi.install.log",
    "C:\Windows\Temp\Acrobat.msi.install.log.patch",
    "$env:SystemRoot\Temp\Acrobat.msi.install.log"
)

Write-Host "Checking these locations:" -ForegroundColor Yellow
$logLocations | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
Write-Host ""

$foundLogs = @()

foreach ($log in $logLocations) {
    if (Test-Path $log) {
        $foundLogs += $log
        $fileInfo = Get-Item $log
        Write-Host "✓ FOUND: $log" -ForegroundColor Green
        Write-Host "  Size: $([math]::Round($fileInfo.Length/1KB, 2)) KB" -ForegroundColor Cyan
        Write-Host "  Modified: $($fileInfo.LastWriteTime)" -ForegroundColor Cyan
        Write-Host ""
    }
}

if ($foundLogs.Count -eq 0) {
    Write-Host "❌ NO LOGS FOUND in standard locations" -ForegroundColor Red
    Write-Host "`nSearching entire TEMP folders..." -ForegroundColor Yellow
    
    $searchResults = Get-ChildItem -Path $env:TEMP, "C:\Windows\Temp" -Filter "*Acrobat*.log" -ErrorAction SilentlyContinue
    
    if ($searchResults) {
        Write-Host "`n✓ Found logs in non-standard locations:" -ForegroundColor Green
        $searchResults | ForEach-Object {
            Write-Host "  - $($_.FullName)" -ForegroundColor Cyan
            $foundLogs += $_.FullName
        }
    } else {
        Write-Host "`n❌ No Adobe logs found anywhere" -ForegroundColor Red
        Write-Host "`nThis means:" -ForegroundColor Yellow
        Write-Host "  1. Installation never started (Intune didn't run the script)" -ForegroundColor White
        Write-Host "  2. Installation ran but didn't create logs" -ForegroundColor White
        Write-Host "  3. Logs were cleaned up" -ForegroundColor White
        Write-Host "`nCheck Intune Management Extension log instead:" -ForegroundColor Yellow
        Write-Host "  C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`n" -ForegroundColor Cyan
        pause
        exit
    }
}

# Analyze the most recent log
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "📋 ANALYZING MOST RECENT LOG" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

$latestLog = $foundLogs | Get-Item | Sort-Object LastWriteTime -Descending | Select-Object -First 1

Write-Host "Log file: $($latestLog.FullName)" -ForegroundColor Yellow
Write-Host "Size: $([math]::Round($latestLog.Length/1KB, 2)) KB" -ForegroundColor Yellow
Write-Host "Modified: $($latestLog.LastWriteTime)`n" -ForegroundColor Yellow

# Search for specific errors
Write-Host "[1] Searching for CAB file errors (Error 1311)..." -ForegroundColor Cyan
$cabErrors = Select-String -Path $latestLog.FullName -Pattern "1311|cab" -Context 2,2 | Select-Object -Last 10
if ($cabErrors) {
    Write-Host "  ⚠️ CAB file errors found:" -ForegroundColor Red
    $cabErrors | ForEach-Object { Write-Host "    $($_.Line)" -ForegroundColor Gray }
    Write-Host ""
} else {
    Write-Host "  ✓ No CAB file errors`n" -ForegroundColor Green
}

Write-Host "[2] Searching for return value 3 (failure)..." -ForegroundColor Cyan
$returnErrors = Select-String -Path $latestLog.FullName -Pattern "return value 3" -Context 2,2 | Select-Object -Last 5
if ($returnErrors) {
    Write-Host "  ⚠️ Installation failures found:" -ForegroundColor Red
    $returnErrors | ForEach-Object { 
        Write-Host "    $($_.Line)" -ForegroundColor Gray
        Write-Host "      Context:" -ForegroundColor Yellow
        $_.Context.PreContext | ForEach-Object { Write-Host "        $_" -ForegroundColor DarkGray }
    }
    Write-Host ""
} else {
    Write-Host "  ✓ No return value 3 errors`n" -ForegroundColor Green
}

Write-Host "[3] Searching for general errors..." -ForegroundColor Cyan
$generalErrors = Select-String -Path $latestLog.FullName -Pattern "error|failed" -Context 1,1 | Select-Object -Last 15
if ($generalErrors) {
    Write-Host "  ⚠️ Errors found:" -ForegroundColor Red
    $generalErrors | ForEach-Object { Write-Host "    $($_.Line)" -ForegroundColor Gray }
    Write-Host ""
} else {
    Write-Host "  ✓ No general errors`n" -ForegroundColor Green
}

Write-Host "[4] Checking installation exit code..." -ForegroundColor Cyan
$exitCode = Select-String -Path $latestLog.FullName -Pattern "MainEngineThread is returning (\d+)" | Select-Object -Last 1
if ($exitCode -match "returning (\d+)") {
    $code = $matches[1]
    Write-Host "  Exit code: $code" -ForegroundColor Yellow
    
    switch ($code) {
        "0" { Write-Host "  ✓ Success" -ForegroundColor Green }
        "3010" { Write-Host "  ✓ Success (restart required)" -ForegroundColor Green }
        "1603" { Write-Host "  ❌ Fatal error during installation" -ForegroundColor Red }
        "1619" { Write-Host "  ❌ Installation package could not be opened" -ForegroundColor Red }
        "1633" { Write-Host "  ❌ Platform not supported" -ForegroundColor Red }
        default { Write-Host "  ⚠️ Unknown exit code" -ForegroundColor Yellow }
    }
    Write-Host ""
}

# Show last 30 lines
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "📄 LAST 30 LINES OF LOG" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Gray

Get-Content $latestLog.FullName -Tail 30 | ForEach-Object { Write-Host $_ -ForegroundColor Gray }

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host "`n💡 To open full log file:" -ForegroundColor Yellow
Write-Host "   notepad `"$($latestLog.FullName)`"`n" -ForegroundColor Cyan

pause
