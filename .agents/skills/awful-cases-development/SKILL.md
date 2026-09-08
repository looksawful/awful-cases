# Awful Cases development

Use this playbook for changes to the Windows utility that are not specifically a release-only task or a typography-rule-only task.

## Context to load

Read, in order:

1. `AGENTS.md`
2. `README.md`
3. `VERSION`
4. the relevant region of `app/awful-cases.ahk`
5. `app/awful-cases.ini` when configuration or hotkeys are involved
6. open GitHub issues related to the code path

Do not load or rewrite the 1+ MB `docs/index.html` unless the task is explicitly about the public trainer/site.

## Workflow

1. State the exact behavior being changed and the behavior that must remain unchanged.
2. Identify whether the path touches pure text transformation, configuration, UI, hotkeys, clipboard I/O or more than one of them.
3. Prefer a minimal change. Do not use an unrelated request as an excuse to redesign the whole single-file application.
4. Add or update automated checks when the behavior can be tested without GUI interaction.
5. Run `pwsh -File tests/repo-contract.ps1`.
6. Let GitHub Actions run AutoHotkey `/Validate` on Windows.
7. If the change touches clipboard, hotkeys, GUI or selected-text replacement, execute the manual smoke matrix in `DEVELOPMENT.md`.
8. Review the diff for accidental changes to copy, shortcuts, regex scope and protected fragments.
9. Update `CHANGELOG.md` only when the change belongs to a release or the repository's release policy explicitly requires an Unreleased section.

## Architecture direction

When a task requires touching several responsibilities in `app/awful-cases.ahk`, prefer moving toward these boundaries rather than adding more coupling:

- startup/tray
- configuration/hotkey schema
- settings UI
- clipboard adapter
- pure case transforms
- pure typography transforms/protection

Do not split modules merely to make the tree look sophisticated. Extract a boundary when it enables isolated testing or removes duplicated state.