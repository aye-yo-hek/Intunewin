# Fix Performance Counter DLL Errors
# Repairs missing bitsperf.dll and sysmain.dll performance counters

Write-Host "Fixing Performance Counter DLL Issues..." -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Gray

# Run as Administrator check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    exit 1
}

# Rebuild performance counters
Write-Host "[1/3] Rebuilding performance counter registry..." -ForegroundColor Yellow
try {
    cd $env:SystemRoot\System32
    lodctr /R
    cd $env:SystemRoot\SysWOW64
    lodctr /R
    Write-Host "  [OK] Performance counters rebuilt`n" -ForegroundColor Green
} catch {
    Write-Host "  [WARNING] Could not rebuild counters: $_`n" -ForegroundColor Yellow
}

# Reset BITS performance counter
Write-Host "[2/3] Resetting BITS performance counter..." -ForegroundColor Yellow
try {
    unlodctr BITS
    lodctr "$env:SystemRoot\System32\bitsperf.ini"
    Write-Host "  [OK] BITS counter reset`n" -ForegroundColor Green
} catch {
    Write-Host "  [WARNING] BITS counter reset failed: $_`n" -ForegroundColor Yellow
}

# Reset SysMain performance counter
Write-Host "[3/3] Resetting SysMain performance counter..." -ForegroundColor Yellow
try {
    unlodctr SysMain
    lodctr "$env:SystemRoot\System32\sysmainperf.ini"
    Write-Host "  [OK] SysMain counter reset`n" -ForegroundColor Green
} catch {
    Write-Host "  [WARNING] SysMain counter reset failed: $_`n" -ForegroundColor Yellow
}

Write-Host "`nPerformance counter repair complete." -ForegroundColor Green
Write-Host "These errors won't affect Adobe Reader installation.`n" -ForegroundColor White
