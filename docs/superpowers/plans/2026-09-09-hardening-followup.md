# Awful Cases Hardening Follow-up Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish the post-audit hardening work by making tests trustworthy and side-effect-minimal, making destructive cleanup safer by default, clarifying Russian phone normalization, and adding a reproducible desktop/release verification gate.

**Architecture:** Keep the existing split introduced in PR #17: `app/awful-cases.ahk` owns Windows integration and `app/lib/text-transforms.ahk` owns pure/configuration-parameterized transforms. Do not rewrite the application or introduce a new runtime. Changes are split into independently reviewable PR-sized tasks and must keep existing user INI files compatible.

**Tech Stack:** AutoHotkey v2.0.27, PowerShell 7, GitHub Actions `windows-latest`, Markdown.

**Spec:** This plan implements the follow-up recommendations from the September 9, 2026 post-audit review of `looksawful/awful-cases`.

## Global Constraints

- Windows remains the target platform.
- AutoHotkey v2 remains the application runtime.
- Do not introduce Node, Python, .NET, or a build framework for application logic.
- Do not mutate production code from GitHub Actions. CI verifies only.
- Existing user `awful-cases.ini` files must remain readable.
- Text changes must be regression-tested before behavior is changed.
- `docs/index.html` is unrelated to this hardening pass and must not be reformatted or edited.
- Keep `VERSION` and `AppVersion` unchanged unless this work is explicitly released as a new version.

---

### Task 1: Make the AutoHotkey test harness strict, shared, and side-effect-minimal

**Files:**
- Create: `tests/lib/assert.ahk`
- Modify: `tests/text-core.ahk`
- Modify: `tests/text-transforms.ahk`
- Modify: `tests/hotkey-validation.ahk`
- Modify: `tests/settings-reset.ahk`
- Verify: `tools/test.ps1`

**Interfaces:**
- Produces: `TestValuesEqual(actual, expected)`, `AssertEqual(name, actual, expected)`, `AssertTrue(name, value)`, `AssertFalse(name, value)`, `FinishTests(label)`.
- Pure transform tests include `app/lib/text-transforms.ahk` directly.
- Windows integration tests may include `app/awful-cases.ahk` only when the behavior under test actually belongs to the shell.

- [ ] **Step 1: Add a shared assertion helper using case-sensitive `==`.**

Create `tests/lib/assert.ahk` with one global failure counter and strict comparison. Add `AssertFalse` so the comparator can test itself.

- [ ] **Step 2: Add a harness sanity assertion.**

Add a passing test proving `TestValuesEqual("A", "a")` is false and `TestValuesEqual("A", "A")` is true. This prevents a future accidental return to case-insensitive equality.

- [ ] **Step 3: Make transform regression tests load the pure core directly.**

Change `tests/text-transforms.ahk` from `#Include ..\\app\\awful-cases.ahk` to `#Include ..\\app\\lib\\text-transforms.ahk`. Move hotkey-only assertions out of this file into `tests/hotkey-validation.ahk`.

- [ ] **Step 4: Replace duplicated assertion implementations.**

Update the four AHK test files to include `tests/lib/assert.ahk` and remove local copies of assertion functions/failure handling.

- [ ] **Step 5: Run the complete AutoHotkey suite.**

Run: `pwsh -File tools/test.ps1`
Expected: every `tests/*.ahk` file exits 0; transform tests do not initialize tray, hotkeys, clipboard, GUI, or configuration files.

- [ ] **Step 6: Run repository contracts.**

Run: `pwsh -File tests/repo-contract.ps1`
Expected: PASS.

- [ ] **Step 7: Commit as one test-infrastructure change.**

Commit message: `test: harden AutoHotkey test harness`

---

### Task 2: Make emoji removal opt-in for new and reset configurations

**Files:**
- Modify: `app/lib/text-transforms.ahk`
- Modify: `app/awful-cases.ahk`
- Modify: `app/awful-cases.ini`
- Modify: `tests/text-transforms.ahk`
- Modify: `tests/repo-contract.ps1`
- Modify: `README.md`
- Modify: `CHANGELOG.md`

**Interfaces:**
- `RemoveEmoji=0` becomes the default for new/reset configuration.
- Explicit existing `RemoveEmoji=1` remains honored.
- `RemoveEmoji(text)` itself remains available and keeps its regression coverage.

- [ ] **Step 1: Add failing default-behavior coverage.**

Test a default `LintText("hello 😀 ✓")` call and expect emoji to remain when no feature override enables removal. Add a second test with an explicit feature map setting `RemoveEmoji` to `1` and expect the emoji to be removed while `✓` remains.

- [ ] **Step 2: Change the authoritative transform default.**

Set `GetDefaultFeatureState()["RemoveEmoji"]` to `0`.

- [ ] **Step 3: Synchronize embedded and checked-in defaults.**

Set `RemoveEmoji=0` in `GetDefaultConfig()` and `app/awful-cases.ini`.

- [ ] **Step 4: Stop the settings GUI from assuming every feature defaults to 1.**

In `ShowSettingsGui()`, obtain `featureDefaults := GetDefaultFeatureState()` once and use the corresponding value as the `IniRead` fallback for each feature.

- [ ] **Step 5: Make Settings Reset use actual feature defaults.**

