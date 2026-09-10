# Changelog

## Unreleased

## 0.2.0

- Added a canonical Windows x64 packaging pipeline that produces a standalone executable, portable ZIP, per-user Inno Setup installer and SHA-256 manifest.
- Added installed configuration storage under `%APPDATA%\Awful Cases` while preserving side-by-side source configuration and a `portable.flag` portable mode.
- Added first-run migration of a legacy side-by-side configuration into AppData for installed builds.
- Added optional current-user Windows startup integration through the tray and installer.
- Added pinned, hash-verified AutoHotkey v2.0.27, Ahk2Exe v1.1.37.02a2 and Inno Setup 7.1.0 packaging tools.
- Added read-only CI package verification and a separate manually gated GitHub Release workflow that requires explicit desktop-smoke confirmation.
- Fixed Toggle Case so Latin and Cyrillic letters actually invert case.
- Prevented typography cleanup from corrupting decimals, semantic versions, IPv4-like values, times and ratios.
- Preserved email local-part casing while normalizing domain casing.
- Restricted phone normalization to explicit Russian `+7` / leading `8` forms instead of coercing ambiguous formatted numbers.
- Clarified in Settings and documentation that phone normalization is Russian-specific while keeping the `FixPhones` INI key compatible.
- Narrowed emoji removal so ordinary typographic symbols are preserved.
- Made emoji removal opt-in for new/reset configurations while preserving existing explicit `RemoveEmoji=1` settings.
- Unified settings/runtime hotkey choices through F24 and reject duplicate shortcuts.
- Made Settings Reset non-destructive until Save.
- Protected URLs, domains, email addresses, Windows/UNC paths and code in sentence typography; added `!` and `?` sentence boundaries.
- Extracted pure text transformations into `app/lib/text-transforms.ahk`.
- Made nested fragment protection restore safely when protected patterns overlap.
- Removed the clipboard paste/restoration race by restoring the user's clipboard before inserting transformed text with `SendText`.
- Added Windows regression tests, repository contracts and pinned AutoHotkey v2.0.27 CI with archive SHA-256 verification.
- Documented `docs/index.html` provenance and editing policy.

## 0.1.0

Initial portable source release.

- Added text case transforms.
- Added typography cleanup.
- Added configurable global hotkeys.
- Added URL, email, path and inline code protection during cleanup.
- Added clipboard preservation after transforms.
- Added portable configuration file.
