$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Fail([string]$Message) {
    throw "Package contract failed: $Message"
}

function Require-File([string]$RelativePath) {
    $path = Join-Path $repoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Fail "missing required file '$RelativePath'"
    }
    return $path
}

$version = (Get-Content -LiteralPath (Join-Path $repoRoot 'VERSION') -Raw).Trim()
$packageScriptPath = Require-File 'tools/package.ps1'
$packagingGuidePath = Require-File 'docs/PACKAGING.md'
$ciWorkflowPath = Require-File '.github/workflows/ci.yml'

$packageScript = Get-Content -LiteralPath $packageScriptPath -Raw
$packagingGuide = Get-Content -LiteralPath $packagingGuidePath -Raw
$ciWorkflow = Get-Content -LiteralPath $ciWorkflowPath -Raw

$requiredScriptTokens = @(
    '2.0.27',
    'F72CAD4B98A7B5AA050B35D6DEAA0B0E3949929B2AAFF7D0D69858F1F380B3EF',
    '1.1.37.02a2',
    'C29B8C3A5124850D79FC9E66E2CA79677C377D7F31631AD3022BA159C5D9E3BE',
    'SHA256SUMS.txt'
)
foreach ($token in $requiredScriptTokens) {
    if ($packageScript -notmatch [regex]::Escape($token)) {
        Fail "tools/package.ps1 is missing pinned/package token '$token'"
    }
}

# Packaging must never recursively delete a caller-supplied output directory.
# Shared artifact folders and accidental paths such as '.' must preserve unrelated files.
if ($packageScript -match 'Remove-Item\s+-LiteralPath\s+\$OutputDirectory\s+-Recurse') {
    Fail 'tools/package.ps1 must not recursively delete OutputDirectory; remove only known package outputs and reject dangerous destinations'
}

$expectedExe = "awful-cases-v$version-windows-x64.exe"
$expectedZip = "awful-cases-v$version-windows-x64.zip"
foreach ($artifactName in @($expectedExe, $expectedZip)) {
    if ($packagingGuide -notmatch [regex]::Escape($artifactName)) {
        Fail "docs/PACKAGING.md must document artifact '$artifactName'"
    }
}

if ($packagingGuide -notmatch '(?i)unsigned') {
    Fail 'docs/PACKAGING.md must explicitly state that the first package is unsigned'
}
if ($packagingGuide -notmatch '(?i)portable') {
    Fail 'docs/PACKAGING.md must describe the first package as portable'
}
if ($packagingGuide -match '(?i)installer' -and $packagingGuide -notmatch '(?i)(not|no|without|does not).*installer|installer.*(not|no|without)') {
    Fail 'docs/PACKAGING.md mentions installer without an explicit non-installer boundary'
}

$requiredCiTokens = @(
    'pwsh -File tools/package.ps1',
    'pwsh -File tests/package-output.ps1',
    '3d3c42e5aac5ba805825da76410c181273ba90b1',
    'ea165f8d65b6e75b540449e92b4886f43607fa02'
)
foreach ($token in $requiredCiTokens) {
    if ($ciWorkflow -notmatch [regex]::Escape($token)) {
        Fail ".github/workflows/ci.yml is missing package verification token '$token'"
    }
}
if ($ciWorkflow -match '(?i)gh\s+release\s+create|softprops/action-gh-release|ncipollo/release-action') {
    Fail 'ordinary CI must not publish GitHub Releases'
}

Write-Host 'Package repository contract passed.'
Write-Host "Version: $version"
Write-Host "Expected EXE: $expectedExe"
Write-Host "Expected ZIP: $expectedZip"
Write-Host 'Ordinary CI package verification: enforced, release publication: forbidden'
