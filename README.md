# Awful Cases

Windows tray utility for changing the case and typography of selected text.

Awful Cases works through global hotkeys. Select text in any editable field, press a shortcut, and the app replaces the selection with the transformed version.

## Features

* Uppercase
* Lowercase
* Toggle case
* Title case
* Typography cleanup
* Sentence-level typography cleanup
* URL, email, file path and inline code protection
* Clipboard restoration after each transform
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

## Typography cleanup

The cleanup mode can normalize:

* dashes
* quotes
* hyphens
* spaces
* short words with non-breaking spaces
* punctuation spacing
* phone numbers
* email text
* symbols such as ©, ® and ™
* ellipsis
* numbers and markers such as № and §

Protected fragments are restored after cleanup.

## Safety

Awful Cases temporarily uses the clipboard to copy selected text and paste the transformed result.

The previous clipboard content is restored after the transform.

URLs, email addresses, file paths and inline code are protected before typography rules are applied.

## Configuration

Settings are stored in `awful-cases.ini`.

The file must be placed next to `awful-cases.exe` or `awful-cases.ahk`.

## Files

| File              | Purpose                      |
| ----------------- | ---------------------------- |
| `awful-cases.exe` | compiled app                 |
| `awful-cases.ahk` | AutoHotkey v2 source         |
| `awful-cases.ini` | hotkeys and cleanup settings |
| `awful-cases.ico` | app icon                     |

## Requirements

Windows.

AutoHotkey v2 is required only when running the `.ahk` source file directly.

## License and rights

Source code is licensed under the MIT License.

The Awful Cases name, icon, visual identity and branding assets are copyright Ivan Krushinsky and are not licensed for reuse as branding assets.

## Author

Ivan Krushinski / looksawful

https://looksawful.ru

