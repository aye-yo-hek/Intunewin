# Detection for .NET SDK 8.0.423 (win-x64)
# The SDK installer lays down its files under a version-named folder - presence
# of that folder (with dotnet.dll inside it) is Microsoft's own recommended
# detection signal for this installer.
$sdkVersionFolder = "C:\Program Files\dotnet\sdk\8.0.423"

if (Test-Path (Join-Path $sdkVersionFolder "dotnet.dll")) {
    Write-Host "dotnet SDK 8.0.423 detected"
    exit 0
} else {
    Write-Host "dotnet SDK 8.0.423 not found"
    exit 1
}
