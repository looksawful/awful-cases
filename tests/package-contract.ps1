$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Fail([string]$Message) {
    throw "Package contract failed: $Message"
}

function Read-Required([string]$RelativePath) {
    $path = Join-Path $repoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Fail "missing required file '$RelativePath'"
    }
    return Get-Content -LiteralPath $path -Raw
}

$version = (Read-Required 'VERSION').Trim()
$source = Read-Required 'app/awful-cases.ahk'
$build = Read-Required 'tools/build.ps1'
$package = Read-Required 'tools/package.ps1'
$installSmoke = Read-Required 'tools/install-smoke.ps1'
$installer = Read-Required 'installer/awful-cases.iss'
$ci = Read-Required '.github/workflows/ci.yml'
$release = Read-Required '.github/workflows/release.yml'

$requiredArtifactFragments = @(
    'Awful-Cases-$version-x64.exe',
    'Awful-Cases-Portable-$version-x64.zip',
    'Awful-Cases-Setup-$version-x64.exe',
    'SHA256SUMS.txt'
)
foreach ($fragment in $requiredArtifactFragments) {
    if ($package -notmatch [regex]::Escape($fragment)) {
        Fail "tools/package.ps1 does not define artifact '$fragment'"
    }
}

$toolPins = @(
    '2.0.27',
    'F72CAD4B98A7B5AA050B35D6DEAA0B0E3949929B2AAFF7D0D69858F1F380B3EF',
    '1.1.37.02a2',
    'C29B8C3A5124850D79FC9E66E2CA79677C377D7F31631AD3022BA159C5D9E3BE',
    '7.1.0',
    '0362A383ED217D4C4239B5933866DD96D3EB2102737DA92F80F6057A4B40DF2F'
)
foreach ($pin in $toolPins) {
    if ($package -notmatch [regex]::Escape($pin)) {
        Fail "tools/package.ps1 is missing pinned tool value '$pin'"
    }
}

foreach ($nativeScript in @(
    @{ Name = 'tools/build.ps1'; Text = $build },
    @{ Name = 'tools/package.ps1'; Text = $package }
)) {
    if ($nativeScript.Text -match '\$LASTEXITCODE') {
        Fail "$($nativeScript.Name) must not depend on an unset LASTEXITCODE after GUI-subsystem tools"
    }
    if ($nativeScript.Text -notmatch 'Start-Process') {
        Fail "$($nativeScript.Name) must use Start-Process for native packaging tools"
    }
    if ($nativeScript.Text -notmatch '\.ExitCode') {
        Fail "$($nativeScript.Name) must validate native process ExitCode"
    }
}

if ($source -match 'global\s+ConfigPath\s*:=\s*A_ScriptDir') {
    Fail 'installed configuration must not be hard-wired to A_ScriptDir'
}
if ($source -notmatch 'portable\.flag') {
    Fail 'application must detect portable.flag'
}
if ($source -notmatch 'A_AppData') {
    Fail 'installed application must route configuration through A_AppData'
}
if ($source -notmatch 'Software\\Microsoft\\Windows\\CurrentVersion\\Run') {
    Fail 'application must expose current-user startup integration'
}
foreach ($uiText in @('Система', 'System', 'Запускать Awful Cases вместе с Windows', 'Start Awful Cases with Windows')) {
    if ($source -notmatch [regex]::Escape($uiText)) {
        Fail "Settings must expose localized startup control text '$uiText'"
    }
}
if ($source -notmatch 'SetAutoStartEnabled\(') {
    Fail 'Settings must apply the startup state through SetAutoStartEnabled()'
}

if ($installer -notmatch 'PrivilegesRequired\s*=\s*lowest') {
    Fail 'installer must be per-user and not require elevation'
}
if ($installer -notmatch '\{localappdata\}\\Programs\\Awful Cases') {
    Fail 'installer must target LocalAppData Programs'
}
if ($installer -notmatch 'Awful Cases.*CurrentVersion\\Run|CurrentVersion\\Run.*Awful Cases') {
    Fail 'installer must offer current-user startup registration'
}
if ($installer -notmatch 'CurUninstallStepChanged') {
    Fail 'installer must clean application-owned startup state during uninstall'
}
if ($installer -notmatch 'RegDeleteValue\s*\(') {
    Fail 'installer uninstall cleanup must remove the Awful Cases Run value explicitly'
}

if ($installSmoke -notmatch 'Awful-Cases-Setup-\$version-x64\.exe') {
    Fail 'install smoke must target the versioned installer'
}
if ($installSmoke -notmatch 'CurrentVersion\\Run') {
    Fail 'install smoke must exercise startup-registry cleanup'
}
if ($installSmoke -notmatch 'unins000\.exe') {
    Fail 'install smoke must execute the generated uninstaller'
}

if ($ci -match '(?mi)^\s*contents\s*:\s*write\s*$') {
    Fail 'ordinary CI must remain read-only for contents'
}
if ($ci -notmatch '(?m)^\s*package\s*:\s*$') {
    Fail 'ordinary CI must include a package verification job'
}
if ($ci -notmatch 'tools/package\.ps1') {
    Fail 'ordinary CI package job must run tools/package.ps1'
}
if ($ci -notmatch 'tools/install-smoke\.ps1') {
    Fail 'ordinary CI package job must run installer lifecycle smoke checks'
}

if ($release -notmatch '(?m)^\s*workflow_dispatch\s*:') {
    Fail 'release workflow must be manually dispatched'
}
if ($release -notmatch 'desktop_smoke_passed') {
    Fail 'release workflow must require explicit desktop smoke confirmation'
}
if ($release -notmatch 'release_commit_sha') {
    Fail 'release workflow must bind desktop smoke evidence to an explicit commit SHA'
}
if ($release -notmatch "release_commit_sha.*GITHUB_SHA|GITHUB_SHA.*release_commit_sha") {
    Fail 'release workflow must compare release_commit_sha with GITHUB_SHA'
}
if ($release -notmatch 'tests/package-contract\.ps1') {
    Fail 'release workflow must run package contracts explicitly'
}
if ($release -notmatch '(?mi)^\s*contents\s*:\s*write\s*$') {
    Fail 'release workflow needs narrowly scoped contents write permission'
}
if ($release -notmatch 'SHA256SUMS\.txt') {
    Fail 'release workflow must publish and verify checksums'
}

if ($build -notmatch '/base' -or $build -notmatch '/icon' -or $build -notmatch '/silent') {
    Fail 'tools/build.ps1 must compile explicitly with x64 base, icon and silent CLI mode'
}

Write-Host 'Package contracts passed.'
Write-Host "Version: $version"
