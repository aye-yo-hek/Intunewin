<#
.SYNOPSIS
    Installs Xerox Global Print Driver PCL6 and creates a printer with a TCP/IP port.

.DESCRIPTION
    This script stages the Xerox Global Print Driver PCL6 to the Windows Driver Store using pnputil,
    creates a Standard TCP/IP printer port, installs the printer driver, and adds the printer.
    Designed for deployment via Microsoft Intune as a Win32 app.

.PARAMETER PrinterIP
    The IP address of the network printer.

.PARAMETER PrinterName
    The display name for the printer as it will appear to users.

.PARAMETER InfPath
    The relative path to the driver INF file (e.g., ".\Driver\x3UNIVX.inf").

.PARAMETER DriverName
    The exact driver name as defined in the INF file.

.EXAMPLE
    powershell.exe -executionpolicy bypass -file Install-Printer.ps1 -PrinterIP "10.20.32.35" -PrinterName "XeroxVersaLink4036" -InfPath ".\Driver\x3UNIVX.inf" -DriverName "Xerox Global Print Driver PCL6"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$PrinterIP,

    [Parameter(Mandatory = $true)]
    [string]$PrinterName,

    [Parameter(Mandatory = $true)]
    [string]$InfPath,

    [Parameter(Mandatory = $true)]
    [string]$DriverName
)

# ── Logging ──────────────────────────────────────────────────────────────────
$LogFolder = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
$LogFile   = Join-Path $LogFolder "Install-Printer.log"

if (!(Test-Path $LogFolder)) { New-Item -ItemType Directory -Path $LogFolder -Force | Out-Null }

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp - $Message"
    Add-Content -Path $LogFile -Value $entry
    Write-Host $entry
}

# Clear previous log contents for a clean run
if (Test-Path $LogFile) { Clear-Content -Path $LogFile }

Write-Log "================================================================"
Write-Log "Starting Printer Installation"
Write-Log "Printer Name : $PrinterName"
Write-Log "Printer IP   : $PrinterIP"
Write-Log "INF Path     : $InfPath"
Write-Log "Driver Name  : $DriverName"
Write-Log "================================================================"

$PortName = "Port_$PrinterIP"
$ExitCode = 0

try {
    # ── Step 1: Stage printer driver to the Driver Store ─────────────────
    Write-Log "Step 1: Staging printer driver to the Driver Store..."

    $InfFullPath = Join-Path $PSScriptRoot $InfPath.TrimStart(".\")
    if (!(Test-Path $InfFullPath)) {
        Write-Log "ERROR: INF file not found at '$InfFullPath'"
        exit 1
    }

    # Use full path to pnputil.exe to avoid PATH issues in SYSTEM context
    $pnpUtilPath = "$env:SystemRoot\System32\pnputil.exe"
    if (!(Test-Path $pnpUtilPath)) {
        # Fallback for SysWOW64 redirection - force native System32
        $pnpUtilPath = "$env:SystemRoot\Sysnative\pnputil.exe"
    }
    Write-Log "Using pnputil at: $pnpUtilPath"

    $pnpResult = & $pnpUtilPath /add-driver "$InfFullPath" /install 2>&1
    $pnpExitCode = $LASTEXITCODE
    Write-Log "pnputil output: $($pnpResult -join ' | ')"

    if ($pnpExitCode -ne 0) {
        Write-Log "ERROR: pnputil failed with exit code $pnpExitCode"
        exit 1
    }
    Write-Log "Step 1 Complete: Driver staged successfully."

    # ── Step 2: Create Standard TCP/IP Printer Port ──────────────────────
    Write-Log "Step 2: Creating TCP/IP printer port '$PortName'..."

    $existingPort = Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue
    if ($existingPort) {
        Write-Log "Port '$PortName' already exists. Skipping port creation."
    }
    else {
        Add-PrinterPort -Name $PortName -PrinterHostAddress $PrinterIP -ErrorAction Stop
        Write-Log "Step 2 Complete: Port '$PortName' created successfully."
    }

    # ── Step 3: Install Printer Driver ───────────────────────────────────
    Write-Log "Step 3: Installing printer driver '$DriverName'..."

    $existingDriver = Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue
    if ($existingDriver) {
        Write-Log "Driver '$DriverName' already installed. Skipping driver installation."
    }
    else {
        Add-PrinterDriver -Name $DriverName -ErrorAction Stop
        Write-Log "Step 3 Complete: Driver '$DriverName' installed successfully."
    }

    # ── Step 4: Add Printer ──────────────────────────────────────────────
    Write-Log "Step 4: Adding printer '$PrinterName'..."

    $existingPrinter = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
    if ($existingPrinter) {
        Write-Log "Printer '$PrinterName' already exists. Removing and re-adding..."
        Remove-Printer -Name $PrinterName -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }

    Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName -ErrorAction Stop
    Write-Log "Step 4 Complete: Printer '$PrinterName' added successfully."

    Write-Log "================================================================"
    Write-Log "Printer installation completed successfully!"
    Write-Log "================================================================"
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    $ExitCode = 1
}

exit $ExitCode
