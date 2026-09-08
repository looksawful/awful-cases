# Awful Cases

[Website](https://looksawful.github.io/awful-cases/) · [Download ZIP](https://github.com/looksawful/awful-cases/archive/refs/heads/main.zip) · [looksawful.ru](https://looksawful.ru)

Windows tray utility for changing the case and typography of selected text.

Awful Cases works through global hotkeys. Select text in any editable field, press a shortcut, and the app replaces the selection with the transformed version.

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
* emoji while preserving ordinary typographic symbols such as check marks, stars and arrows
* symbols such as ©, ® and ™
* ellipsis
* numbers and markers such as № and §

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
pwsh -File tools/test.ps1
```

CI runs repository consistency contracts and AutoHotkey regression tests on Windows using pinned AutoHotkey v2.0.27 with SHA-256 verification.

Pure text transformations live in `app/lib/text-transforms.ahk`; Windows integration remains in `app/awful-cases.ahk`.

## Files

| File                          | Purpose                                      |
| ----------------------------- | -------------------------------------------- |
| `app/awful-cases.ahk`         | Windows integration / application entry     |
| `app/lib/text-transforms.ahk` | pure text transformation core                |
| `app/awful-cases.ini`         | hotkeys and cleanup settings                 |
| `app/awful-cases.ico`         | app icon                                     |
| `tests/`                      | regression and repository contract tests    |
| `docs/index.html`             | checked-in GitHub Pages project/trainer page |

## Requirements

Windows.

AutoHotkey v2 is required only when running the `.ahk` source file directly.

## License and rights

Source code is licensed under the MIT License.

The Awful Cases name, icon, visual identity and branding assets are copyright Ivan Krushinsky and are not licensed for reuse as branding assets.

## Author

Ivan Krushinski / looksawful

https://looksawful.ru
