# Windows Packaging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce deterministic Windows x64 executable, portable ZIP, and per-user installer artifacts with safe configuration storage and gated GitHub Releases.

**Architecture:** Keep the AutoHotkey runtime intact. Add a small pure path-decision library plus Windows-side migration/autostart integration, then add deterministic PowerShell packaging around official pinned AutoHotkey/Ahk2Exe/Inno Setup tools. CI builds but never publishes; a separate manually gated release workflow performs publication.

**Tech Stack:** AutoHotkey v2.0.27, PowerShell 7, Ahk2Exe v1.1.37.02a2, Inno Setup 7.1.0, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-10-windows-packaging-design.md`

## Global Constraints

- Windows 10/11 x64 is the supported packaged target.
- Existing text-transform behavior and clipboard insertion semantics must not change.
- Ordinary CI retains `contents: read`.
- Release publication requires explicit desktop-smoke confirmation.
- Downloaded packaging tools are pinned and SHA-256 verified before execution.
- Public artifacts are unsigned until a separate code-signing solution is implemented.

---

### Task 1: Lock packaging and Windows-app contracts

**Files:**
- Create: `tests/package-contract.ps1`
- Modify: `tests/repo-contract.ps1`

**Interfaces:**
- Consumes: repository files and `VERSION`.
- Produces: fail-closed structural guarantees for artifact names, pinned tools, config placement, portable marker, installer, CI and release workflow boundaries.

- [ ] **Step 1: Write the failing contracts** that require `tools/build.ps1`, `tools/package.ps1`, `installer/awful-cases.iss`, `.github/workflows/release.yml`, AppData/portable config routing, x64 artifact names, checksums, and a manual smoke gate.
- [ ] **Step 2: Run `pwsh -File tests/repo-contract.ps1`** and confirm it fails because the implementation files/behaviors do not exist yet.
- [ ] **Step 3: Keep the failing commit as RED evidence.**

### Task 2: Implement installed/portable configuration and autostart

**Files:**
- Create: `app/lib/app-paths.ahk`
- Modify: `app/awful-cases.ahk`
- Test: `tests/package-contract.ps1`

**Interfaces:**
- Consumes: `A_IsCompiled`, `A_ScriptDir`, `A_AppData`, `portable.flag` presence.
- Produces: `ResolveConfigPath(scriptDir, appDataDir, isCompiled, portableMode)` and current-user autostart registry management.

- [ ] **Step 1:** Add pure path selection: source or portable mode uses the script directory; installed compiled mode uses `%APPDATA%\Awful Cases`.
- [ ] **Step 2:** Make `EnsureConfig()` create the destination directory and migrate a legacy side-by-side INI before generating defaults.
- [ ] **Step 3:** Add a tray autostart toggle using `HKCU\Software\Microsoft\Windows\CurrentVersion\Run\Awful Cases`.
- [ ] **Step 4:** Preserve all existing transform, hotkey, GUI, clipboard, and language behavior.

### Task 3: Add deterministic executable build

**Files:**
- Create: `tools/build.ps1`
- Modify: `app/awful-cases.ahk`
- Modify: `tests/repo-contract.ps1`

**Interfaces:**
- Consumes: explicit Ahk2Exe path, AutoHotkey64 base path, application source/icon, `VERSION`.
- Produces: `dist/Awful-Cases-<version>-x64.exe` with Awful Cases icon/version metadata.

- [ ] **Step 1:** Add Ahk2Exe metadata directives to the application and require directive version to match `VERSION`.
- [ ] **Step 2:** Implement `tools/build.ps1` with explicit tool paths, input validation, clean output, `/base` x64, `/icon`, and `/silent verbose` compilation.
- [ ] **Step 3:** Fail if the expected executable was not created.

### Task 4: Add portable and installer packaging

**Files:**
- Create: `installer/awful-cases.iss`
- Create: `tools/package.ps1`

**Interfaces:**
- Consumes: official pinned tool archives/installers and `tools/build.ps1`.
- Produces: standalone EXE, portable ZIP, per-user Setup EXE, `SHA256SUMS.txt`.

- [ ] **Step 1:** Download AutoHotkey v2.0.27, Ahk2Exe v1.1.37.02a2 and Inno Setup 7.1.0 only from their official GitHub release URLs.
- [ ] **Step 2:** Verify every download against the exact SHA-256 values in the design spec before extraction/execution.
- [ ] **Step 3:** Compile the standalone x64 executable.
- [ ] **Step 4:** Stage portable contents (`exe`, INI, `portable.flag`, LICENSE) and create the versioned ZIP.
- [ ] **Step 5:** Silently install pinned Inno Setup into the temporary tooling directory, locate `ISCC.exe`, and compile the per-user installer.
- [ ] **Step 6:** Hash the three release artifacts and write deterministic `SHA256SUMS.txt` entries sorted by filename.

### Task 5: Verify packages continuously without publishing

**Files:**
- Modify: `.github/workflows/ci.yml`

**Interfaces:**
- Consumes: successful existing test job.
- Produces: a Windows packaging verification job and downloadable CI artifact.

- [ ] **Step 1:** Keep top-level `contents: read` unchanged.
- [ ] **Step 2:** Add a `package` job after tests that runs `tools/package.ps1` and `tests/package-contract.ps1`.
- [ ] **Step 3:** Upload `dist/` as a CI artifact without creating tags/releases or mutating source.

### Task 6: Add gated GitHub Release publication

**Files:**
- Create: `.github/workflows/release.yml`

**Interfaces:**
- Consumes: `workflow_dispatch`, exact commit, successful ordinary CI, explicit desktop-smoke confirmation.
- Produces: `v<VERSION>` tag and GitHub Release with standalone EXE, portable ZIP, installer and checksums.

- [ ] **Step 1:** Require boolean input `desktop_smoke_passed` and fail unless true.
- [ ] **Step 2:** Require at least one successful `ci.yml` run for `GITHUB_SHA`.
- [ ] **Step 3:** Re-run repository/AutoHotkey tests and package from the exact commit.
- [ ] **Step 4:** Reject an existing release/tag that points elsewhere.
- [ ] **Step 5:** Create/push `v<VERSION>`, publish versioned assets, download them back, and validate all SHA-256 entries.

### Task 7: Version and document the Windows distribution

**Files:**
- Modify: `VERSION`
- Modify: `CHANGELOG.md`
- Modify: `README.md`
- Modify: `docs/TESTING.md`

**Interfaces:**
- Consumes: implemented package/release behavior.
- Produces: version `0.2.0` documentation with canonical package command and clear unsigned/release-gate statements.

- [ ] **Step 1:** Set `VERSION`, `AppVersion`, and Ahk2Exe metadata version to `0.2.0`.
- [ ] **Step 2:** Document `pwsh -File tools/package.ps1`, produced artifact names, installed/portable config behavior, autostart, and unsigned SmartScreen expectations.
- [ ] **Step 3:** Extend the release gate with package/checksum verification and the manual-release-workflow requirement.

### Task 8: Verification and review

**Files:** all changed files.

- [ ] **Step 1:** Run repository contracts and full AutoHotkey suite in Windows CI.
- [ ] **Step 2:** Run the packaging job to prove all four `dist` files are generated.
- [ ] **Step 3:** Inspect the PR diff for accidental transform changes, clipboard changes, broad workflow permissions, or `docs/index.html` edits.
- [ ] **Step 4:** Do not publish a public release until the real Windows desktop smoke matrix is explicitly confirmed.
