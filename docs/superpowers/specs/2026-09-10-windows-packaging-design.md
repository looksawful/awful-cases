# Windows packaging and distribution design

## Goal

Turn Awful Cases into a normal Windows 10/11 x64 application distribution while preserving the existing AutoHotkey v2 runtime architecture and text-transform behavior.

## Supported artifacts

The first supported release produces exactly three versioned assets:

- `Awful-Cases-<version>-x64.exe` — standalone compiled application;
- `Awful-Cases-Portable-<version>-x64.zip` — portable package containing the executable, default INI, `portable.flag`, and license;
- `Awful-Cases-Setup-<version>-x64.exe` — per-user installer.

A release also publishes `SHA256SUMS.txt` containing SHA-256 hashes for the three binary/package assets.

The GitHub source archive is source code only and is never presented as the Windows application download.

## Toolchain

Canonical packaging uses:

- AutoHotkey v2.0.27 x64 archive, SHA-256 `F72CAD4B98A7B5AA050B35D6DEAA0B0E3949929B2AAFF7D0D69858F1F380B3EF`;
- official Ahk2Exe v1.1.37.02a2 archive, SHA-256 `C29B8C3A5124850D79FC9E66E2CA79677C377D7F31631AD3022BA159C5D9E3BE`;
- Inno Setup 7.1.0 x64 installer, SHA-256 `0362A383ED217D4C4239B5933866DD96D3EB2102737DA92F80F6057A4B40DF2F`.

Every downloaded tool is hash-verified before execution. Packaging fails closed on any mismatch.

## Build inputs

The executable is compiled from:

- `app/awful-cases.ahk`;
- `app/lib/text-transforms.ahk` and any other included application libraries;
- `app/awful-cases.ico`.

`VERSION` is the release version source. `AppVersion` and the Ahk2Exe version-resource directive must match it and are enforced by repository contracts.

## Configuration model

Source/development execution continues to use `app/awful-cases.ini` beside the `.ahk` file.

A compiled installed application stores settings in `%APPDATA%\Awful Cases\awful-cases.ini`. On first run, if that file does not exist and a legacy `awful-cases.ini` exists beside the executable, the application copies it to the AppData location.

A compiled application switches to portable mode when `portable.flag` exists beside the executable. Portable mode stores `awful-cases.ini` beside the executable.

The installer does not write the user INI. The application owns first-run config creation so upgrades do not overwrite user settings.

## Installation model

The Inno Setup package installs for the current user without elevation to `%LOCALAPPDATA%\Programs\Awful Cases`.

It creates a Start Menu shortcut, registers uninstall metadata, and offers an unchecked optional task to start Awful Cases with Windows. Autostart uses the current-user `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` entry named `Awful Cases`.

The application tray also exposes an autostart toggle that manages the same registry value.

## CI and release model

Ordinary CI remains `contents: read`. It runs repository contracts, AutoHotkey tests, and a packaging job that builds all release-shaped artifacts but does not publish a release. The packaging output is uploaded only as a CI artifact for inspection.

Release publication is isolated in `.github/workflows/release.yml` with `actions: read` and `contents: write`. It is manual (`workflow_dispatch`) and requires an explicit `desktop_smoke_passed=true` input. The workflow verifies a successful ordinary CI run for the exact commit, re-runs automated tests, packages the application, creates tag `v<VERSION>`, publishes the four release assets, downloads them again, and verifies `SHA256SUMS.txt`.

The release workflow must not claim code signing. Until a signing solution is added, documentation explicitly states that the application and installer are unsigned and Windows SmartScreen may warn.

## Release gate

A public release requires all existing checks in `docs/TESTING.md`, plus successful package construction and checksum verification. Headless CI is not evidence that foreground-editor clipboard/input behavior passed the desktop matrix.

## Non-goals

No Electron/Tauri rewrite, background update service, MSIX package, Microsoft Store publication, or code-signing infrastructure is introduced in this stage. The existing AutoHotkey application remains the product runtime.
