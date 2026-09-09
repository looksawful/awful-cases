# Awful Cases testing and release gate

Awful Cases has two verification layers:

1. automated repository and AutoHotkey tests, which run locally and in GitHub Actions;
2. a short Windows desktop smoke test for behavior that depends on the foreground application, selection, keyboard input, and clipboard formats.

CI is intentionally verification-only. It must not rewrite or push application source as part of ordinary development.

## Automated gate

From the repository root on Windows:

```powershell
pwsh -File tests/repo-contract.ps1
pwsh -File tools/test.ps1
```

`tools/test.ps1` requires AutoHotkey v2. Pass a non-standard executable explicitly when needed:

```powershell
pwsh -File tools/test.ps1 -AutoHotkeyPath "C:\path\to\AutoHotkey64.exe"
```

GitHub Actions runs the same repository contracts and AutoHotkey suite with pinned AutoHotkey v2.0.27 and verifies the downloaded archive SHA-256 before execution.

## Windows desktop smoke test

Run this matrix after changes to `TransformSelectedText()`, hotkeys, clipboard handling, `SendText`, selection capture, or before a release.

Use a short sample such as:

```text
Привет,world. User.Name@example.com v2.0.1 3.14 ✓ 😀
```

Also prepare a large plain-text sample between roughly 10 KB and 50 KB.

Before each test, place unrelated content on the clipboard. At least once use non-text or rich clipboard data, for example an image copied from Paint or formatted text copied from a rich-text editor.

| Target | Minimum scenario | Verify |
| --- | --- | --- |
| Windows Notepad | select normal RU/EN text and run case + lint actions | transformed once; no truncation/duplication; clipboard unchanged |
| Browser textarea | run a transform in a normal `<textarea>` | replacement lands in the selected range; focus stays in the field; clipboard unchanged |
| Browser contenteditable | run a transform in an editable rich web field when available | no duplicate insertion; selection is replaced; clipboard unchanged |
| VS Code | transform prose/plain text in an editor tab | exact replacement; no stuck Ctrl/Alt/Shift state; clipboard unchanged |
| Word or LibreOffice Writer | transform a selected sentence | selected text is replaced once; surrounding document remains intact; clipboard content is restored |
| Cyrillic text | run Upper, Lower and Toggle on Cyrillic text | case transforms are correct |
| Large 10–50 KB selection | run a simple case transform | complete insertion; no truncation or duplicated suffix/prefix; acceptable interactive behavior |
| Non-text clipboard | copy an image or rich content, transform selected text elsewhere | original clipboard payload can still be pasted afterward |
| No selection | invoke a transform with only a caret | document remains unchanged; existing clipboard remains usable |

For every target also confirm that no modifier key appears stuck after the shortcut completes. A quick check is to type ordinary text immediately after the operation.

## Release gate

Do not tag or publish a release until all items below are true:

- working tree / release commit is based on current `main`;
- GitHub CI is green on the exact release commit;
- `pwsh -File tests/repo-contract.ps1` passes;
- `pwsh -File tools/test.ps1` passes with AutoHotkey v2;
- the desktop smoke matrix above passes for the areas affected by the release; run the full matrix for changes to clipboard/input integration;
- `VERSION` equals `AppVersion`;
- `CHANGELOG.md` contains the released version and accurately describes user-visible changes;
- `app/awful-cases.ini`, `GetDefaultConfig()`, and `GetDefaultFeatureState()` remain synchronized through repository contracts;
- README/settings documentation matches the actual behavior;
- no temporary one-shot workflow or source-patching automation is present in `.github/workflows/`.

## When a smoke check fails

Record the exact target application, its version when relevant, input text, action/hotkey, clipboard type, and observed result. Reduce the case before changing code. If the failure is deterministic, add an automated test for the pure or integration logic that can be isolated, then make the smallest fix. Do not replace application-specific evidence with longer arbitrary `Sleep` delays.
