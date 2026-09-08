# Development

## Environment

Awful Cases is developed and functionally tested on Windows.

Required tools:

- AutoHotkey v2.0.x
- PowerShell 7+
- Git

The CI workflow pins AutoHotkey 2.0.27 for syntax validation. The application currently declares `#Requires AutoHotkey v2.0`, so do not move CI to the 2.1 alpha line without an explicit compatibility decision.

## Run from source

From PowerShell, with AutoHotkey v2 installed:

```powershell
& "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" .\app\awful-cases.ahk
```

If AutoHotkey is registered for `.ahk` files, launching `app\awful-cases.ahk` directly is also sufficient.

## Automated checks

Run the dependency-free repository contract test:

```powershell
pwsh -File .\tests\repo-contract.ps1
```

It currently verifies:

- required source/release files exist
- `VERSION` is a simple `x.y.z` value
- `VERSION` matches `AppVersion`
- `CHANGELOG.md` contains the current version
- the checked-in INI matches `GetDefaultConfig()`
- default hotkeys exist, are unique and belong to the allowed-key set
- the AHK v2 requirement is explicit
- README documents the configuration file and AutoHotkey v2 requirement

GitHub Actions additionally downloads the official AutoHotkey 2.0.27 portable archive and executes:

```text
AutoHotkey64.exe /ErrorStdOut=UTF-8 /Validate app\awful-cases.ahk
```

That catches load-time syntax errors using the real AutoHotkey interpreter on a Windows runner.

## Manual Windows smoke matrix

Automated syntax and repository checks do not prove global hotkeys, GUI interaction or clipboard handoff. Before merging changes in those areas, run this matrix on Windows.

| Area | Test | Expected result |
| --- | --- | --- |
| Startup | Launch `app\awful-cases.ahk` | One tray instance starts without an error dialog |
| Upper | Select mixed-case text and trigger Upper | Selection is replaced with uppercase text |
| Lower | Select mixed-case text and trigger Lower | Selection is replaced with lowercase text |
| Toggle | Select `AbC` and trigger Toggle | Selection becomes `aBc` |
| Title | Select a multi-word phrase and trigger Title | Word starts are capitalized according to current rule |
| Lint | Run typography cleanup on representative RU/EN text | Enabled cleanup rules apply; protected fragments survive |
| Sentence | Run sentence typography on multi-sentence text | Sentence starts are capitalized without breaking decimals |
| Clipboard | Put distinctive text/image data on the clipboard before a transform | Original clipboard data is restored after the transform |
| No selection | Trigger an action with no selectable text | No destructive paste occurs; clipboard is restored |
| URL protection | Lint text containing `https://example.com/a-b?q=x` | URL remains intact |
| Email protection | Lint text containing a valid compact email | Email remains protected after normalization stage |
| Path protection | Lint text containing `C:\Work\file-name.txt` and a UNC path | Paths remain intact |
| Code protection | Lint inline backtick code and fenced code | Protected code is restored unchanged |
| Settings round-trip | Open Settings and Save without editing | Existing valid configuration is unchanged |
| Language | Switch RU/EN and reopen settings | Same controls and behavior are available in both modes |
| Large text | Transform a large multi-line selection | Paste completes and original clipboard is restored |
| Slow target | Test in a slow/remote editor when available | Transformed text, not the restored old clipboard, is pasted |

For clipboard-sensitive changes, repeat the core transform in Notepad, a Chromium editable field and an Office-style rich text editor when available.

## Architecture map

The current 0.1.0 application is intentionally small but monolithic: `app/awful-cases.ahk` owns startup/tray behavior, configuration, hotkeys, settings GUI, clipboard integration and all text transformation rules.

Recommended extraction order when feature work justifies it:

1. pure case/typography transforms
2. configuration and hotkey schema
3. clipboard adapter
4. settings GUI and tray/startup shell

The first goal is testability, not achieving a ceremonial number of files.

## Known review risks

- The accepted hotkey set and the settings GUI choices are not currently the same set.
- Clipboard restoration uses fixed sleeps after paste, so slow paste consumers can race restoration.
- Pure transformation code cannot yet be executed as an isolated automated test suite because application startup side effects live in the same file.
- `docs/index.html` is a large published artifact with no source/build pipeline documented in this repository.

These should be tracked as GitHub issues rather than silently normalized into the codebase.