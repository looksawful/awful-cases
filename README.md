# Awful Cases

[Website](https://looksawful.github.io/awful-cases/) · [Releases](https://github.com/looksawful/awful-cases/releases) · [Source ZIP](https://github.com/looksawful/awful-cases/archive/refs/heads/main.zip) · [looksawful.ru](https://looksawful.ru)

Windows tray utility for changing the case and typography of selected text.

Awful Cases works through global hotkeys. Select text in any editable field, press a shortcut, and the app replaces the selection with the transformed version.

## Windows distribution

The canonical Windows x64 packaging pipeline produces:

* `Awful-Cases-<version>-x64.exe` — standalone executable;
* `Awful-Cases-Portable-<version>-x64.zip` — portable build with a side-by-side configuration;
* `Awful-Cases-Setup-<version>-x64.exe` — per-user installer that does not require elevation;
* `SHA256SUMS.txt` — SHA-256 hashes for the three release artifacts.

The installer targets `%LOCALAPPDATA%\Programs\Awful Cases`, creates a Start Menu shortcut, and offers an optional unchecked task to start Awful Cases with Windows. The same current-user startup setting can be toggled from the application tray.

Public GitHub Releases are deliberately gated by the Windows desktop smoke matrix in `docs/TESTING.md`. The repository/source ZIP is source code, not an application installer.

Current packages are unsigned. Windows SmartScreen may therefore show a reputation/signing warning until a separate code-signing solution is introduced.

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

Awful Cases chooses the configuration location from the execution mode:

* installed compiled app: `%APPDATA%\Awful Cases\awful-cases.ini`;
* portable compiled app with `portable.flag` beside the executable: `awful-cases.ini` beside the executable;
* `.ahk` source execution: `awful-cases.ini` beside the source file.

On the first installed run, if AppData has no configuration but a legacy side-by-side `awful-cases.ini` exists beside the executable, Awful Cases copies that configuration into AppData before starting.

The Settings dialog's Reset button stages default values in the UI. Persistent settings change only after Save. The tray command `Reset to defaults` remains an explicit immediate reset.

## Development

Run the Windows test suite with:

```powershell
pwsh -File tests/repo-contract.ps1
pwsh -File tools/test.ps1
```

Build all release-shaped Windows artifacts with:

```powershell
pwsh -File tools/package.ps1
```

The package command downloads only the pinned official AutoHotkey, Ahk2Exe and Inno Setup tool versions defined by the packaging contract and verifies each download with SHA-256 before execution. Output is written to `dist/`.

CI runs repository consistency contracts and AutoHotkey regression tests on Windows using pinned AutoHotkey v2.0.27 with SHA-256 verification. A separate CI package job builds the Windows artifacts for inspection but does not publish a GitHub Release.

Desktop integration checks and the release gate are documented in [`docs/TESTING.md`](docs/TESTING.md). Use that matrix for clipboard/input changes and before releases rather than treating headless CI as proof of compatibility with every Windows editor.

Pure text transformations live in `app/lib/text-transforms.ahk`; Windows integration remains in `app/awful-cases.ahk`.

## Files

| File                          | Purpose                                      |
| ----------------------------- | -------------------------------------------- |
| `app/awful-cases.ahk`         | Windows integration / application entry     |
| `app/lib/text-transforms.ahk` | pure text transformation core                |
| `app/lib/app-paths.ahk`       | installed/portable config path selection     |
| `app/awful-cases.ini`         | default hotkeys and cleanup settings         |
| `app/awful-cases.ico`         | app icon                                     |
| `installer/awful-cases.iss`   | per-user Inno Setup definition               |
| `tools/build.ps1`             | explicit Ahk2Exe build wrapper               |
| `tools/package.ps1`           | pinned Windows package pipeline              |
| `tests/`                      | regression and repository/package contracts |
| `docs/TESTING.md`             | desktop smoke matrix and release gate       |
| `docs/index.html`             | checked-in GitHub Pages project/trainer page |

## Requirements

Windows 10/11 x64 for packaged releases.

The compiled executable and installer do not require a separate AutoHotkey installation. AutoHotkey v2 is required only when running the `.ahk` source file directly.

## License and rights

Source code is licensed under the MIT License.

The Awful Cases name, icon, visual identity and branding assets are copyright Ivan Krushinsky and are not licensed for reuse as branding assets.

## Author

Ivan Krushinski / looksawful

https://looksawful.ru
