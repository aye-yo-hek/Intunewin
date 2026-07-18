# Local Testing Guide for Win32 Apps
## Test Before Deploying to Intune

### 🧪 **Local Testing Strategy**

Testing locally helps verify:
- Install scripts work correctly
- Detection scripts accurately identify installations
- Uninstall scripts clean up properly
- No errors occur during the process

---

## **Test 1: AXCodeSetup Local Testing**

### **Step 1: Test Installation**
```powershell
# Navigate to AXCodeSetup folder
cd "C:\IntuneWin\src\AXCodeSetup"

# Run install script (as Administrator)
.\install.cmd

# Check if installation succeeded
if (Test-Path "$env:LOCALAPPDATA\Programs\AX Code\AX Code.exe") {
    Write-Host "✅ AXCodeSetup installed successfully" -ForegroundColor Green
} else {
    Write-Host "❌ AXCodeSetup installation failed" -ForegroundColor Red
}
```

### **Step 2: Test Detection**
```powershell
# Run detection script
.\detect.ps1
$exitCode = $LASTEXITCODE

if ($exitCode -eq 0) {
    Write-Host "✅ Detection script correctly identifies installation" -ForegroundColor Green
} else {
    Write-Host "❌ Detection script failed (Exit code: $exitCode)" -ForegroundColor Red
}
```

### **Step 3: Test Uninstallation**
```powershell
# Run uninstall script
.\uninstall.cmd

# Verify removal
if (!(Test-Path "$env:LOCALAPPDATA\Programs\AX Code\AX Code.exe")) {
    Write-Host "✅ AXCodeSetup uninstalled successfully" -ForegroundColor Green
} else {
    Write-Host "❌ AXCodeSetup uninstall failed" -ForegroundColor Red
}

# Test detection after uninstall
.\detect.ps1
$exitCode = $LASTEXITCODE

if ($exitCode -eq 1) {
    Write-Host "✅ Detection correctly identifies removal" -ForegroundColor Green
} else {
    Write-Host "❌ Detection still shows installed after removal" -ForegroundColor Red
}
```

---

## **Test 2: Python314 Local Testing**

### **Step 1: Test Installation**
```powershell
# Navigate to Python314 folder  
cd "C:\IntuneWin\src\Python314"

# Run install script (as Administrator)
.\install.cmd

# Check if installation succeeded
if (Test-Path "$env:ProgramFiles\Python314\python.exe") {
    Write-Host "✅ Python314 installed successfully" -ForegroundColor Green
    
    # Test if Python is in PATH
    try {
        $version = python --version 2>&1
        Write-Host "✅ Python version: $version" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Python installed but not in PATH" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Python314 installation failed" -ForegroundColor Red
}
```

### **Step 2: Test Detection**
```powershell
# Run detection script
.\detect.ps1
$exitCode = $LASTEXITCODE

if ($exitCode -eq 0) {
    Write-Host "✅ Detection script correctly identifies installation" -ForegroundColor Green
} else {
    Write-Host "❌ Detection script failed (Exit code: $exitCode)" -ForegroundColor Red
}
```

### **Step 3: Test Uninstallation**
```powershell
# Run uninstall script
.\uninstall.cmd

# Verify removal
if (!(Test-Path "$env:ProgramFiles\Python314\python.exe")) {
    Write-Host "✅ Python314 uninstalled successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Python314 uninstall failed" -ForegroundColor Red
}

# Test detection after uninstall
.\detect.ps1
$exitCode = $LASTEXITCODE

if ($exitCode -eq 1) {
    Write-Host "✅ Detection correctly identifies removal" -ForegroundColor Green
} else {
    Write-Host "❌ Detection still shows installed after removal" -ForegroundColor Red
}
```

---

## **Test 3: Manual Installer Testing**

### **Test AXCodeSetup Silent Parameters**
```powershell
# Test the exact command from install.cmd
cd "C:\IntuneWin\src\AXCodeSetup"

# Run with logging to see what happens
.\axcodesetup.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /LOG="C:\temp\axcode_install.log"

# Wait for completion and check log
Start-Sleep 30
if (Test-Path "C:\temp\axcode_install.log") {
    Write-Host "Installation log created. Checking for errors..."
    $log = Get-Content "C:\temp\axcode_install.log" -Raw
    if ($log -match "error|failed|exception") {
        Write-Host "❌ Errors found in installation log" -ForegroundColor Red
        Get-Content "C:\temp\axcode_install.log" | Select-String "error|failed|exception"
    } else {
        Write-Host "✅ No errors found in installation log" -ForegroundColor Green
    }
}
```

