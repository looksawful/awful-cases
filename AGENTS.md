# Awful Cases agent guide

## Scope

Awful Cases is a Windows AutoHotkey v2 tray utility. The production source is `app/awful-cases.ahk`; default settings are in `app/awful-cases.ini`; the public project page is the large self-contained `docs/index.html`.

## Read before changing code

1. Read `README.md` and `app/awful-cases.ahk`.
2. Check open GitHub issues for known text-normalization edge cases before touching typography rules.
3. Run `pwsh -File tools/test.ps1` before and after a change.
4. Keep the change narrowly scoped. Do not mix website work in `docs/index.html` with application behavior unless the task explicitly requires both.

## Behavioral invariants

- The clipboard must be restored after every transform, including error paths.
- Protected URLs, file paths, fenced code, and inline code must round-trip byte-for-byte through typography cleanup.
- Email text may change only through the explicit `FixEmails` normalization step; after that step, protection must prevent unrelated typography rules from changing it further.
- A typography rule must not silently change machine-readable values such as decimals, versions, IP addresses, identifiers, paths, URLs, or code.
- Existing global hotkeys must keep working unless the task explicitly changes them.
- New text-normalization behavior requires a regression test.
- AutoHotkey v2 syntax only; do not introduce v1 compatibility code.

## Architecture map

The current `app/awful-cases.ahk` contains four concerns in one file:

- startup, tray, hotkey registration and settings I/O;
- settings GUI;
- clipboard integration;
- pure and mostly-pure text transformations.

Prefer moving toward testable pure transformation modules, but do not perform a broad split as a drive-by refactor. Extract code only when a feature or fix benefits from the boundary and add tests first.

## Testing

Run:

```powershell
pwsh -File tools/test.ps1
```

The test script includes the real application source and executes characterization tests under AutoHotkey v2. Tests should be deterministic and must not depend on an interactive editor window or simulated clipboard selection.

CI runs the same test file on `windows-latest`.

## Review checklist

- Does the change preserve clipboard restoration?
- Can punctuation or whitespace rules touch structured data accidentally?
- Are protected fragments restored exactly after any explicitly enabled pre-protection normalization?
- Are RU/EN UI behavior and configuration still coherent?
- Are hotkeys unique and representable in both config and GUI?
- Is every bug fix covered by a regression test?
- Is `VERSION` consistent with `AppVersion` when releasing?

## Files to treat carefully

- `docs/index.html` is a generated/self-contained public page over 1 MB. Do not reformat it or make unrelated edits.
- `app/awful-cases.ini` and `GetDefaultConfig()` currently duplicate defaults. Keep them synchronized until that debt is removed.
- `VERSION` and `AppVersion` currently duplicate the release version. Keep them synchronized until that debt is removed.
