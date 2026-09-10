# Windows packaging

This document defines the canonical packaging contract for Awful Cases. It describes how to build portable Windows x64 artifacts; it does not claim that a GitHub Release has been published.

## Canonical command

Run from the repository root on Windows with PowerShell 7:

```powershell
pwsh -File tools/package.ps1
```

By default artifacts are written to `dist/`. A different output directory can be supplied:

```powershell
pwsh -File tools/package.ps1 -OutputDirectory C:\path\to\dist
```

## Pinned toolchain

Packaging downloads only the following pinned official archives and verifies SHA-256 before extraction:

- AutoHotkey v2.0.27: `AutoHotkey_2.0.27.zip`
  - SHA-256: `F72CAD4B98A7B5AA050B35D6DEAA0B0E3949929B2AAFF7D0D69858F1F380B3EF`
  - upstream: AutoHotkey/AutoHotkey GitHub Release `v2.0.27`
- Ahk2Exe v1.1.37.02a2: `Ahk2Exe1.1.37.02a2.zip`
  - SHA-256: `C29B8C3A5124850D79FC9E66E2CA79677C377D7F31631AD3022BA159C5D9E3BE`
  - upstream: AutoHotkey/Ahk2Exe GitHub Release `Ahk2Exe1.1.37.02a2`

A digest mismatch fails packaging before any downloaded executable is used.

## Inputs

The package command treats these repository files as inputs:

- `VERSION`
- `app/awful-cases.ahk`
- `app/lib/text-transforms.ahk`
- `app/awful-cases.ico`
- `app/awful-cases.ini`
- `LICENSE`
- repository contracts in `tests/repo-contract.ps1`

The production source is not rewritten. Packaging copies `app/` to a temporary build directory and prepends Ahk2Exe version-resource directives only to that temporary copy.

`VERSION` is the package version source. Existing repository contracts require `VERSION` and `AppVersion` to agree before packaging succeeds. The Windows file version emitted by Ahk2Exe is derived from `VERSION` as `x.y.z.0`.

## Artifacts for 0.1.0

For the current `VERSION=0.1.0`, a successful package command produces:

- `dist/awful-cases-v0.1.0-windows-x64.exe`
- `dist/awful-cases-v0.1.0-windows-x64.zip`
- `dist/SHA256SUMS.txt`

The filenames are generated from `VERSION`; the names above are the concrete current-version examples used by the package contract.

The portable ZIP contains one top-level directory named `awful-cases-v0.1.0-windows-x64/` with:

- `awful-cases.exe`
- `awful-cases.ini`
- `LICENSE`
- `VERSION`
- `README.txt`

The INI ships beside the executable so the package has explicit starting defaults. If it is deleted later, the application still recreates its default config on the next start.

## Verification

`tools/package.ps1` fails closed when:

- packaging is run outside Windows;
- a required repository input is missing;
- repository consistency contracts fail;
- a downloaded tool archive does not match its pinned SHA-256;
- the x64 AutoHotkey base or Ahk2Exe executable cannot be found;
- Ahk2Exe returns a non-zero exit code;
- the expected executable or ZIP is absent;
- compiled `FileVersion` does not match `VERSION`;
- the ZIP does not contain all required members.

After successful assembly, SHA-256 digests for the standalone EXE and portable ZIP are written to `SHA256SUMS.txt`.

CI may build and retain package artifacts for verification, but ordinary CI must not publish a GitHub Release or push source changes.

## Reproducibility boundary

The build inputs, upstream tool versions, upstream archive digests, package layout, naming and version metadata are deterministic and pinned. `SHA256SUMS.txt` certifies the concrete artifacts produced by a build.

This contract does not promise byte-for-byte identical PE or ZIP output across different Windows hosts unless that property is separately demonstrated. PE metadata, archive implementation details or tool behavior may make binary-identical cross-host output stronger than the project currently proves.

## Security and distribution status

The first supported package is **portable** and **unsigned**. It is **not an installer** and is not code-signed. Windows SmartScreen or reputation warnings are therefore possible. The project must not claim trusted-publisher status, SmartScreen reputation, Authenticode signing or installer behavior until those capabilities actually exist and are verified.

Do not tell users to disable Windows security protections as a workaround.

A packaged CI artifact is also not automatically a public release. Public download wording should point to binary release assets only after a real GitHub Release has been created and its uploaded assets/checksums verified.
