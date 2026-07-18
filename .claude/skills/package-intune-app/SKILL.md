---
name: package-intune-app
description: Build, verify, version, and file away a .intunewin package for an app in this workspace (C:\IntuneWin) - including building a real MSI from scratch for registry/settings/config-template deployments that have no installer file. Use whenever the user wants to package/build/create an intunewin for an app, add a new app to package, update an existing app to a new version, process/watch the Inbox drop folder, clean up after a build, or turn registry key edits / settings changes / a deployment template into an MSI. Triggers on "package this", "build the intunewin", "add a new app", "I dropped/uploaded a file", "process the inbox", "update <app> to version X", "clean up the source folder", "turn this into an MSI", "registry key edit", "deploy this setting/template".
---

# Packaging an app into .intunewin

This workspace keeps one folder per app under `Apps\<AppName>\`, each with a
`Source\` (inputs) and `Output\` (built, versioned packages) subfolder. Follow
these steps in order every time — don't skip the verify step, and don't delete
anything from `Source\` until the build is confirmed good.

## 0. Identify the app folder

- Existing app → `Apps\<AppName>\`. List apps with `Get-ChildItem Apps -Directory`
  if unsure of the exact name.
- Brand-new app → create `Apps\<AppName>\Source\` and `Apps\<AppName>\Output\`
  first (`New-Item -ItemType Directory -Force`).

## 1. Where the user puts new/updated files

**Default answer: `Inbox\`.** Tell the user to drop the installer (`.exe`/`.msi`)
there — that's the one place they ever need to remember, for a brand-new app or
an update to an existing one. Then run:

```powershell
.\Scripts\Process-Inbox.ps1
```

This does the app-name matching, folder creation, script scaffolding (real
ProductCode-based for `.msi`, flagged-UNVERIFIED for `.exe`), build, verify,
version, and source cleanup all in one pass — for every file currently sitting
in `Inbox\`. Nothing is left behind in `Inbox\`: each file is moved out as soon
as it's matched to an app.

After it runs, check the output for any `_NEEDS-REVIEW.md` it mentions — that
means an `.exe` install/uninstall/detect script was guessed and must be
verified before the app is deployed to real devices.

If the user instead wants to place things by hand (e.g. they already have
`install.cmd`/`uninstall.cmd`/`detect.ps1` written), the direct location is:

```
Apps\<AppName>\Source\
```

Reference an existing app's `Source\` folder (e.g. `Apps\Python314\Source\`) as
a template for install.cmd/uninstall.cmd/detect.ps1 structure when scripting a
brand-new app by hand.

## 2. Pre-flight checks (do these before building)

- `Tools\IntuneWinAppUtil.exe` exists.
- `Apps\<AppName>\Source\` contains the setup file referenced by `install.cmd`
  (or whatever `-SetupFile` you're using) and the installer it launches.
- If this is a version update, confirm the new installer's version number so
  the output can be named correctly (e.g. ask the user, or check the installer's
  file properties / a version string in its filename).

## 3. Build

`Process-Inbox.ps1` calls this for you. If you're working from an already-placed
`Source\` folder instead, run it directly:

```powershell
.\Scripts\Create-IntunePackage.ps1 -AppName <AppName> -Version <x.y.z>
```

(Omit `-Version` to fall back to today's date as the version tag.) This script
already does steps 4–6 below automatically — use it rather than calling
`IntuneWinAppUtil.exe` directly, so the checks and cleanup always happen the
same way.

## 4. Verify — never skip this

Before treating a build as good, confirm:

- The command exited with code 0.
- The output file exists at `Apps\<AppName>\Output\<AppName>_<version>.intunewin`.
- It has a valid ZIP header (first two bytes `PK`, i.e. `0x50 0x4B`) — a
  `.intunewin` is a zip container, so a bad header means a corrupt/truncated build.
- Its size is sane (not a few KB — that's a sign the source folder or setup file
  was wrong/empty). Compare roughly against the installer's own size as a gut check.

`Create-IntunePackage.ps1` performs this check itself and refuses to touch
`Source\` if verification fails — if you're doing a manual build outside that
script, replicate this check before moving on.

## 5. File it away with a version, never overwrite history

- Save/keep the build as `Apps\<AppName>\Output\<AppName>_<version>.intunewin`.
- Do **not** delete or overwrite an older `.intunewin` in `Output\` for a
  version bump — every version stays there so there's a visible build history
  per app. Only replace a file in `Output\` if you're re-building the *exact
  same* version to fix a mistake.

## 6. Clean up Source\ after a verified build

Once (and only once) the build is verified per step 4:

- Remove the large installer binary(ies) (anything over ~5 MB) from
  `Apps\<AppName>\Source\` — it's already safely archived inside the
  `.intunewin`, and can be recovered by extracting the `.intunewin` (it's a
  zip) if ever needed.
- Leave `install.cmd`, `uninstall.cmd`, `detect.ps1`, and any docs/templates in
  `Source\` — they're small and needed as the starting point for the next
  version.

`Create-IntunePackage.ps1` does this automatically; pass `-SkipSourceCleanup`
to opt out for a specific run (e.g. while iterating on a detection script and
you don't want to re-supply the installer each time).

### Exceptions — don't blindly auto-clean these

- **AdobeAcrobatPro**: `Source\` holds the full Adobe admin install tree plus
  MST-merge build tooling (`Source\_build-tools\`) — this is reusable build
  material for producing future merged MSIs, not a disposable installer copy.
  Leave it in place.
- **XeroxPrinter**: `Source\Driver\` is the actual driver payload the install
  script needs, not a redundant installer copy — leave it in place.
- Any app where `Source\` contains build material that isn't simply "one
  installer file that's now embedded in the intunewin" — think before deleting;
  ask the user if unsure.

## 7. Every app gets an Intune config + install guide in its Source\ folder

`Create-IntunePackage.ps1` auto-generates `Apps\<AppName>\Source\intune-config-template.md`
after the first verified build, if one doesn't already exist — so this happens
automatically, nothing extra to remember. It documents the actual install
command, uninstall command, and detection rule to use when configuring the app
in the Intune console, plus the built package's name/size. For `.msi` apps
scaffolded by `Process-Inbox.ps1`, the guide is generated at scaffold time with
the MSI's real ProductName/ProductCode already filled in — better than the
generic fallback. Fields the scripts can't know (description, publisher,
category, disk/memory requirements) are left marked `EDIT ME` — fill those in
from what you know about the app before deploying.

See `Apps\Python314\Source\intune-config-template.md` or
`Apps\DotNetSDK\Source\intune-config-template.md` for fully filled-in examples.

## 8. Tell the user where things ended up

Finish by stating plainly:
- Where the new build is: `Apps\<AppName>\Output\<AppName>_<version>.intunewin`
- That it's ready to upload to Intune.
- Where its `intune-config-template.md` is, and whether it still has `EDIT ME`
  fields that need filling in before deployment.
- What (if anything) was cleaned from `Source\`.

## 9. When there's no installer at all — registry edits / settings / "deploy templates"

Sometimes the request isn't "package this installer" but "make these registry
key edits / policy settings / a config template happen via Intune" — with no
`.exe`/`.msi` supplied. Build a real MSI for it rather than improvising a
script-only package, using WiX (verified installed and working on this
machine: `wix` v4 CLI at `%USERPROFILE%\.dotnet\tools\wix.exe`):

1. Copy `Tools\wix\ConfigTemplate.wxs` into `Apps\<AppName>\Source\<Name>.wxs`
   (create the app folder if new). This template is registry/settings-only —
   no files installed.
2. Generate a fresh GUID for `UpgradeCode` (`[guid]::NewGuid()` in PowerShell)
   — never reuse the placeholder or another app's GUID.
3. Fill in the exact `RegistryKey`/`RegistryValue` block(s) for what was
   requested. Add more `<RegistryValue>` lines under one key, or duplicate the
   `<RegistryKey>` block for a different registry path.
4. Build it: `wix build Apps\<AppName>\Source\<Name>.wxs -o Apps\<AppName>\Source\<Name>.msi`
5. **Verify the compiled MSI actually contains what was asked for** — don't
   just trust a clean exit code. Query its `Registry` table via the
   `WindowsInstaller.Installer` COM object (see `Tools\wix\README.md` for the
   exact snippet) and confirm the keys/values/data match the request. This
   matters more here than for a normal installer wrap, since the whole point
   of the MSI is those exact registry entries.
6. Once verified, treat the `.msi` exactly like any other installer: drop it
   in `Inbox\` (or leave it in `Apps\<AppName>\Source\`) and run
   `Process-Inbox.ps1` / `Create-IntunePackage.ps1` — it reads the real
   ProductCode out of the MSI and generates accurate `install.cmd`/
   `uninstall.cmd`/`detect.ps1` automatically (this is the reliable, non-guessed
   path — unlike the `.exe` scaffold case in step 1, MSI-based scripts don't
   need a `_NEEDS-REVIEW.md` flag).
7. Keep the `.wxs` source file in `Apps\<AppName>\Source\` — it's small text,
   won't be touched by the large-file cleanup in step 6, and is what you'll
   edit next time this app's settings need to change.
