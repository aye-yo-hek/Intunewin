# ADOBE ACROBAT DC - PROPER MSI EXTRACTION GUIDE
# Resolves Error 1311 - CAB file not found

## THE PROBLEM
Error 1311 means the MSI file is looking for external CAB files that aren't included.
This happens when:
1. MSI was extracted incorrectly from Adobe's EXE installer
2. CAB files were separated from the MSI
3. MSI was moved without its companion CAB files

## SOLUTION: Properly Extract Adobe Installer

### METHOD 1: Extract from Adobe EXE Installer (RECOMMENDED)

1. **Download Adobe Acrobat DC installer** from Adobe Admin Console:
   - Go to: https://adminconsole.adobe.com
   - Navigate to: Packages > Create Package
   - Select: Acrobat DC Pro
   - Download the EXE installer

2. **Extract ALL files from the EXE**:
   ```powershell
   # Create extraction directory
   New-Item -ItemType Directory -Force -Path "C:\Temp\AdobeExtract"
   
   # Extract using 7-Zip (if installed)
   & "C:\Program Files\7-Zip\7z.exe" x "AcrobatDCx64.exe" -o"C:\Temp\AdobeExtract"
   
   # OR run the EXE with extract switches
   .\AcrobatDCx64.exe /sAll /msi EULA_ACCEPT=YES /extract:"C:\Temp\AdobeExtract"
   ```

3. **Look for these files in the extracted folder**:
   - `AcroPro.msi` (main installer)
   - `*.cab` files (multiple CAB files containing installation files)
   - `setup.ini` (configuration file)
   
4. **Copy ALL files to your source folder**:
   ```powershell
   Copy-Item "C:\Temp\AdobeExtract\*" -Destination ".\source\" -Force
   ```

### METHOD 2: Use Adobe Customization Wizard

1. Download Adobe Customization Wizard DC from Adobe
2. Open your MSI with the wizard
3. Make customizations (if any)
4. Save - this will ensure all CAB files are properly referenced

### METHOD 3: Download Complete Package from Adobe

1. Go to Adobe Admin Console: https://adminconsole.adobe.com
2. Create a new package with all customizations
3. Download the complete package (includes MSI + all CAB files)
4. Extract the downloaded package
5. Copy all files (MSI + CAB files) to your source folder

## VERIFICATION

After obtaining the proper files, verify you have:
```powershell
Get-ChildItem .\source\ -Filter "*.cab"
```

You should see multiple CAB files like:
- Core.cab
- Data1.cab
- Data2.cab (etc.)

## WHAT NOT TO DO

❌ Don't use just the MSI file alone
❌ Don't merge MSI and MST (breaks CAB references)
❌ Don't copy MSI without its companion CAB files

## WHAT TO DO

✅ Keep MSI and all CAB files together
✅ Use TRANSFORMS parameter to apply MST
✅ Package everything together for Intune

## NEXT STEPS

1. Get the complete Adobe package (MSI + CAB files)
2. Place all files in the `source` folder
3. Recreate the Intune package with:
   ```powershell
   C:\IntuneTools\IntuneWinAppUtil.exe -c ".\source" -s "install-enhanced.cmd" -o ".\intune-packages"
   ```

## ALTERNATIVE: Use Adobe's Pre-packaged Installer

If this is too complex, consider using Adobe's EXE installer directly:
1. Download the EXE from Adobe Admin Console
2. Create a simple CMD script that runs the EXE with silent switches
3. Package the EXE + CMD script with IntuneWinAppUtil

Example install command:
```cmd
AcrobatDCx64.exe /sAll /msi EULA_ACCEPT=YES /qn
```

This avoids the MSI/CAB complexity entirely.
