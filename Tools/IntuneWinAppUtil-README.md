# Microsoft Win32 Content Prep Tool

This folder contains tools and configurations for packaging Win32 applications for Intune deployment.

## Required Tool

Download the Microsoft Win32 Content Prep Tool from:
https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool

Place the `IntuneWinAppUtil.exe` file in this directory.

## Usage

1. Build your application using the build script
2. Use the Create-IntuneWinPackage.ps1 script to create .intunewin packages
3. Upload the .intunewin package to Microsoft Intune admin center

## Command Line Usage

```cmd
IntuneWinAppUtil.exe -c <source_folder> -s <setup_file> -o <output_folder>
```

### Parameters:
- `-c` : Source folder containing the application files
- `-s` : Setup file (installer executable)
- `-o` : Output folder for the .intunewin package
- `-q` : Quiet mode (suppress output)

## Example

```powershell
.\IntuneWinAppUtil.exe -c ".\output" -s "install.cmd" -o ".\packages"
```

This will create a .intunewin package from the files in the output folder using install.cmd as the setup file.