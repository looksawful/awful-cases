# Next-stage readiness: packaging, release, and agent boundaries

This document is a dated working plan, not a second source of truth for application behavior. Current behavior remains defined by production code, executable tests, `README.md`, `AGENTS.md`, `docs/TESTING.md`, packaging/release docs, and merged GitHub history.

Related tracking issue: #26.

## Audit conclusion

Awful Cases keeps a deliberately small repository-specific agent system:

1. `AGENTS.md` — always-on policy, invariants, safety boundaries, and repository truth rules.
2. `skills/awful-cases/SKILL.md` — the single task-routing workflow for implementation, testing, Windows integration, packaging/release, and public docs.

The larger `looksawful.ru` repository benefits from many narrow skills because it spans frontend runtime, CMS, media, TypeScript, CI tiers, browser testing, deployment, and multiple protected publication surfaces. Copying that catalog into Awful Cases would add routing overhead without adding enforcement. Reuse the underlying principle instead: prose guidance must map to executable checks or explicit stop conditions where safety matters.

## Current strengths

- Pure text transformations are separated from Windows side effects.
- Clipboard output no longer relies on a paste/restore race.
- Repository contracts synchronize version/config/hotkey/default invariants.
- AutoHotkey regression tests run on Windows CI with a pinned verified AutoHotkey archive.
- Ordinary CI has read-only contents permission and does not mutate source.
- `docs/TESTING.md` separates headless automation from real desktop smoke verification.
- Canonical Windows x64 packaging is implemented in `tools/package.ps1` and documented in `docs/PACKAGING.md`.
- Package toolchain archives are version-pinned and SHA-256 verified.
- Package output verification checks PE metadata, ZIP layout, VERSION, and `SHA256SUMS.txt`.
- Package output handling preserves unrelated files and rejects dangerous destinations.
- A guarded manual release workflow is implemented separately from ordinary CI and documented in `docs/RELEASING.md`.
- Release verification and publication are split by privilege: read-only verification first, `contents: write` only in the dependent publication job.
- Completed hardening work is recorded in dated plans rather than silently mixed into current behavior documentation.

## Readiness status

### P0 — agent/policy clarity

- [x] Explicitly define one-skill minimal agent architecture.
- [x] Clarify that Issues are authoritative for tracked defects, not exhaustive defect knowledge.
- [x] Mark agent instructions, workflows, packaging/release tooling, repository contracts, and release-gate rules as protected policy/tooling surfaces.
- [x] Add a public-reporting boundary for GitHub Issues/PRs/logs/artifacts.
- [x] Add build/release truth rules so agents cannot invent a package, installer, or release that does not exist.

### P1 — packaging contract

- [x] Supported AutoHotkey v2 compiler/toolchain defined.
- [x] Compiler/tool versions pinned and external archives integrity-checked.
- [x] Exact source/config/icon/package inputs defined.
- [x] First distribution format defined: portable Windows x64 standalone EXE plus versioned ZIP.
- [x] Artifact naming convention defined from repository `VERSION`.
- [x] `VERSION`/`AppVersion` consistency enforced before packaging; PE metadata derives from VERSION as `x.y.z.0`.
- [x] `awful-cases.ini` ships beside the executable and can still be regenerated if removed.
- [x] `SHA256SUMS.txt` generated and verified.
- [x] Reproducibility boundary documented without claiming unproven byte-for-byte determinism.
- [x] Unsigned/non-installer/SmartScreen expectations documented honestly.
- [x] Output directory handling preserves unrelated files and rejects repository/drive roots.

Implemented by merged PR #29.

### P1 — release implementation

- [x] Dedicated package script with fail-closed validation.
- [x] Package-level repository and output contract tests.
- [x] Dedicated manual GitHub Release workflow separate from ordinary CI.
- [x] Workflow default remains `contents: read`; only the dependent publish job receives `contents: write`.
- [x] Release input requires exact repository VERSION and `main` ref.
- [x] Release input requires explicit `SMOKE-PASSED` plus real non-empty desktop smoke evidence.
- [x] Read-only verification job runs contracts, AutoHotkey tests, canonical packaging and output verification.
- [x] Verified candidate is handed to publish through commit-pinned upload/download artifact actions.
- [x] Publish job re-verifies the transferred candidate before creating release state.
- [x] Publication is draft-first; uploaded draft assets are downloaded and package-verified before becoming public.
- [x] Partial draft/tag state is cleaned on pre-publication failure.
- [x] Ordinary CI remains verification-only/read-only and cannot publish releases.
- [ ] Perform the real Windows desktop smoke matrix on the intended release candidate.
- [ ] Prepare final release version/changelog commit.
- [ ] Dispatch the guarded Release workflow from `main` using truthful smoke evidence.
- [ ] Verify the resulting public GitHub Release and downloaded checksums.
- [ ] Replace README source-only download wording with actual binary Release links only after the public Release exists.

The implementation tasks above are in PR #32. The remaining unchecked items intentionally require real release evidence and must not be marked complete from headless CI alone.

### P2 — repository hygiene

- [ ] Inspect and delete stale merged/superseded non-main branches where the available GitHub tooling permits ref deletion.
- [ ] Remove duplicated `VERSION` ↔ `AppVersion` representation in a separate narrow change if a simpler single-source mechanism is available.
- [ ] Remove checked-in config ↔ embedded-default duplication in a separate narrow change only if first-run behavior remains simple and reliable.
- [ ] Decide whether `docs/index.html` needs a reproducible authoring source before substantial future redesign; do not invent provenance retroactively.

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

### Packaging change

- `tests/repo-contract.ps1`;
- `tests/package-contract.ps1`;
- canonical `tools/package.ps1` build;
- `tests/package-output.ps1` against produced outputs;
- final Windows CI package job.

### Release change

- `tests/release-contract.ps1`;
- current Windows CI;
- canonical package verification;
- applicable real desktop smoke matrix before publication;
- draft-first uploaded-asset verification;
- fresh public GitHub Release evidence before reporting publication success.

### Public docs page change

- read `docs/README.md` first;
- keep page changes separate from application behavior unless explicitly coupled;
- do not reformat the large self-contained artifact as incidental cleanup.

## Stop conditions

An agent must stop and report the missing decision/evidence rather than improvise when:

- a release claim cannot be supported by a real GitHub Release or verified artifact;
- `SMOKE-PASSED` would need to be invented rather than supported by a real desktop test;
- a workflow would need broader permissions only to work around a failing guard;
- a desktop compatibility claim depends only on headless CI;
- external/private/local data would need to be copied into a public repository surface without a clear necessity and sanitization path;
- a change would rewrite `docs/index.html` broadly without an explicit web-authoring task.

## Exit criteria for the next stage

The engineering implementation is release-capable when all of the following are true:

1. [x] a canonical package command/toolchain is documented and reproducible enough for project needs;
2. [x] package inputs, outputs, versioning, config behavior, and checksums are explicit;
3. [x] package checks run independently of GUI smoke tests;
4. [x] a narrow manual release workflow exists and ordinary CI remains read-only;
5. [x] `docs/TESTING.md` defines the manual gate required by the release workflow;
6. [ ] the intended release candidate passes the real desktop smoke gate;
7. [ ] the first GitHub Release is published with verified assets/checksums;
8. [ ] README binary download wording points to the real application Release assets.

Items 6–8 are publication evidence, not missing release engineering. They remain deliberately open until a human desktop smoke run and actual public Release exist.
