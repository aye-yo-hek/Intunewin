# WiX Toolset - MSI Builder

Build Windows Installer (.msi) packages using WiX Toolset **v4** (the CLI installed
on this machine, confirmed working: `wix` v4.0.3, installed as a `dotnet` global
tool at `%USERPROFILE%\.dotnet\tools\wix.exe`). This is a newer, single-binary CLI
than the classic `candle.exe`/`light.exe` v3 workflow you may see in older guides.

## Two templates, two use cases

- **`ConfigTemplate.wxs`** - registry keys / policy settings / config "templates"
  only, no files installed. This is the one to use for "edit this registry key
  / apply this setting via Intune" requests.
- **`Product.wxs`** - a full app install (files + Start Menu shortcuts +
  registry), for when there's an actual EXE/DLL payload to lay down.

Both are verified to compile as-is with the installed `wix` CLI.

## Quick Start (registry/settings-only MSI)

1. Copy `ConfigTemplate.wxs` to a new file (e.g. into the target app's
   `Apps\<AppName>\Source\` folder, so the source stays with the app like
   everything else in this workspace).
2. Generate a real GUID and drop it in for `UpgradeCode`:
   ```powershell
   [guid]::NewGuid()
   ```
3. Edit the `RegistryKey`/`RegistryValue` block(s) to the actual keys/values
   requested - add more `<RegistryValue>` lines under one `RegistryKey`, or
   duplicate the whole `<RegistryKey>` block for a different registry path.
4. Build:
   ```powershell
   wix build Apps\<AppName>\Source\<Name>.wxs -o Apps\<AppName>\Source\<Name>.msi
   ```
5. **Verify before trusting it** - confirm the MSI's `Registry` table actually
   contains what was requested:
   ```powershell
   $installer = New-Object -ComObject WindowsInstaller.Installer
   $db = $installer.GetType().InvokeMember("OpenDatabase","InvokeMethod",$null,$installer,@("Apps\<AppName>\Source\<Name>.msi",0))
   $view = $db.GetType().InvokeMember("OpenView","InvokeMethod",$null,$db,@("SELECT ``Registry``,``Root``,``Key``,``Name``,``Value`` FROM ``Registry``"))
   $view.GetType().InvokeMember("Execute","InvokeMethod",$null,$view,$null) | Out-Null
   while ($r = $view.GetType().InvokeMember("Fetch","InvokeMethod",$null,$view,$null)) {
       (1..5 | ForEach-Object { $r.GetType().InvokeMember("StringData","GetProperty",$null,$r,$_) }) -join " | "
   }
   ```
6. Drop the `.msi` in `Inbox\` (or leave it in `Apps\<AppName>\Source\`) and run
   `Process-Inbox.ps1` / `Create-IntunePackage.ps1` as usual - it reads the
   real ProductCode out of the MSI and generates `install.cmd`/`uninstall.cmd`/
   `detect.ps1` automatically, then builds the verified, versioned `.intunewin`.

## Quick Start (full app install)

1. Put `YourApp.exe` / `Support.dll` etc. in a `source\` folder.
2. Edit `Product.wxs`: `Name`, `Manufacturer`, a fresh `UpgradeCode` GUID, and
   the `<File Source="...">` paths.
3. Build:
   ```powershell
   .\Tools\wix\Build-MSI.ps1 -WxsFile Product.wxs -OutputMsi output\YourApp.msi
   ```
   (or directly: `wix build Product.wxs -d SourceDir=.\source -o output\YourApp.msi`)
4. Continue as above: drop the `.msi` in `Inbox\` and let `Process-Inbox.ps1` /
   `Create-IntunePackage.ps1` take it from there.

## Common Customizations

### Add More Registry Values

```xml
<RegistryKey Root="HKLM" Key="Software\YourCompany\YourSetting">
  <RegistryValue Type="string" Name="Mode" Value="Enabled" KeyPath="yes" />
  <RegistryValue Type="integer" Name="Timeout" Value="30" />
</RegistryKey>
```

### Add a Desktop Shortcut

```xml
<StandardDirectory Id="DesktopFolder">
  <Component Id="DesktopShortcut" Guid="*">
    <Shortcut Id="DesktopShortcut"
              Name="YourAppName"
              Target="[INSTALLFOLDER]YourApp.exe"
              WorkingDirectory="INSTALLFOLDER"/>
    <RegistryValue Root="HKCU"
                   Key="Software\YourCompany\YourAppName"
                   Name="DesktopShortcut"
                   Type="integer"
                   Value="1"
                   KeyPath="yes"/>
  </Component>
</StandardDirectory>
```

### Add a Service Installation

```xml
<Component Id="ServiceComponent" Guid="*">
  <File Id="ServiceExe" Source="$(var.SourceDir)\YourService.exe" KeyPath="yes" />
  <ServiceInstall Id="ServiceInstaller"
                  Name="YourServiceName"
                  DisplayName="Your Service Display Name"
                  Start="auto"
                  Type="ownProcess"
                  ErrorControl="normal" />
  <ServiceControl Id="ServiceControl"
                  Name="YourServiceName"
                  Start="install"
                  Stop="both"
                  Remove="uninstall" />
</Component>
```

## Troubleshooting

**"wix: command not found" / CLI not found**
- Confirm it's installed: `dotnet tool list -g` should show `wix`.
- If missing: `dotnet tool install --global wix`
- `Build-MSI.ps1` also checks `%USERPROFILE%\.dotnet\tools\wix.exe` directly if
  `wix` isn't on PATH.

**Schema errors mentioning `Product`, `InstallScope`, or plain `Directory Id="TARGETDIR"`**
- Those are WiX v3 syntax. v4 uses a single `<Package>` element (no separate
  `<Product>`), `Scope` instead of `InstallScope`, and `<StandardDirectory>` for
  well-known folders like `ProgramFilesFolder`/`TARGETDIR`. Both templates in
  this folder already use the correct v4 syntax.

**"Unresolved reference to symbol"**
- Check Component IDs are referenced correctly and every `ComponentGroupRef`/
  `ComponentRef` points at something that actually exists.

**Get a built MSI's ProductCode/Registry contents**
- See the verification snippet in the Quick Start above - swap the SQL query's
  table name (`Property`, `Registry`, etc.) to inspect other parts of the MSI.

## Resources

- WiX v4 Docs: https://wixtoolset.org/docs/
- WiX Schema Reference: https://wixtoolset.org/docs/schema/

---

**Updated**: 2026-07-17
**WiX Version**: v4 CLI (`wix` dotnet tool), verified installed and working on this machine
**Purpose**: Registry/settings config MSIs and full app installs, both feeding into the standard Inbox -> Apps\<AppName> -> .intunewin pipeline
