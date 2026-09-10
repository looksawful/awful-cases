param(
    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$version = (Get-Content -LiteralPath (Join-Path $repoRoot 'VERSION') -Raw).Trim()
$outputRoot = (Resolve-Path -LiteralPath $OutputDirectory).Path

function Fail([string]$Message) {
    throw "Package output verification failed: $Message"
}

function Require-File([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Fail "missing file '$Path'"
    }
}

$exeName = "awful-cases-v$version-windows-x64.exe"
$zipName = "awful-cases-v$version-windows-x64.zip"
$exePath = Join-Path $outputRoot $exeName
$zipPath = Join-Path $outputRoot $zipName
$checksumPath = Join-Path $outputRoot 'SHA256SUMS.txt'

Require-File $exePath
Require-File $zipPath
Require-File $checksumPath

$versionInfo = (Get-Item -LiteralPath $exePath).VersionInfo
if ([string]::IsNullOrWhiteSpace($versionInfo.FileVersion) -or -not $versionInfo.FileVersion.StartsWith($version)) {
    Fail "compiled FileVersion '$($versionInfo.FileVersion)' does not match VERSION '$version'"
}

$checksumLines = @(Get-Content -LiteralPath $checksumPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
if ($checksumLines.Count -ne 2) {
    Fail "SHA256SUMS.txt must contain exactly two artifact lines, got $($checksumLines.Count)"
}

foreach ($artifact in @($exePath, $zipPath)) {
    $name = Split-Path -Leaf $artifact
    $actual = (Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash.ToLowerInvariant()
    $expectedLine = "$actual  $name"
    if ($expectedLine -notin $checksumLines) {
        Fail "SHA256SUMS.txt does not contain the verified digest for '$name'"
    }
}

$verifyRoot = Join-Path ([IO.Path]::GetTempPath()) ("awful-cases-package-output-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $verifyRoot -Force | Out-Null
try {
    Expand-Archive -LiteralPath $zipPath -DestinationPath $verifyRoot -Force
    $portableDir = Join-Path $verifyRoot "awful-cases-v$version-windows-x64"
    foreach ($name in @('awful-cases.exe', 'awful-cases.ini', 'LICENSE', 'VERSION', 'README.txt')) {
        Require-File (Join-Path $portableDir $name)
    }

    $packagedVersion = (Get-Content -LiteralPath (Join-Path $portableDir 'VERSION') -Raw).Trim()
    if ($packagedVersion -ne $version) {
        Fail "portable ZIP VERSION '$packagedVersion' does not match repository VERSION '$version'"
    }

    $packagedExeVersion = (Get-Item -LiteralPath (Join-Path $portableDir 'awful-cases.exe')).VersionInfo.FileVersion
    if ([string]::IsNullOrWhiteSpace($packagedExeVersion) -or -not $packagedExeVersion.StartsWith($version)) {
        Fail "portable ZIP executable FileVersion '$packagedExeVersion' does not match VERSION '$version'"
    }
} finally {
    Remove-Item -LiteralPath $verifyRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host 'Package output verification passed.'
Write-Host "Version: $version"
Write-Host "EXE: $exeName"
Write-Host "ZIP: $zipName"
