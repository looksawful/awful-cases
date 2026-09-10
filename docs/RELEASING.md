# Releasing Awful Cases

This is the canonical procedure for publishing a GitHub Release. Packaging can be automated and verified headlessly; desktop compatibility cannot. A public release therefore requires a real Windows desktop smoke run before the release workflow is dispatched.

## What the workflow publishes

The release workflow publishes exactly three assets for repository `VERSION=x.y.z`:

- `awful-cases-vx.y.z-windows-x64.exe`
- `awful-cases-vx.y.z-windows-x64.zip`
- `SHA256SUMS.txt`

The build is portable and unsigned. It is not an installer, is not Authenticode-signed, and may trigger Windows SmartScreen or reputation warnings. Do not disable Windows security protections to work around those warnings.

## 1. Prepare the release commit

Before smoke testing, `main` must contain the intended release version and changelog state. Verify:

```powershell
pwsh -File tests/repo-contract.ps1
pwsh -File tests/package-contract.ps1
pwsh -File tests/release-contract.ps1
pwsh -File tools/test.ps1
pwsh -File tools/package.ps1
```

`VERSION`, `AppVersion`, changelog and package names must agree. Do not dispatch a release for a version different from repository `VERSION`.

## 2. Run the desktop smoke gate

Build the package with `pwsh -File tools/package.ps1` and use the packaged `awful-cases.exe`, not an arbitrary source checkout, for the applicable release smoke matrix in [`docs/TESTING.md`](TESTING.md).

At minimum, the release gate must cover the documented Windows desktop checks for:

- Notepad ordinary replacement;
- a browser editable field;
- VS Code;
- Word or LibreOffice Writer;
- Cyrillic and general Unicode input;
- large replacement text;
- preservation of non-text clipboard payloads;
- empty/no-selection behavior.

Record a short evidence note that is specific enough to identify the run, for example the tested Windows version, package version, applications covered, and any relevant result summary. The workflow intentionally cannot manufacture this evidence itself.

## 3. Dispatch the GitHub Release workflow

Open GitHub Actions → `Release` → `Run workflow` and select `main`.

Provide:

- `version`: exactly the value in repository `VERSION`;
- `desktop_smoke_confirmed`: exactly `SMOKE-PASSED`;
- `desktop_smoke_evidence`: the non-empty evidence note from the real desktop smoke run.

Do not type `SMOKE-PASSED` unless the desktop smoke matrix was actually performed on the package being released. The input is a human release assertion, not an automated test substitute.

## 4. What the workflow verifies

The workflow fails closed unless all of the following are true:

1. it is running from `refs/heads/main`;
2. the requested version exactly equals repository `VERSION`;
3. `desktop_smoke_confirmed` is exactly `SMOKE-PASSED`;
4. `desktop_smoke_evidence` is non-empty;
5. the version tag and GitHub Release do not already exist;
6. repository, package and release contracts pass;
7. AutoHotkey regression tests pass with the pinned verified AutoHotkey v2.0.27 archive;
8. the canonical package script succeeds;
9. package output metadata, ZIP layout and SHA256SUMS pass verification.

Only the release job receives `contents: write`; the workflow default remains `contents: read`. Ordinary CI stays read-only and never publishes or edits releases.

## 5. Draft-first publication

Publication is deliberately two-stage:

1. GitHub creates a draft Release targeting the exact verified `GITHUB_SHA` and uploads the versioned EXE, portable ZIP and `SHA256SUMS.txt`.
2. The workflow downloads those uploaded assets back from the draft Release and runs `tests/package-output.ps1` against the downloaded copies.
3. It verifies that the draft tag and target commit still match the requested release.
4. Only then does it run `gh release edit ... --draft=false` and make the Release public.

If the workflow fails after creating the draft but before publication, the partial draft Release and generated tag are deleted by the cleanup step. A failure after successful publication is reported but does not silently replace or mutate an existing published release.

## 6. After publication

The workflow performs a final state check that the GitHub Release is public, stable rather than prerelease, and still targets the verified commit.

For an external audit, download the three release assets and verify the EXE/ZIP hashes against `SHA256SUMS.txt`. A GitHub Release is the public binary distribution source; the repository source ZIP is not an installer or application release.

## Version changes

Prepare version changes in a normal PR before running the release workflow. Do not change `VERSION` inside the release workflow and do not allow the workflow to push source changes. Repository contracts remain the guard for duplicated version representations until that technical debt is removed separately.
