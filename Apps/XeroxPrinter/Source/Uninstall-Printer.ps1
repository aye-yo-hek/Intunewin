<#
.SYNOPSIS
    Uninstalls a printer and optionally its port deployed via Intune.

.DESCRIPTION
    Removes the specified printer and its associated TCP/IP port from the device.
    Does NOT remove the printer driver from the Driver Store.

.PARAMETER PrinterName
    The display name of the printer to remove.

.PARAMETER PrinterIP
    The IP address used to create the printer port. If provided, the port will also be removed.

.EXAMPLE
    powershell.exe -executionpolicy bypass -file Uninstall-Printer.ps1 -PrinterName "XeroxVersaLink4036" -PrinterIP "10.20.32.35"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$PrinterName,

    [Parameter(Mandatory = $false)]
    [string]$PrinterIP
)

# ── Logging ──────────────────────────────────────────────────────────────────
$LogFolder = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
$LogFile   = Join-Path $LogFolder "Uninstall-Printer.log"

if (!(Test-Path $LogFolder)) { New-Item -ItemType Directory -Path $LogFolder -Force | Out-Null }

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp - $Message"
    Add-Content -Path $LogFile -Value $entry
    Write-Host $entry
}

if (Test-Path $LogFile) { Clear-Content -Path $LogFile }

Write-Log "================================================================"
Write-Log "Starting Printer Uninstallation"
Write-Log "Printer Name : $PrinterName"
if ($PrinterIP) { Write-Log "Printer IP   : $PrinterIP" }
Write-Log "================================================================"

$ExitCode = 0

try {
    # ── Step 1: Remove Printer ───────────────────────────────────────────
    Write-Log "Step 1: Removing printer '$PrinterName'..."

    $existingPrinter = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
    if ($existingPrinter) {
        Remove-Printer -Name $PrinterName -ErrorAction Stop
        Write-Log "Printer '$PrinterName' removed successfully."
    }
    else {
        Write-Log "Printer '$PrinterName' not found. Nothing to remove."
    }

    # ── Step 2: Remove Printer Port (if IP provided) ────────────────────
    if ($PrinterIP) {
        $PortName = "Port_$PrinterIP"
        Write-Log "Step 2: Removing printer port '$PortName'..."

        Start-Sleep -Seconds 3  # Allow time for printer removal to complete

        $existingPort = Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue
        if ($existingPort) {
            try {
                Remove-PrinterPort -Name $PortName -ErrorAction Stop
                Write-Log "Port '$PortName' removed successfully."
            }
            catch {
                Write-Log "WARNING: Could not remove port '$PortName': $($_.Exception.Message)"
            }
        }
        else {
            Write-Log "Port '$PortName' not found. Nothing to remove."
        }
    }

    Write-Log "================================================================"
    Write-Log "Printer uninstallation completed successfully!"
    Write-Log "================================================================"
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    $ExitCode = 1
}

exit $ExitCode
