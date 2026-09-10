$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Fail([string]$Message) {
    throw "Release contract failed: $Message"
}

function Require-File([string]$RelativePath) {
    $path = Join-Path $repoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Fail "missing required file '$RelativePath'"
    }
    return $path
}

$releaseWorkflowPath = Require-File '.github/workflows/release.yml'
$releaseGuidePath = Require-File 'docs/RELEASING.md'
$ciWorkflowPath = Require-File '.github/workflows/ci.yml'

$releaseWorkflow = Get-Content -LiteralPath $releaseWorkflowPath -Raw
$releaseGuide = Get-Content -LiteralPath $releaseGuidePath -Raw
$ciWorkflow = Get-Content -LiteralPath $ciWorkflowPath -Raw

$requiredWorkflowTokens = @(
    'workflow_dispatch:',
    'desktop_smoke_confirmed',
    'desktop_smoke_evidence',
    "refs/heads/main",
    'pwsh -File tests/repo-contract.ps1',
    'pwsh -File tests/package-contract.ps1',
    'pwsh -File tests/release-contract.ps1',
    'pwsh -File tools/test.ps1',
    'pwsh -File tools/package.ps1',
    'pwsh -File tests/package-output.ps1',
    'gh release create',
    '--draft',
    'gh release download',
    'gh release edit',
    '--draft=false',
    'contents: write',
    '3d3c42e5aac5ba805825da76410c181273ba90b1'
)
foreach ($token in $requiredWorkflowTokens) {
    if ($releaseWorkflow -notmatch [regex]::Escape($token)) {
        Fail ".github/workflows/release.yml is missing required token '$token'"
    }
}

if ($releaseWorkflow -match '(?m)^\s*push\s*:') {
    Fail 'release workflow must not publish automatically on push'
}
if ($releaseWorkflow -match '(?m)^\s*pull_request\s*:') {
    Fail 'release workflow must not run on pull_request'
}
if ($releaseWorkflow -notmatch '(?m)^permissions:\s*\r?\n\s+contents:\s*read\s*$') {
    Fail 'release workflow must default to contents: read'
}
if ($releaseWorkflow -notmatch '(?ms)^\s+permissions:\s*\r?\n\s+contents:\s*write\s*$') {
    Fail 'release publication job must explicitly scope contents: write'
}
if ($releaseWorkflow -notmatch [regex]::Escape("SMOKE-PASSED")) {
    Fail 'release workflow must require the exact SMOKE-PASSED confirmation phrase'
}
if ($releaseWorkflow -notmatch '(?i)IsNullOrWhiteSpace') {
    Fail 'release workflow must reject empty smoke evidence'
}
if ($releaseWorkflow -notmatch '(?i)VERSION') {
    Fail 'release workflow must validate the requested version against repository VERSION'
}
if ($releaseWorkflow -notmatch '(?i)GITHUB_SHA') {
    Fail 'release workflow must target and verify the exact checked-out commit'
}
if ($releaseWorkflow -notmatch '(?i)release delete') {
    Fail 'release workflow must clean up a partial draft release when publication fails'
}

$requiredGuideTokens = @(
    'desktop smoke',
    'SMOKE-PASSED',
    'GitHub Release',
    'unsigned',
    'not an installer',
    'SHA256SUMS.txt'
)
foreach ($token in $requiredGuideTokens) {
    if ($releaseGuide -notmatch [regex]::Escape($token)) {
        Fail "docs/RELEASING.md is missing release guidance token '$token'"
    }
}

# Ordinary CI remains verification-only. Release publication belongs only to release.yml.
if ($ciWorkflow -match '(?i)gh\s+release\s+(create|edit|upload|delete)') {
    Fail 'ordinary CI must not publish or mutate GitHub Releases'
}
if ($ciWorkflow -notmatch [regex]::Escape('pwsh -File tests/release-contract.ps1')) {
    Fail 'ordinary CI must enforce the release repository contract'
}

Write-Host 'Release repository contract passed.'
Write-Host 'Trigger: workflow_dispatch only'
Write-Host 'Publication gate: main + exact version + desktop smoke evidence'
Write-Host 'Publication model: draft -> downloaded asset verification -> public release'
