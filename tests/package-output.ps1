param(
    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$version = (Get-Content -LiteralPath (Join-Path $repoRoot 'VERSION') -Raw).Trim()
$versionResource = "$version.0"
$outputRoot = (Resolve-Path -LiteralPath $OutputDirectory).Path

function Fail([string]$Message) {
    throw "Package output verification failed: $Message"
}

function Require-File([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Fail "missing file '$Path'"
    }
}

function Assert-ExeMetadata([string]$Path, [string]$Label) {
    $info = (Get-Item -LiteralPath $Path).VersionInfo
    if ($info.FileVersion -ne $versionResource) {
        Fail "$Label FileVersion '$($info.FileVersion)' does not equal '$versionResource'"
    }
    if ($info.ProductVersion -ne $versionResource) {
        Fail "$Label ProductVersion '$($info.ProductVersion)' does not equal '$versionResource'"
    }
    if ($info.ProductName -ne 'Awful Cases') {
        Fail "$Label ProductName '$($info.ProductName)' does not equal 'Awful Cases'"
    }
    if ($info.OriginalFilename -ne 'awful-cases.exe') {
        Fail "$Label OriginalFilename '$($info.OriginalFilename)' does not equal 'awful-cases.exe'"
    }
    if ($info.CompanyName -ne 'looksawful') {
        Fail "$Label CompanyName '$($info.CompanyName)' does not equal 'looksawful'"
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
Assert-ExeMetadata $exePath 'standalone executable'

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

    Assert-ExeMetadata (Join-Path $portableDir 'awful-cases.exe') 'portable ZIP executable'
} finally {
    Remove-Item -LiteralPath $verifyRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host 'Package output verification passed.'
Write-Host "Version: $version"
Write-Host "EXE: $exeName"
Write-Host "ZIP: $zipName"
Write-Host "PE metadata: FileVersion/ProductVersion=$versionResource, ProductName/OriginalFilename/CompanyName verified"
