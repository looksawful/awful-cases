# Next-stage readiness: packaging, release, and agent boundaries

This document is a dated working plan, not a second source of truth for application behavior. Current behavior remains defined by production code, executable tests, `README.md`, `AGENTS.md`, `docs/TESTING.md`, and merged GitHub history.

Related tracking issue: #26.

## Audit conclusion

Awful Cases should keep a deliberately small repository-specific agent system:

1. `AGENTS.md` — always-on policy, invariants, safety boundaries, and repository truth rules.
2. `skills/awful-cases/SKILL.md` — the single task-routing workflow for implementation, testing, Windows integration, packaging/release, and public docs.

The larger `looksawful.ru` repository benefits from many narrow skills because it spans frontend runtime, CMS, media, TypeScript, CI tiers, browser testing, deployment, and multiple protected publication surfaces. Copying that catalog into Awful Cases would add routing overhead without adding enforcement. Reuse the underlying principle instead: prose guidance must map to executable checks or explicit stop conditions where safety matters.

## Current strengths

- Pure text transformations are separated from Windows side effects.
- Clipboard output no longer relies on a paste/restore race.
- Repository contracts synchronize version/config/hotkey/default invariants.
- AutoHotkey regression tests run on Windows CI with a pinned verified AutoHotkey archive.
- Ordinary CI has read-only contents permission and does not mutate source.
- `docs/TESTING.md` correctly separates headless automation from real desktop smoke verification.
- Completed hardening work is recorded in dated plans rather than silently mixed into current behavior documentation.

## Readiness gaps

### P0 — agent/policy clarity

- [x] Explicitly define one-skill minimal agent architecture.
- [x] Clarify that Issues are authoritative for tracked defects, not exhaustive defect knowledge.
- [x] Mark agent instructions, workflows, release tooling, repository contracts, and release-gate rules as protected policy/tooling surfaces.
- [x] Add a public-reporting boundary for GitHub Issues/PRs/logs/artifacts.
- [x] Add build/release truth rules so agents cannot invent a package or installer that does not exist.

### P1 — packaging contract

No canonical Windows packaging procedure exists yet. Before implementing automated publication, decide and document:

- [ ] supported AutoHotkey v2 compiler/toolchain;
- [ ] pinned compiler/tool versions and external download integrity checks;
- [ ] exact inputs (`app/awful-cases.ahk`, transform core, icon, configuration/default behavior as applicable);
- [ ] artifact formats: portable `.exe`, ZIP, installer, or a defined combination;
- [ ] artifact naming convention;
- [ ] how `VERSION`/`AppVersion` flow into compiled/package metadata;
- [ ] whether `awful-cases.ini` ships beside the executable, is generated on first run, or both;
- [ ] checksum format and publication;
- [ ] reproducibility expectations that are realistic for the chosen toolchain;
- [ ] malware/SmartScreen/signing expectations and what the project will or will not claim without code signing.

### P1 — release implementation

Only after the packaging contract is approved:

- [ ] implement a dedicated package script with deterministic inputs and fail-closed validation;
- [ ] add package-level contract tests that do not require GUI interaction;
- [ ] add a dedicated GitHub Release workflow separate from ordinary CI;
- [ ] give the release workflow only the minimum write permissions required;
- [ ] require the exact release commit to pass current Windows CI;
- [ ] require the applicable `docs/TESTING.md` desktop smoke matrix before publication;
- [ ] publish versioned artifacts and checksums;
- [ ] verify the uploaded assets after publication;
- [ ] update README download language only when real release assets exist.

### P2 — repository hygiene

- [ ] inspect stale merged/superseded non-main branches for unique commits, then delete them if none remain;
- [ ] remove duplicated `VERSION` ↔ `AppVersion` representation in a separate narrow change if a simpler single-source mechanism is available;
- [ ] remove checked-in config ↔ embedded-default duplication in a separate narrow change only if first-run behavior remains simple and reliable;
- [ ] decide whether `docs/index.html` needs a reproducible authoring source before substantial future redesign; do not invent provenance retroactively.

## Minimum verification model

### Pure transform change

- smallest reproducer;
- regression test where practical;
- `tests/repo-contract.ps1`;
- `tools/test.ps1`;
- Windows CI on final commit.

### Settings/hotkey change

- targeted regression/contract test;
- default/config synchronization;
- full automated suite;
- manual desktop smoke only when actual input/hotkey integration risk changes.

### Clipboard/input change

- full automated suite;
- applicable real-Windows desktop smoke matrix;
- no cross-editor compatibility claim from headless CI alone.

### Packaging/release change

- packaging contract review;
- package-level deterministic checks;
- current Windows CI;
- applicable desktop smoke matrix;
- artifact checksum verification;
- fresh GitHub Release evidence before reporting publication success.

### Public docs page change

- read `docs/README.md` first;
- keep page changes separate from application behavior unless explicitly coupled;
- do not reformat the large generated/self-contained artifact as incidental cleanup.

## Stop conditions

An agent must stop and report the missing decision/evidence rather than improvise when:

- a requested release depends on an undefined package format/toolchain;
- a workflow would need broader permissions only to work around a failing guard;
- a release claim cannot be supported by a real GitHub Release or verified artifact;
- a desktop compatibility claim depends only on headless CI;
- external/private/local data would need to be copied into a public repository surface without a clear necessity and sanitization path;
- a change would rewrite `docs/index.html` broadly without an explicit web-authoring task.

## Exit criteria for the next stage

The repository is ready to call itself release-capable when all of the following are true:

1. a canonical package command/toolchain is documented and reproducible enough for project needs;
2. package inputs, outputs, versioning, config behavior, and checksums are explicit;
3. package checks run independently of GUI smoke tests;
4. a narrow release workflow exists and ordinary CI remains read-only;
5. `docs/TESTING.md` defines the manual gate actually used for release;
6. the first GitHub Release is published with verified assets/checksums;
7. README download wording points to real application artifacts rather than source ZIPs.
