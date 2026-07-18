# IntuneWin Packaging Workspace

This workspace builds `.intunewin` packages for Microsoft Intune Win32 app deployment.
Every application lives in its own folder under `Apps\` with a `Source\` (inputs) and
`Output\` (built packages, versioned) subfolder — so nothing gets mixed together and
you can always see the build history for a given app.

## Folder Structure

```
IntuneWin/
├── Apps/
│   ├── <AppName>/
│   │   ├── Source/           # Installer + install.cmd/uninstall.cmd/detect.ps1 + intune-config-template.md go here
│   │   └── Output/           # Built .intunewin files, one per version, named <AppName>_<version>.intunewin
│   ├── AXCodeSetup/
│   ├── Python314/
│   ├── VSCodeWindows/
│   ├── VSCodeMac/
│   ├── XeroxPrinter/
│   ├── AdobeAcrobatPro/       # includes the MSI+MST merge build tooling in Source/_build-tools
│   ├── DotNetSDK/
│   ├── Zoom/                  # installer present, not yet packaged
│   └── Autodesk/              # installer present, not yet packaged
├── Tools/
│   ├── IntuneWinAppUtil.exe   # Microsoft Win32 Content Prep Tool
│   ├── wix/                   # WiX v4 templates: ConfigTemplate.wxs (registry/settings-only MSI), Product.wxs (full app install)
│   └── nsis/                  # generic NSIS installer-build template (not app-specific)
├── Scripts/
│   ├── Process-Inbox.ps1          # drop-zone automation: Inbox\ -> Apps\<App>\Source -> built + verified
│   ├── Create-IntunePackage.ps1   # build + verify + version + clean up an app
│   └── Test-*.ps1                 # ad-hoc test/validation scripts
├── Inbox/                     # <-- drop new/updated installers here, then run Process-Inbox.ps1
├── Docs/                      # general guides (not tied to one app)
└── README.md
```

## Adding or updating an app — the easy way

1. **Drop the installer file (.exe or .msi) into `Inbox\`.** Nothing else required.
2. Run `.\Scripts\Process-Inbox.ps1` (or just ask Claude to "process the inbox").
   For every file it finds, it will:
   - Work out which app it belongs to — matching an existing `Apps\<AppName>\`
     folder if the filename looks related (e.g. `VSCodeSetup-x64-1.130.0.exe`
     matches the existing `VSCodeWindows` app), otherwise creating a new
     `Apps\<AppName>\` folder.
   - Move the installer into that app's `Source\` (it never lingers in `Inbox\`).
   - If it's a brand-new app, scaffold `install.cmd` / `uninstall.cmd` /
     `detect.ps1`: for `.msi` installers these are generated from the file's
     real ProductCode/ProductName (reliable); for `.exe` installers it's a
     best-effort guess flagged as **UNVERIFIED** in a `_NEEDS-REVIEW.md` file —
     check that before deploying.
   - Build, verify, version, and clean up exactly as described below.
3. **Upload to Intune** from `Apps\<AppName>\Output\`.

## Adding or updating an app — manual way

If you'd rather place things yourself: drop the installer (and `install.cmd` /
`uninstall.cmd` / `detect.ps1`) directly into `Apps\<AppName>\Source\`, then run:

```powershell
.\Scripts\Create-IntunePackage.ps1 -AppName <AppName>
```

(omit `-AppName` to pick from a menu; optionally pass `-Version x.y.z`). The script:
- Verifies `Tools\IntuneWinAppUtil.exe` and the setup file exist before doing anything.
- Builds the `.intunewin`.
- **Verifies the result** (valid zip header + sane file size) before trusting it.
- Saves it as `Apps\<AppName>\Output\<AppName>_<version>.intunewin` — older versions
  are never overwritten, so `Output\` becomes your version history.
- Once verified, **removes the large installer binary from `Source\`** (anything over
  5 MB) since it's already safely archived inside the `.intunewin`. Small scripts/docs
  stay in `Source\` so it's ready for the next version's installer. Pass
  `-SkipSourceCleanup` to disable this.
- **Generates `Apps\<AppName>\Source\intune-config-template.md`** if the app doesn't
  already have one — the exact install command, uninstall command, and detection rule
  to punch into the Intune console, plus the built package's name/size. For `.msi` apps
  this is populated with the installer's real ProductName/ProductCode; fields nothing
  can infer (description, publisher, category, requirements) are left marked `EDIT ME`.

See the `package-intune-app` Claude Code skill (`.claude/skills/package-intune-app/`)
for the full step-by-step checklist both scripts follow, including what to double-check
before/after each build.

## No installer at all — registry edits / settings / deploy templates

If the request is "make these registry key edits / policy settings happen via
Intune" rather than "package this installer," a real `.msi` gets built from
`Tools\wix\ConfigTemplate.wxs` (WiX v4 CLI, confirmed installed and working on
this machine) with the exact registry keys/values requested, verified by
inspecting the compiled MSI's `Registry` table, then fed through the same
Inbox/`Create-IntunePackage.ps1` pipeline above. See `Tools\wix\README.md` and
the `package-intune-app` skill for the full steps.

## Notes on specific apps

- **AdobeAcrobatPro**: `Source\` contains the full Adobe admin install source tree plus
  the MST-merge tooling (`Source\_build-tools\Merge-MSI-MST.ps1` and friends) used to
  build a merged MSI before packaging. This source tree is large (~4.3 GB) and is
  reusable build material, not a one-off installer — it was **not** auto-cleaned.
- **XeroxPrinter**: `Source\Driver\` is the actual driver payload (not a redundant
  installer copy), so it was left in place.
- **Zoom** and **Autodesk**: installers are in `Source\` but no `install.cmd` /
  `uninstall.cmd` / `detect.ps1` exist yet and nothing has been packaged — write those
  scripts, then run `Create-IntunePackage.ps1` to produce the first `Output\` build.