In `ResetSettingsInPlace()`, set each checkbox from `GetDefaultFeatureState()` rather than unconditionally assigning `1`.

- [ ] **Step 6: Extend repository contracts.**

Parse `[Features]` from `app/awful-cases.ini` and verify every checked-in feature default agrees with `GetDefaultFeatureState()` or with a deliberately maintained contract extraction. At minimum assert `RemoveEmoji=0` and that the embedded INI matches the checked-in INI.

- [ ] **Step 7: Document the compatibility behavior.**

README: emoji removal is opt-in for new/reset configs; existing INI values are preserved. CHANGELOG: record the safer default.

- [ ] **Step 8: Run `tools/test.ps1` and `tests/repo-contract.ps1`.**
Expected: PASS.

- [ ] **Step 9: Commit.**

Commit message: `fix: make emoji removal opt-in by default`

---

### Task 3: Make Russian phone normalization explicit without breaking existing INI files

**Files:**
- Modify: `app/awful-cases.ahk`
- Modify: `app/lib/text-transforms.ahk` only if tests expose a semantic gap
- Modify: `tests/text-transforms.ahk`
- Modify: `README.md`
- Modify: `CHANGELOG.md`

**Interfaces:**
- Keep the persisted key name `FixPhones` for backward compatibility.
- User-facing label becomes `Нормализовать российские телефоны` / `Normalize Russian phones`.
- Only explicit `+7` and leading `8` forms are normalized.

- [ ] **Step 1: Expand negative regression examples.**

Add representative non-Russian/ambiguous forms such as `+1 415 555 2671`, `020 7946 0958`, and unprefixed `999 123 45 67`; all must remain unchanged.

- [ ] **Step 2: Keep positive Russian cases.**

Retain tests for `+7 999 123 45 67` and `8 (999) 123-45-67` -> `+7 (999) 123-45-67`.

- [ ] **Step 3: Rename only the GUI copy, not the INI key.**

Change the RU/EN settings label while retaining `FixPhones` internally.

- [ ] **Step 4: Update README wording.**

State explicitly that this feature is Russian-specific and requires `+7` or leading `8`.

- [ ] **Step 5: Run all tests and contracts.**
Expected: PASS.

- [ ] **Step 6: Commit.**

Commit message: `docs: clarify Russian phone normalization`

---

### Task 4: Add a desktop smoke test and release gate instead of pretending CI can validate every Windows target

**Files:**
- Create: `docs/TESTING.md`
- Modify: `AGENTS.md`
- Modify: `skills/awful-cases/SKILL.md`
- Modify: `README.md`
- Modify: `tests/repo-contract.ps1`

**Interfaces:**
- Automated gate remains `pwsh -File tests/repo-contract.ps1` plus `pwsh -File tools/test.ps1`.
- Manual gate is a short Windows desktop matrix for clipboard preservation and `SendText` compatibility.

- [ ] **Step 1: Define the manual matrix.**

Document checks for Notepad, browser textarea/contenteditable, VS Code, Word or LibreOffice Writer, Cyrillic text, 10-50 KB selections, non-text clipboard content, and no-selection behavior.

For every target verify:
1. selected text is transformed once;
2. original clipboard content is preserved;
3. no text is duplicated or truncated;
4. focus stays in the target;
5. no stray modifier keys remain held.

- [ ] **Step 2: Define the release gate.**

Before tag/release require: clean `main`, green repository contracts, green AHK suite, manual smoke matrix, `VERSION == AppVersion`, changelog section, checked-in defaults synchronized.

- [ ] **Step 3: Add agent discovery rules.**

AGENTS and repo skill must require checking existing PRs/issues/branches and relevant Notion/project documentation before creating duplicate work. GitHub Actions are verification-only; no workflow may patch and push application source as part of ordinary development.

- [ ] **Step 4: Make the testing document discoverable.**

Link `docs/TESTING.md` from README and AGENTS.

- [ ] **Step 5: Add lightweight repository contracts.**

Assert `docs/TESTING.md` exists and CI workflow permissions do not grant `contents: write`. Do not attempt to parse every possible GitHub Actions permission rule.

- [ ] **Step 6: Run automated gates.**
Expected: PASS.

- [ ] **Step 7: Commit.**

Commit message: `docs: add desktop smoke and release gate`

---

### Task 5: Final review and synchronization

**Files:**
- Review all changed files from Tasks 1-4
- Update Notion Awful Cases engineering/runbook pages after GitHub changes are merged

- [ ] **Step 1: Verify each PR-sized task independently.**

Do not merge a task with failing Windows CI.

- [ ] **Step 2: Review for compatibility.**

Confirm existing INI keys remain accepted, especially `FixPhones` and explicit `RemoveEmoji=1`.

- [ ] **Step 3: Verify no temporary mutation workflow entered `main`.**

`main/.github/workflows/` should contain ordinary verification/deployment workflows only; no one-shot source-patching workflow.

- [ ] **Step 4: Synchronize Notion.**

Update the Awful Cases audit/runbook with the final architecture, commands, safer defaults, Russian-phone semantics, release gate, and links to merged PRs. The repository remains the engineering source of truth; Notion is the overview/runbook mirror.

- [ ] **Step 5: Final clean-main verification.**

Run the same repository contracts and AHK test suite against the final `main` commit after all merges.
