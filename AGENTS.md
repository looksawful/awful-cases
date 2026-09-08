# Awful Cases agent guide

## Scope

Awful Cases is a Windows AutoHotkey v2 tray utility. The Windows integration entry point is `app/awful-cases.ahk`; pure text transformations live in `app/lib/text-transforms.ahk`; default settings are in `app/awful-cases.ini`; the public project page is the large self-contained `docs/index.html`.

## Read before changing code

1. Read `README.md`, `app/awful-cases.ahk`, and the relevant functions in `app/lib/text-transforms.ahk`.
2. Check open GitHub issues for known text-normalization edge cases before touching typography rules.
3. Run `pwsh -File tools/test.ps1` before and after a change.
4. Keep the change narrowly scoped. Do not mix website work in `docs/index.html` with application behavior unless the task explicitly requires both.
5. Read `docs/README.md` before changing the published page.

## Behavioral invariants

- The clipboard must be restored after every transform, including error paths.
- Protected URLs, file paths, fenced code, and inline code must round-trip byte-for-byte through typography cleanup.
- Email text may change only through the explicit `FixEmails` normalization step; after that step, protection must prevent unrelated typography rules from changing it further.
- A typography rule must not silently change machine-readable values such as decimals, versions, IP addresses, identifiers, paths, URLs, or code.
- Existing global hotkeys must keep working unless the task explicitly changes them.
- New text-normalization behavior requires a regression test.
- AutoHotkey v2 syntax only; do not introduce v1 compatibility code.

## Architecture map

The code is intentionally split at the side-effect boundary:

- `app/awful-cases.ahk`: startup, tray, hotkey registration, settings I/O and GUI, clipboard/keyboard integration;
- `app/lib/text-transforms.ahk`: pure or configuration-parameterized case, sentence and typography transforms;
- `tests/*.ahk`: executable regression/characterization tests;
- `tests/repo-contract.ps1`: repository-level consistency checks;
- `tools/test.ps1`: local Windows test runner.

Keep transformation logic in the pure core when it does not require Windows state. Do not move GUI, clipboard, hotkey registration, or filesystem side effects into the core merely to reduce file count.

## Testing

Run:

```powershell
pwsh -File tools/test.ps1
```

The AutoHotkey tests execute the production transform core and targeted integration helpers. Tests should be deterministic and must not depend on an interactive editor window or simulated clipboard selection unless the test is explicitly an integration/manual scenario.

CI runs repository contracts and the same AutoHotkey suite on `windows-latest`.

## Review checklist

- Does the change preserve clipboard restoration?
- Can punctuation or whitespace rules touch structured data accidentally?
- Are protected fragments restored exactly after any explicitly enabled pre-protection normalization?
- Are RU/EN UI behavior and configuration still coherent?
- Are hotkeys unique and representable in both config and GUI?
- Is every bug fix covered by a regression test?
- Is `VERSION` consistent with `AppVersion` when releasing?

## Files to treat carefully

- `docs/index.html` is a self-contained checked-in GitHub Pages artifact over 1 MB. Its original external authoring/export provenance is not recoverable from repository evidence; `docs/README.md` defines the current source-of-truth and editing policy. Do not reformat it or make unrelated edits.
- `app/awful-cases.ini` and `GetDefaultConfig()` currently duplicate defaults. Keep them synchronized until that debt is removed.
- `VERSION` and `AppVersion` currently duplicate the release version. Keep them synchronized until that debt is removed.
