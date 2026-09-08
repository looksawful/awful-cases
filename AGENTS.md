# Awful Cases agent guide

## Scope

Awful Cases is a Windows tray utility written for AutoHotkey v2. It transforms selected text through global hotkeys and temporarily uses the Windows clipboard for copy/paste handoff.

Primary source of truth:

- `app/awful-cases.ahk` — application runtime, UI and text transforms.
- `app/awful-cases.ini` — checked-in portable default configuration.
- `VERSION` — current release version.
- `CHANGELOG.md` — release history.
- `docs/index.html` — public GitHub Pages artifact. Treat it as a separate website/trainer surface, not application source.

## Required workflow

1. Work on a branch. Do not push feature or repair work directly to `main`.
2. Read the relevant code path before changing it. The main AHK file currently mixes startup, config, hotkeys, UI, clipboard I/O and typography rules, so apparently local changes can have non-local effects.
3. Run `pwsh -File tests/repo-contract.ps1` before committing.
4. Let the `quality` GitHub Actions workflow validate the AHK source with AutoHotkey v2 on Windows.
5. For behavior that depends on selection, clipboard timing, global hotkeys or GUI controls, complete the manual Windows smoke matrix in `DEVELOPMENT.md`.
6. Open or update a GitHub issue for defects and architectural debt that are not fixed in the same change.

## Change constraints

### Versioning

Keep all release metadata synchronized:

- `VERSION`
- `global AppVersion` in `app/awful-cases.ahk`
- matching `## x.y.z` section in `CHANGELOG.md`

### Hotkeys

Hotkey support is represented in several places today. Until that duplication is removed, verify all of them when changing keys:

- `AllowedFinalHotkeyKeys`
- `GetDefaultConfig()`
- `app/awful-cases.ini`
- settings GUI key choices
- capture/normalization logic

Never add a key in only one representation.

### Typography rules

Typography transforms touch user text. Preserve protected fragments such as URLs, email addresses, file paths and inline code unless the task explicitly changes protection behavior.

For every regex change, document at least:

- input text
- expected output
- one near-miss that must remain unchanged
- language assumptions

Prefer narrowly scoped rules over broad cleanup expressions. A typography rule that is clever enough to need a paragraph of excuses is probably too broad.

### Clipboard path

`TransformSelectedText()` temporarily replaces the user's clipboard. Changes to copy/paste timing are high-risk because application paste behavior is asynchronous and varies by target application.

Any clipboard change requires manual checks in at least:

- Notepad
- a Chromium-based browser editable field
- an Office-style rich text editor when available
- a slow or remote target when available
- large multi-line text
- no-selection behavior

The user's original clipboard contents must be restored after a successful transform and after every failure path.

### UI and configuration

Configuration round-trips must be lossless. Opening settings and pressing Save without changing a value must not mutate a valid existing configuration.

RU and EN UI modes must expose the same controls and behavior.

### Public website

Do not casually edit `docs/index.html`. It is a large standalone artifact and the repository currently does not contain a documented source/build pipeline for regenerating it. Website/trainer work should be isolated from the Windows utility unless the task explicitly spans both.

## Tooling

Required:

- Windows 11 or a Windows CI runner
- AutoHotkey v2.0.x
- PowerShell 7+
- Git
- GitHub Actions

Useful review tools:

- GitHub Issues and pull requests for traceable defects and changes
- CodeRabbit CLI when installed and authenticated; treat it as an additional reviewer, never as a substitute for tests

## Local skills

Use the repository-specific playbooks under `.agents/skills/`:

- `awful-cases-development` for ordinary changes
- `typography-rules` for text normalization and regex work
- `release-check` for versioning and release validation
