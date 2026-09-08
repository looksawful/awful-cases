---
name: awful-cases
description: Use when reviewing, testing, fixing, or extending the Awful Cases AutoHotkey v2 application, especially typography transforms, global hotkeys, configuration, clipboard behavior, and release checks.
---

# Awful Cases

## Start here

Read `AGENTS.md`, `README.md`, `app/awful-cases.ahk`, and relevant open issues. Treat the application source as authoritative for current behavior and the issue tracker as authoritative for known defects that have not been fixed yet.

## Workflow

1. Identify whether the change affects text transforms, settings/hotkeys, clipboard integration, UI, or the public docs page.
2. Reproduce the behavior with the smallest text sample possible.
3. Add or update a regression test before changing a text transformation.
4. Make the smallest behavior-preserving implementation change.
5. Run `pwsh -File tools/test.ps1`.
6. Review the diff specifically for structured-text corruption, clipboard restoration, config drift, and accidental edits to `docs/index.html`.
7. For releases, verify `VERSION`, `AppVersion`, README behavior, and packaged defaults agree.

## Text-transform safety

Typography cleanup is destructive by nature, so assume every broad regex is guilty until proven otherwise. Test punctuation rules against decimals, version numbers, IP addresses, URLs, email addresses, paths, code, dates, times, ranges, and ordinary Russian/English prose as applicable.

Protected fragments must round-trip exactly. Do not solve a protection bug by broadly exempting arbitrary text unless the exemption has a clear grammar and tests.

## Hotkeys and settings

The user-configurable final key and the GUI choices must describe the same allowed set. Validate duplicate shortcuts before registering or saving them. Do not silently swallow a configuration error when the user can reasonably correct it.

## Architecture direction

The long-term boundary should separate pure text transformations from Windows/UI side effects. Prefer small extraction steps backed by tests rather than a one-shot rewrite of the current single-file application.

## Done criteria

A change is done only when the affected behavior has an automated test, the Windows test command passes, known safety invariants still hold, and documentation is updated if user-visible behavior changed.
