# Awful Cases testing and release gate

Awful Cases has three verification layers:

1. automated repository, package-contract and AutoHotkey tests;
2. Windows package construction and checksum verification;
3. a short Windows desktop smoke test for behavior that depends on the foreground application, selection, keyboard input, and clipboard formats.

Ordinary CI is intentionally verification-only. It must not rewrite or push application source or publish a GitHub Release.

## Automated gate

From the repository root on Windows:

```powershell
pwsh -File tests/repo-contract.ps1
pwsh -File tests/package-contract.ps1
pwsh -File tools/test.ps1
```

`tools/test.ps1` requires AutoHotkey v2. Pass a non-standard executable explicitly when needed:

```powershell
pwsh -File tools/test.ps1 -AutoHotkeyPath "C:\path\to\AutoHotkey64.exe"
```

GitHub Actions runs the same repository contracts and AutoHotkey suite with pinned AutoHotkey v2.0.27 and verifies the downloaded archive SHA-256 before execution.

## Package gate

Build the complete release-shaped package set with:

```powershell
pwsh -File tools/package.ps1
```

The command must finish with exactly these release-shaped outputs for the version in `VERSION`:

```text
Awful-Cases-<version>-x64.exe
Awful-Cases-Portable-<version>-x64.zip
Awful-Cases-Setup-<version>-x64.exe
SHA256SUMS.txt
```

The package script pins and SHA-256 verifies the official AutoHotkey, Ahk2Exe and Inno Setup downloads before executing them. `SHA256SUMS.txt` must list exactly the standalone executable, portable ZIP and installer, and every listed hash must match the corresponding built file.

The portable ZIP must contain `Awful-Cases.exe`, `awful-cases.ini`, `portable.flag` and `LICENSE`. The installer must be a per-user package targeting `%LOCALAPPDATA%\Programs\Awful Cases`; it must not require administrator elevation.

CI uploads the package output as a temporary Actions artifact for inspection. That artifact is verification evidence, not a public release.

## Windows desktop smoke test

Run this matrix after changes to `TransformSelectedText()`, hotkeys, clipboard handling, `SendText`, selection capture, or before a release.

Use a short sample such as:

```text
Привет,world. User.Name@example.com v2.0.1 3.14 ✓ 😀
```

Also prepare a large plain-text sample between roughly 10 KB and 50 KB.

Before each test, place unrelated content on the clipboard. At least once use non-text or rich clipboard data, for example an image copied from Paint or formatted text copied from a rich-text editor.

| Target | Minimum scenario | Verify |
| --- | --- | --- |
| Windows Notepad | select normal RU/EN text and run case + lint actions | transformed once; no truncation/duplication; clipboard unchanged |
| Browser textarea | run a transform in a normal `<textarea>` | replacement lands in the selected range; focus stays in the field; clipboard unchanged |
| Browser contenteditable | run a transform in an editable rich web field when available | no duplicate insertion; selection is replaced; clipboard unchanged |
| VS Code | transform prose/plain text in an editor tab | exact replacement; no stuck Ctrl/Alt/Shift state; clipboard unchanged |
| Word or LibreOffice Writer | transform a selected sentence | selected text is replaced once; surrounding document remains intact; clipboard content is restored |
| Cyrillic text | run Upper, Lower and Toggle on Cyrillic text | case transforms are correct |
| Large 10–50 KB selection | run a simple case transform | complete insertion; no truncation or duplicated suffix/prefix; acceptable interactive behavior |
| Non-text clipboard | copy an image or rich content, transform selected text elsewhere | original clipboard payload can still be pasted afterward |
| No selection | invoke a transform with only a caret | document remains unchanged; existing clipboard remains usable |

For every target also confirm that no modifier key appears stuck after the shortcut completes. A quick check is to type ordinary text immediately after the operation.

For release candidates built as installed packages, also install and uninstall once, confirm the Start Menu shortcut works, confirm the optional startup task is unchecked by default, toggle `Run at startup` from the tray, and verify that user configuration under `%APPDATA%\Awful Cases` survives an application upgrade/uninstall unless deliberately removed by the user.

## Release gate

Do not tag or publish a release until all items below are true:

- working tree / release commit is based on current `main`;
- GitHub CI is green on the exact release commit, including the package job;
- `pwsh -File tests/repo-contract.ps1` passes;
- `pwsh -File tests/package-contract.ps1` passes;
- `pwsh -File tools/test.ps1` passes with AutoHotkey v2;
- `pwsh -File tools/package.ps1` succeeds on Windows and produces the expected four files;
- all entries in `SHA256SUMS.txt` match the built artifacts;
- the desktop smoke matrix above passes for the areas affected by the release; run the full matrix for changes to clipboard/input integration and before the first packaged release;
- installed and portable configuration behavior is smoke-tested for the packaged release;
- `VERSION`, `AppVersion`, and the Ahk2Exe version-resource directive agree;
- `CHANGELOG.md` contains the released version and accurately describes user-visible changes;
- `app/awful-cases.ini`, `GetDefaultConfig()`, and `GetDefaultFeatureState()` remain synchronized through repository contracts;
- README/settings documentation matches the actual behavior;
- no temporary one-shot workflow or source-patching automation is present in `.github/workflows/`;
- the `Release` workflow is manually dispatched from `main` with `desktop_smoke_passed=true` only after the checks above are actually complete.

The current executable and installer are unsigned. Passing this release gate does not imply Authenticode signing or SmartScreen reputation.

## When a smoke check fails

Record the exact target application, its version when relevant, input text, action/hotkey, clipboard type, package type, and observed result. Reduce the case before changing code. If the failure is deterministic, add an automated test for the pure or integration logic that can be isolated, then make the smallest fix. Do not replace application-specific evidence with longer arbitrary `Sleep` delays.