### **Test Python Silent Parameters**
```powershell
# Test the exact command from install.cmd
cd "C:\IntuneWin\src\Python314"

# Run with logging
.\python-3.14.0-amd64.exe /quiet InstallAllUsers=1 PrependPath=1 /log "C:\temp\python_install.log"

# Check installation result
Start-Sleep 30
if (Test-Path "$env:ProgramFiles\Python314\python.exe") {
    Write-Host "✅ Python installed successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Python installation failed" -ForegroundColor Red
    if (Test-Path "C:\temp\python_install.log") {
        Write-Host "Check log for details:"
        Get-Content "C:\temp\python_install.log" | Select-String "error|failed|exception"
    }
}
```

---

## **Test 4: Simulate Intune Behavior**

### **Run as SYSTEM Context (Mimics Intune)**
```powershell
# Create a test script that runs as SYSTEM
$testScript = @'
# Test AXCodeSetup as SYSTEM
cd "C:\IntuneWin\src\AXCodeSetup"
Start-Process cmd -ArgumentList "/c install.cmd" -Wait
$installed = Test-Path "$env:LOCALAPPDATA\Programs\AX Code\AX Code.exe"
Add-Content "C:\temp\system_test.log" "AXCodeSetup installed: $installed"

# Test detection as SYSTEM
$detectResult = & powershell -File "detect.ps1"
Add-Content "C:\temp\system_test.log" "AXCodeSetup detection: $LASTEXITCODE"
'@

# Save and run via Task Scheduler (runs as SYSTEM)
$testScript | Out-File "C:\temp\system_test.ps1"
schtasks /create /tn "IntuneTest" /tr "powershell -File C:\temp\system_test.ps1" /sc once /st 23:59 /ru SYSTEM /f
schtasks /run /tn "IntuneTest"
Start-Sleep 60
schtasks /delete /tn "IntuneTest" /f

# Check results
if (Test-Path "C:\temp\system_test.log") {
    Write-Host "SYSTEM context test results:"
    Get-Content "C:\temp\system_test.log"
}
```

---

## **Test 5: Package Integrity Testing**

### **Verify .intunewin Packages**
```powershell
# Check package files exist and have reasonable sizes
$packages = @(
    @{Name="AXCodeSetup.intunewin"; MinSizeMB=140; MaxSizeMB=150},
    @{Name="Python314-v2.intunewin"; MinSizeMB=25; MaxSizeMB=35}
)

foreach ($pkg in $packages) {
    $file = "C:\IntuneWin\packages\$($pkg.Name)"
    if (Test-Path $file) {
        $sizeMB = [math]::Round((Get-Item $file).Length / 1MB, 2)
        if ($sizeMB -ge $pkg.MinSizeMB -and $sizeMB -le $pkg.MaxSizeMB) {
            Write-Host "✅ $($pkg.Name): $sizeMB MB (size looks correct)" -ForegroundColor Green
        } else {
            Write-Host "⚠️ $($pkg.Name): $sizeMB MB (size seems unusual)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ $($pkg.Name): Package file not found" -ForegroundColor Red
    }
}
```

---

## **Test 6: Error Simulation**

### **Test Error Handling**
```powershell
# Test what happens when installer file is missing
cd "C:\IntuneWin\src\AXCodeSetup"
Rename-Item "axcodesetup.exe" "axcodesetup.exe.backup"

# Try to run install script
.\install.cmd
$errorLevel = $LASTEXITCODE

# Restore file
Rename-Item "axcodesetup.exe.backup" "axcodesetup.exe"

if ($errorLevel -ne 0) {
    Write-Host "✅ Install script properly handles missing files (Exit code: $errorLevel)" -ForegroundColor Green
} else {
    Write-Host "❌ Install script should fail when installer is missing" -ForegroundColor Red
}
```

---

## **Quick Test All Script**

Would you like me to create a comprehensive test script that runs all these tests automatically?