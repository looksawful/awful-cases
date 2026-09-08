# Awful Cases Engineering Baseline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish a minimal, reproducible engineering baseline for Awful Cases without changing normal application behavior.

**Architecture:** Keep the current 0.1.0 AutoHotkey application intact. Add dependency-free repository contracts, Windows-based interpreter validation, repository-specific agent guidance and explicit issue tracking for defects/refactors that require behavior changes.

**Tech Stack:** AutoHotkey v2.0.x, PowerShell 7+, GitHub Actions, GitHub Issues.

**Spec:** `AGENTS.md`

## Global Constraints

- Target platform remains Windows.
- Application source remains AutoHotkey v2.0-compatible.
- Do not change user-facing text transforms, shortcuts, GUI behavior or clipboard behavior in this baseline.
- Keep `VERSION`, `AppVersion` and `CHANGELOG.md` synchronized.
- Do not modify `docs/index.html` as part of utility tooling work.

---

### Task 1: Repository contract test

**Files:**
- Create: `tests/repo-contract.ps1`

**Interfaces:**
- Consumes: repository files and embedded AHK configuration.
- Produces: a zero exit code when repository invariants hold; a terminating error when one is violated.

- [x] **Step 1: Define invariants that can fail on the current repository structure**

Validate required files, version synchronization, AHK v2 declaration, changelog version, embedded/default INI equality and default-hotkey validity.

- [x] **Step 2: Implement dependency-free PowerShell checks**

Use only PowerShell built-ins so the script runs on Windows 11 and `windows-latest` without package installation.

- [ ] **Step 3: Execute on Windows**

Run:

```powershell
pwsh -File .\tests\repo-contract.ps1
```

Expected: `Repository contracts passed.`

---

### Task 2: Real AutoHotkey parser validation in CI

**Files:**
- Create: `.github/workflows/quality.yml`

**Interfaces:**
- Consumes: `app/awful-cases.ahk` and official AutoHotkey 2.0.27 portable archive.
- Produces: PR/push quality status.

- [x] **Step 1: Add Windows repository-contract job**

Run `tests/repo-contract.ps1` on `windows-latest`.

- [x] **Step 2: Add AutoHotkey validation job**

Download `AutoHotkey_2.0.27.zip` from the official AutoHotkey download host and run:

```text
AutoHotkey64.exe /ErrorStdOut=UTF-8 /Validate app\awful-cases.ahk
```

- [ ] **Step 3: Verify both jobs on the pull request**

Expected: both jobs complete successfully.

---

### Task 3: Agent and maintainer playbooks

**Files:**
- Create: `AGENTS.md`
- Create: `DEVELOPMENT.md`
- Create: `.agents/skills/awful-cases-development/SKILL.md`
- Create: `.agents/skills/typography-rules/SKILL.md`
- Create: `.agents/skills/release-check/SKILL.md`

**Interfaces:**
- Consumes: current application structure and quality gates.
- Produces: explicit repository-local instructions for humans and coding agents.

- [x] **Step 1: Document source-of-truth files and change constraints**
- [x] **Step 2: Document automated and manual validation**
- [x] **Step 3: Add task-specific playbooks for ordinary development, typography rules and releases**

---

### Task 4: Review findings and tracked follow-up

**Files:**
- No production-code changes in this baseline.

**Interfaces:**
- Consumes: static architecture/code review.
- Produces: actionable GitHub issues with acceptance criteria.

- [x] **Step 1: Track F13-F24 Settings round-trip bug**
- [x] **Step 2: Track clipboard restoration race risk**
- [x] **Step 3: Track extraction of a pure, executable text-transform test core**
- [x] **Step 4: Track missing provenance/build procedure for `docs/index.html`**

---

### Task 5: Documentation capture

**Files:**
- Notion pages under the existing Awful Cases project page.

**Interfaces:**
- Consumes: repository audit, CI results, issue links and architecture findings.
- Produces: engineering overview, architecture/technical debt, testing guide and agent/tooling reference in Notion.

- [ ] **Step 1: Create an Engineering & Development hub under the existing Awful Cases page**
- [ ] **Step 2: Add architecture, testing and tooling subpages**
- [ ] **Step 3: Link GitHub issues and the baseline pull request**
- [ ] **Step 4: Verify the Notion pages after creation**
