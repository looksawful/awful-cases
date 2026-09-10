# Awful Cases

[Website](https://looksawful.github.io/awful-cases/) · [Source ZIP](https://github.com/looksawful/awful-cases/archive/refs/heads/main.zip) · [looksawful.ru](https://looksawful.ru)

Windows tray utility for changing the case and typography of selected text.

Awful Cases works through global hotkeys. Select text in any editable field, press a shortcut, and the app replaces the selection with the transformed version.

> The repository archive linked above is source code, not an installer or published application release. Windows binary packaging is defined in [`docs/PACKAGING.md`](docs/PACKAGING.md). Public binary download links belong here only after a real GitHub Release exists and its assets have been verified.

## Features

* Uppercase
* Lowercase
* Toggle case
* Title case
* Typography cleanup
* Sentence-level typography cleanup
* URL, email, domain, file path and inline code protection
* Clipboard preservation after each transform
* Configurable hotkeys through `awful-cases.ini`

## Default shortcuts

All actions use `Ctrl + Alt + Shift` plus one key.

| Action              | Shortcut                      |
| ------------------- | ----------------------------- |
| Uppercase           | `Ctrl + Alt + Shift + Up`     |
| Lowercase           | `Ctrl + Alt + Shift + Down`   |
| Toggle case         | `Ctrl + Alt + Shift + Right`  |
| Title case          | `Ctrl + Alt + Shift + Left`   |
| Typography cleanup  | `Ctrl + Alt + Shift + PgDn`   |
| Sentence typography | `Ctrl + Alt + Shift + Delete` |
| Settings            | `Ctrl + Alt + Shift + Home`   |

The settings UI supports the same final-key set as runtime validation, including `F1` through `F24`. Duplicate shortcuts are rejected before settings are saved.

## Typography cleanup

The cleanup mode can normalize:

* dashes
* quotes
* hyphens
* spaces
* short words with non-breaking spaces
* prose punctuation spacing without changing structured numeric values such as decimals, versions, IPv4-like values, times and ratios
* explicit Russian phone numbers beginning with `+7` or `8`
* email whitespace/domain casing while preserving the local-part casing
* optional emoji removal while preserving ordinary typographic symbols such as check marks, stars and arrows
* symbols such as ©, ® and ™
* ellipsis
* numbers and markers such as № and §

Phone normalization is intentionally Russian-specific. It only rewrites explicit Russian forms beginning with `+7` or a leading `8`; unprefixed digit groups and other international formats are left unchanged. The persisted configuration key remains `FixPhones` for backward compatibility.

Emoji removal is disabled for new and reset configurations. Enable `RemoveEmoji=1` in Settings or `awful-cases.ini` when that destructive cleanup is wanted. Existing configuration files that already contain `RemoveEmoji=1` keep that behavior.

Protected fragments are restored after cleanup. URL/domain/email/path/code protection also applies to sentence typography so sentence capitalization does not rewrite structured fragments internally.

## Safety

Awful Cases temporarily uses the clipboard only to capture the currently selected text. The previous `ClipboardAll()` contents are restored before the transformed text is inserted.

Replacement text is sent with AutoHotkey `SendText` instead of placing transformed text on the clipboard and racing a delayed clipboard restore against the target application's paste handling. This favors predictable clipboard preservation; very large replacements can therefore be slower than a clipboard paste.

URLs, domains, email addresses, file paths and inline/fenced code are protected from unrelated typography rules.

## Configuration

Settings are stored in `awful-cases.ini`.

The file must be placed next to `awful-cases.exe` or `awful-cases.ahk`.

The Settings dialog's Reset button stages default values in the UI. Persistent settings change only after Save. The tray command `Reset to defaults` remains an explicit immediate reset.

## Development

Run the Windows test suite with:

```powershell
pwsh -File tests/repo-contract.ps1
pwsh -File tests/package-contract.ps1
pwsh -File tests/release-contract.ps1
pwsh -File tools/test.ps1
```

Build the portable Windows x64 package with:

```powershell
pwsh -File tools/package.ps1
```

The packager uses pinned, SHA-256-verified AutoHotkey and Ahk2Exe archives and writes versioned artifacts plus `SHA256SUMS.txt` to `dist/`. See [`docs/PACKAGING.md`](docs/PACKAGING.md) for the package contract, safe output handling, and unsigned/non-installer boundary.

CI runs repository/package/release consistency contracts and AutoHotkey regression tests on Windows. Its package job compiles and validates the same portable package but does not publish a GitHub Release.

A separate manually dispatched Release workflow is defined for publication. It requires exact repository `VERSION`, explicit real desktop-smoke confirmation, and a non-empty evidence note. It builds/verifies under read-only permissions, hands the verified candidate to a narrowly write-scoped publish job, creates a draft Release, downloads and verifies the uploaded assets, and only then publishes it. See [`docs/RELEASING.md`](docs/RELEASING.md).

Desktop integration checks and the release gate are documented in [`docs/TESTING.md`](docs/TESTING.md). Use that matrix for clipboard/input changes and before releases rather than treating headless CI as proof of compatibility with every Windows editor.

Pure text transformations live in `app/lib/text-transforms.ahk`; Windows integration remains in `app/awful-cases.ahk`.

## Files

| File                          | Purpose                                      |
| ----------------------------- | -------------------------------------------- |
| `app/awful-cases.ahk`         | Windows integration / application entry     |
| `app/lib/text-transforms.ahk` | pure text transformation core                |
| `app/awful-cases.ini`         | hotkeys and cleanup settings                 |
| `app/awful-cases.ico`         | app icon                                     |
| `tools/package.ps1`           | canonical Windows portable packager          |
| `tests/`                      | regression and repository/package/release contracts |
| `docs/PACKAGING.md`           | package inputs, outputs and security boundary|
| `docs/RELEASING.md`           | guarded GitHub Release procedure             |
| `docs/TESTING.md`             | desktop smoke matrix and release gate       |
| `.github/workflows/release.yml` | manual verified release publication        |
| `docs/index.html`             | checked-in GitHub Pages project/trainer page |

## Requirements

Windows.

AutoHotkey v2 is required only when running the `.ahk` source file directly. PowerShell 7 is required for the canonical packaging command.

## Distribution status

The repository is capable of building and verifying the portable Windows package. A CI/package artifact is not a public application release. Until a real GitHub Release exists, the source ZIP remains the only repository download linked at the top of this README.

Current portable builds are unsigned and are not installers. Windows may therefore show SmartScreen or reputation warnings.

## License and rights

Source code is licensed under the MIT License.

The Awful Cases name, icon, visual identity and branding assets are copyright Ivan Krushinsky and are not licensed for reuse as branding assets.

## Author

Ivan Krushinski / looksawful

https://looksawful.ru