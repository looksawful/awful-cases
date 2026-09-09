---
name: awful-cases
description: Use when reviewing, testing, fixing, or extending the Awful Cases AutoHotkey v2 application, especially typography transforms, global hotkeys, configuration, clipboard behavior, and release checks.
---

# Awful Cases

## Start here

Before creating new work, inspect existing open/recent PRs, issues, and relevant branches for the same area. Read `AGENTS.md`, `README.md`, `app/awful-cases.ahk`, `app/lib/text-transforms.ahk`, and relevant project/runbook documentation available through the connected workspace. Treat the application/core source as authoritative for current behavior and the issue tracker as authoritative for known unresolved defects.

Do not create a parallel issue, PR, plan, or documentation page when an existing one already has the correct scope. Extend or supersede it explicitly.

## Workflow

1. Identify whether the change affects pure text transforms, settings/hotkeys, clipboard/keyboard integration, UI, or the public docs page.
2. Reproduce the behavior with the smallest input possible.
3. Add or update a regression test before changing application behavior.
4. Keep deterministic transformations in `app/lib/text-transforms.ahk`; keep Windows side effects in `app/awful-cases.ahk`.
5. Make the smallest implementation change that resolves the reproduced defect.
6. Run `pwsh -File tests/repo-contract.ps1` and `pwsh -File tools/test.ps1`.
7. Review the diff specifically for structured-text corruption, clipboard preservation, config drift, and accidental edits to `docs/index.html`.
8. If clipboard/input behavior changed, execute the relevant Windows desktop smoke matrix in `docs/TESTING.md` before release.
9. For releases, follow the full release gate in `docs/TESTING.md` and verify `VERSION`, `AppVersion`, README behavior, changelog, and packaged defaults agree.

## CI boundary

GitHub Actions verify code. Ordinary development CI must not edit application source and push those edits back to a branch. Do not use one-shot source-patching workflows as a substitute for making a normal branch change. Keep CI permissions read-only unless a separately scoped deployment/release workflow genuinely requires write access.

## Text-transform safety

Typography cleanup is destructive by nature, so assume every broad regex is guilty until proven otherwise. Test punctuation rules against decimals, version numbers, IP addresses, URLs, email addresses, paths, code, dates, times, ratios, ranges, and ordinary Russian/English prose as applicable.

Protected fragments must round-trip exactly after any explicitly enabled normalization that intentionally runs before protection. `FixEmails` normalizes email text before the protection pass. Protection rules may overlap, so restoration must remain safe when one protected fragment contains another candidate fragment.

## Clipboard and insertion

The clipboard is used only to capture the selected text. Restore the user's `ClipboardAll()` before sending the replacement text. Do not reintroduce a transformed-text clipboard paste followed by a fixed delay, because restoration can race slow paste consumers. Current output uses `SendText` deliberately for correctness.

Headless CI cannot prove compatibility with every foreground Windows editor. Use `docs/TESTING.md` for Notepad, browser editable fields, VS Code, rich-text editors, large selections, non-text clipboard payloads, and no-selection behavior.

## Hotkeys and settings

The user-configurable final key and the GUI choices share `AllowedFinalHotkeyKeys`. Validate duplicate shortcuts before registering or saving them. Do not silently swallow a configuration error when the user can reasonably correct it. Settings Reset stages defaults in the GUI and persistence happens only on Save.

## Architecture

The side-effect boundary already exists:

- `app/lib/text-transforms.ahk`: pure/configuration-parameterized transforms;
- `app/awful-cases.ahk`: config, tray, GUI, hotkeys, clipboard capture and text insertion.

Preserve this boundary. Do not copy transform implementations back into the Windows shell and do not move Windows state into the pure core.

## Done criteria

A change is done only when the affected behavior has an automated regression/contract test where practical, Windows CI passes on the final commit, known safety invariants still hold, and documentation is updated when behavior or architecture changes. A release is not done until the applicable desktop smoke checks in `docs/TESTING.md` also pass.
