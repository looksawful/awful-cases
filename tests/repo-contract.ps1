$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Fail([string]$Message) {
    throw "Repository contract failed: $Message"
}

function Read-Text([string]$RelativePath) {
    $path = Join-Path $repoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Fail "missing required file '$RelativePath'"
    }
    Get-Content -LiteralPath $path -Raw
}

function Normalize-Newlines([string]$Text) {
    (($Text -replace "`r`n", "`n") -replace "`r", "`n").Trim()
}

function Read-IniSection([string]$Text, [string]$Section) {
    $values = [ordered]@{}
    $insideSection = $false
    foreach ($line in $Text -split "`n") {
        $line = $line.TrimEnd("`r")
        if ($line -match '^\s*\[([^\]]+)\]\s*$') {
            $insideSection = $Matches[1] -eq $Section
            continue
        }
        if ($insideSection -and $line -match '^\s*([^=]+?)\s*=\s*(.*?)\s*$') {
            $values[$Matches[1]] = $Matches[2]
        }
    }
    return $values
}

$version = (Read-Text 'VERSION').Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') {
    Fail "VERSION must contain x.y.z, got '$version'"
}

$source = Read-Text 'app/awful-cases.ahk'
$transformCore = Read-Text 'app/lib/text-transforms.ahk'
$testingGuide = Read-Text 'docs/TESTING.md'
$ciWorkflow = Read-Text '.github/workflows/ci.yml'

if ($testingGuide -notmatch '(?m)^##\s+Release gate\s*$') {
    Fail 'docs/TESTING.md must define a Release gate section'
}
if ($ciWorkflow -match '(?mi)^\s*contents\s*:\s*write\s*$' -or $ciWorkflow -match '(?mi)^\s*permissions\s*:\s*write-all\s*$') {
    Fail '.github/workflows/ci.yml must remain read-only for repository contents'
}

$versionMatch = [regex]::Match($source, 'global\s+AppVersion\s*:=\s*"([^"]+)"')
if (-not $versionMatch.Success) {
    Fail 'AppVersion was not found in app/awful-cases.ahk'
}
if ($versionMatch.Groups[1].Value -ne $version) {
    Fail "VERSION ($version) and AppVersion ($($versionMatch.Groups[1].Value)) differ"
}

$changelog = Read-Text 'CHANGELOG.md'
if ($changelog -notmatch "(?m)^##\s+$([regex]::Escape($version))\s*$") {
    Fail "CHANGELOG.md has no section for version $version"
}

$defaultConfigMatch = [regex]::Match(
    $source,
    'GetDefaultConfig\(\)\s*\{\s*return\s*"\s*\(\s*(.*?)\s*\)\s*"\s*\}',
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)
if (-not $defaultConfigMatch.Success) {
    Fail 'could not extract GetDefaultConfig()'
}

$embeddedConfig = Normalize-Newlines $defaultConfigMatch.Groups[1].Value
$checkedInConfig = Normalize-Newlines (Read-Text 'app/awful-cases.ini')
if ($embeddedConfig -ne $checkedInConfig) {
    Fail 'app/awful-cases.ini differs from GetDefaultConfig()'
}

$featureDefaultMatch = [regex]::Match(
    $transformCore,
    'GetDefaultFeatureState\(\)\s*\{\s*return\s+Map\((.*?)\)\s*\}',
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)
if (-not $featureDefaultMatch.Success) {
    Fail 'could not extract GetDefaultFeatureState()'
}

$featureDefaults = [ordered]@{}
foreach ($pair in [regex]::Matches($featureDefaultMatch.Groups[1].Value, '"([^"]+)"\s*,\s*([01])')) {
    $featureDefaults[$pair.Groups[1].Value] = $pair.Groups[2].Value
}
if ($featureDefaults.Count -eq 0) {
    Fail 'GetDefaultFeatureState() contains no parseable feature defaults'
}

$configFeatures = Read-IniSection $checkedInConfig 'Features'
foreach ($name in $featureDefaults.Keys) {
    if (-not $configFeatures.Contains($name)) {
        Fail "missing [Features] entry '$name'"
    }
    if ([string]$configFeatures[$name] -ne [string]$featureDefaults[$name]) {
        Fail "feature default '$name' differs between app/awful-cases.ini ($($configFeatures[$name])) and GetDefaultFeatureState() ($($featureDefaults[$name]))"
    }
}
if ($configFeatures.Count -ne $featureDefaults.Count) {
    Fail "feature default count differs between app/awful-cases.ini ($($configFeatures.Count)) and GetDefaultFeatureState() ($($featureDefaults.Count))"
}

$allowedMatch = [regex]::Match(
    $source,
    'global\s+AllowedFinalHotkeyKeys\s*:=\s*\[(.*?)\]\s*EnsureConfig\(\)',
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)
if (-not $allowedMatch.Success) {
    Fail 'could not extract AllowedFinalHotkeyKeys'
}

$allowedKeys = @(
    [regex]::Matches($allowedMatch.Groups[1].Value, '"([^"]+)"') |
        ForEach-Object { $_.Groups[1].Value }
)

$hotkeys = Read-IniSection $checkedInConfig 'Hotkeys'
$expectedHotkeys = @('Upper', 'Lower', 'Toggle', 'Title', 'Lint', 'Sentence', 'Settings')
foreach ($name in $expectedHotkeys) {
    if (-not $hotkeys.Contains($name)) {
        Fail "missing [Hotkeys] entry '$name'"
    }
    if ($hotkeys[$name] -notin $allowedKeys) {
        Fail "default hotkey '$name=$($hotkeys[$name])' is not allowed"
    }
}

$duplicateDefaults = @($hotkeys.Values | Group-Object | Where-Object Count -gt 1)
if ($duplicateDefaults.Count -gt 0) {
    Fail "default hotkeys are not unique: $(($duplicateDefaults | ForEach-Object Name) -join ', ')"
}

# The clipboard is allowed for capturing the selection, but not as the output transport.
# Restore the user's ClipboardAll before sending replacement text so a slow paste target
# cannot race restoration of the previous clipboard contents.
if ($source -match 'A_Clipboard\s*:=\s*changedText') {
    Fail 'TransformSelectedText still uses the clipboard as the output transport'
}
if ($source -notmatch 'SendText\s+changedText') {
    Fail 'TransformSelectedText must insert replacement text with SendText'
}
if ($source -notmatch 'try\s+A_Clipboard\s*:=\s*savedClipboard\s*\r?\n\s*SendText\s+changedText') {
    Fail 'the original clipboard must be restored immediately before SendText'
}

Write-Host 'Repository contracts passed.'
Write-Host "Version: $version"
Write-Host "Default hotkeys: $($hotkeys.Count)"
Write-Host "Default features: $($featureDefaults.Count)"
Write-Host 'CI contents permission: read-only'