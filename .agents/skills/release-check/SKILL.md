# Release check

Use this playbook when preparing a tagged or downloadable Awful Cases release.

## Release metadata

Before packaging, confirm one exact version appears in all required locations:

- `VERSION`
- `global AppVersion` in `app/awful-cases.ahk`
- a matching heading in `CHANGELOG.md`

Run `pwsh -File tests/repo-contract.ps1`; it enforces this synchronization.

## Required quality gates

1. Repository contract checks pass.
2. GitHub Actions `AutoHotkey v2 syntax` job passes using AutoHotkey 2.0.x.
3. Manual Windows smoke tests in `DEVELOPMENT.md` pass.
4. Default `app/awful-cases.ini` still matches the embedded `GetDefaultConfig()`.
5. All default hotkeys are unique and supported.
6. Opening and saving settings without edits does not mutate valid configuration.
7. Clipboard content is restored after successful transforms and failure/no-selection paths.
8. Protected URL, email, path and code examples survive typography cleanup unchanged except for behavior explicitly documented by the release.

## Packaging

The source release must contain at minimum:

- `app/awful-cases.ahk`
- `app/awful-cases.ini`
- icon assets
- `README.md`
- `LICENSE`
- `VERSION`
- `CHANGELOG.md`

If an `.exe` is published, record the exact AutoHotkey/Ahk2Exe version used to build it and verify that the executable reports the same application version as `VERSION`.

Do not infer release readiness from a green syntax check alone. Syntax checking proves the interpreter can load the script; Windows interaction, global hotkeys and clipboard behavior still require an end-to-end smoke pass.