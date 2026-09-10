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

$packageScript = Get-Content -LiteralPath $packageScriptPath -Raw
$packagingGuide = Get-Content -LiteralPath $packagingGuidePath -Raw

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
if ($packagingGuide -match '(?i)installer') {
    $installerClaims = [regex]::Matches($packagingGuide, '(?i)installer')
    if ($packagingGuide -notmatch '(?i)(not|no|without|does not).*installer|installer.*(not|no|without)') {
        Fail 'docs/PACKAGING.md mentions installer without an explicit non-installer boundary'
    }
}

Write-Host 'Package repository contract passed.'
Write-Host "Version: $version"
Write-Host "Expected EXE: $expectedExe"
Write-Host "Expected ZIP: $expectedZip"
