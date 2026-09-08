$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Fail([string]$Message) {
    throw "Repository contract failed: $Message"
}

function Read-Text([string]$RelativePath) {
    $path = Join-Path $repoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Fail "missing required file '$RelativePath'"
    }
    return Get-Content -LiteralPath $path -Raw
}

function Normalize-Newlines([string]$Text) {
    return (($Text -replace "`r`n", "`n") -replace "`r", "`n").Trim()
}

$requiredFiles = @(
    "README.md",
    "CHANGELOG.md",
    "LICENSE",
    "VERSION",
    "app/awful-cases.ahk",
    "app/awful-cases.ini",
    "app/awful-cases.ico",
    "app/awful-cases-icon.png"
)

foreach ($file in $requiredFiles) {
    $null = Read-Text $file
}

$version = (Read-Text "VERSION").Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') {
    Fail "VERSION must contain a SemVer-like x.y.z value, got '$version'"
}

$source = Read-Text "app/awful-cases.ahk"
$versionMatch = [regex]::Match($source, 'global\s+AppVersion\s*:=\s*"([^"]+)"')
if (-not $versionMatch.Success) {
    Fail "AppVersion was not found in app/awful-cases.ahk"
}
if ($versionMatch.Groups[1].Value -ne $version) {
    Fail "VERSION ($version) and AppVersion ($($versionMatch.Groups[1].Value)) differ"
}

if ($source -notmatch '(?m)^#Requires\s+AutoHotkey\s+v2\.0\s*$') {
    Fail "app/awful-cases.ahk must explicitly require AutoHotkey v2.0"
}

$changelog = Read-Text "CHANGELOG.md"
$changelogHeading = "(?m)^##\s+$([regex]::Escape($version))\s*$"
if ($changelog -notmatch $changelogHeading) {
    Fail "CHANGELOG.md has no section for version $version"
}

$defaultConfigMatch = [regex]::Match(
    $source,
    'GetDefaultConfig\(\)\s*\{\s*return\s*"\s*\(\s*(.*?)\s*\)\s*"\s*\}',
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)
if (-not $defaultConfigMatch.Success) {
    Fail "could not extract GetDefaultConfig() from app/awful-cases.ahk"
}

$embeddedConfig = Normalize-Newlines $defaultConfigMatch.Groups[1].Value
$checkedInConfig = Normalize-Newlines (Read-Text "app/awful-cases.ini")
if ($embeddedConfig -ne $checkedInConfig) {
    Fail "app/awful-cases.ini differs from GetDefaultConfig()"
}

$allowedMatch = [regex]::Match(
    $source,
    'global\s+AllowedFinalHotkeyKeys\s*:=\s*\[(.*?)\]\s*EnsureConfig\(\)',
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)
if (-not $allowedMatch.Success) {
    Fail "could not extract AllowedFinalHotkeyKeys"
}

$allowedKeys = @(
    [regex]::Matches($allowedMatch.Groups[1].Value, '"([^"]+)"') |
        ForEach-Object { $_.Groups[1].Value }
)
if ($allowedKeys.Count -eq 0) {
    Fail "AllowedFinalHotkeyKeys is empty"
}

$hotkeys = [ordered]@{}
$insideHotkeys = $false
foreach ($line in (Normalize-Newlines $checkedInConfig) -split "`n") {
    if ($line -match '^\s*\[([^\]]+)\]\s*$') {
        $insideHotkeys = $Matches[1] -eq "Hotkeys"
        continue
    }
    if ($insideHotkeys -and $line -match '^\s*([^=]+?)\s*=\s*(.*?)\s*$') {
        $hotkeys[$Matches[1]] = $Matches[2]
    }
}

$expectedHotkeyNames = @("Upper", "Lower", "Toggle", "Title", "Lint", "Sentence", "Settings")
foreach ($name in $expectedHotkeyNames) {
    if (-not $hotkeys.Contains($name)) {
        Fail "missing [Hotkeys] entry '$name'"
    }
    if ($hotkeys[$name] -notin $allowedKeys) {
        Fail "default hotkey '$name=$($hotkeys[$name])' is not in AllowedFinalHotkeyKeys"
    }
}

$duplicateDefaults = @(
    $hotkeys.Values |
        Group-Object |
        Where-Object Count -gt 1
)
if ($duplicateDefaults.Count -gt 0) {
    $duplicates = ($duplicateDefaults | ForEach-Object Name) -join ", "
    Fail "default hotkeys must be unique; duplicates: $duplicates"
}

$readme = Read-Text "README.md"
if ($readme -notmatch [regex]::Escape('awful-cases.ini')) {
    Fail "README.md must document awful-cases.ini"
}
if ($readme -notmatch 'AutoHotkey\s+v2') {
    Fail "README.md must document the AutoHotkey v2 requirement"
}

Write-Host "Repository contracts passed."
Write-Host "Version: $version"
Write-Host "Default hotkeys: $($hotkeys.Count)"
Write-Host "Allowed final keys: $($allowedKeys.Count)"
