# Detection Script - Check if diagnostic report exists
# Return exit code 1 if diagnostic needs to run

$reportExists = Get-ChildItem "$env:PUBLIC\Documents" -Filter "Adobe-Diagnostic-*.txt" -ErrorAction SilentlyContinue | 
    Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-1) }

if ($reportExists) {
    Write-Host "Recent diagnostic found"
    Exit 0  # Already run recently
} else {
    Write-Host "No recent diagnostic"
    Exit 1  # Needs to run
}
