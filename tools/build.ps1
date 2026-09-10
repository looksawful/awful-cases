param(
    [Parameter(Mandatory = $true)]
    [string]$AutoHotkeyBasePath,

    [Parameter(Mandatory = $true)]
    [string]$Ahk2ExePath,

    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not $OutputDirectory) {
    $OutputDirectory = Join-Path $repoRoot 'dist'
}

$version = (Get-Content -LiteralPath (Join-Path $repoRoot 'VERSION') -Raw).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') {
    throw "VERSION must contain x.y.z, got '$version'."
}

$sourcePath = Join-Path $repoRoot 'app\awful-cases.ahk'
$iconPath = Join-Path $repoRoot 'app\awful-cases.ico'

foreach ($requiredPath in @($sourcePath, $iconPath, $AutoHotkeyBasePath, $Ahk2ExePath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required build input was not found: $requiredPath"
    }
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$outputPath = Join-Path $OutputDirectory "Awful-Cases-$version-x64.exe"
Remove-Item -LiteralPath $outputPath -Force -ErrorAction SilentlyContinue

Write-Host "Compiling Awful Cases $version"
Write-Host "Source: $sourcePath"
Write-Host "Output: $outputPath"

& $Ahk2ExePath /in $sourcePath /out $outputPath /base $AutoHotkeyBasePath /icon $iconPath /silent verbose
if ($LASTEXITCODE -ne 0) {
    throw "Ahk2Exe failed with exit code $LASTEXITCODE."
}

if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
    throw "Ahk2Exe did not create the expected executable: $outputPath"
}

$builtFile = Get-Item -LiteralPath $outputPath
if ($builtFile.Length -le 0) {
    throw "Compiled executable is empty: $outputPath"
}

Write-Host "Built: $($builtFile.FullName) ($($builtFile.Length) bytes)"
Write-Output $builtFile.FullName
