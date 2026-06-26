# Awful Cases

Awful Cases is a small Windows utility for changing selected text with global hotkeys.

It can change letter case, clean typography, protect URLs, email addresses, file paths and inline code, and restore the previous clipboard content after each transform.

## Features

- Uppercase selected text.
- Lowercase selected text.
- Toggle letter case.
- Convert selected text to title case.
- Clean typography in selected text.
- Apply sentence-level typography cleanup.
- Protect URLs, email addresses, file paths and inline code during cleanup.
- Restore the previous clipboard content after each transform.
- Configure hotkeys and cleanup features through an INI file.

## Default hotkeys

All actions use `Ctrl + Alt + Shift + selected key`.

| Action | Default key | Full hotkey |
|---|---:|---|
| Uppercase | Up | Ctrl + Alt + Shift + Up |
| Lowercase | Down | Ctrl + Alt + Shift + Down |
| Toggle case | Right | Ctrl + Alt + Shift + Right |
| Title case | Left | Ctrl + Alt + Shift + Left |
| Clean typography | PgDn | Ctrl + Alt + Shift + PgDn |
| Sentence typography | Delete | Ctrl + Alt + Shift + Delete |
| Settings | Home | Ctrl + Alt + Shift + Home |

## Configuration

Awful Cases reads `awful-cases.ini` from the same folder as the script or executable.

Default configuration:

```ini
[Hotkeys]
Upper=Up
Lower=Down
Toggle=Right
Title=Left
Lint=PgDn
Sentence=Delete
Settings=Home

[Ui]
Language=ru

[Features]
FixDash=1
FixQuotes=1
FixHyphens=1
FixSpaces=1
FixShortWords=1
FixPunctuation=1
FixPhones=1
FixEmails=1
RemoveEmoji=1
ProtectCode=1
ProtectUrls=1
ProtectPaths=1
FixSymbols=1
FixEllipsis=1
FixNumbers=1
```

## Safety

Awful Cases works with selected text. It temporarily uses the clipboard to copy the selection and paste the transformed result.

The previous clipboard content is restored after each transform.

Typography cleanup protects URLs, email addresses, file paths and inline code before applying text cleanup rules.

## License and rights

Source code is licensed under the MIT License.

The Awful Cases name, icon, visual identity and branding assets are copyright Ivan Krushinsky and are not licensed for reuse as branding assets.

## Author

Ivan Krushinsky / looksawful

https://looksawful.ru
