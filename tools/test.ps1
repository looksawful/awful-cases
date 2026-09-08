param(
    [string]$AutoHotkeyPath
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$testFile = Join-Path $repoRoot 'tests\text-transforms.ahk'

if (-not $AutoHotkeyPath) {
    $candidates = @(
        (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey64.exe'),
        (Join-Path $env:ProgramFiles 'AutoHotkey\AutoHotkey.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'AutoHotkey\v2\AutoHotkey64.exe')
    ) | Where-Object { $_ -and (Test-Path $_) }

    if ($candidates.Count -gt 0) {
        $AutoHotkeyPath = $candidates[0]
    }
}

if (-not $AutoHotkeyPath) {
    $command = Get-Command AutoHotkey64.exe, AutoHotkey.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) {
        $AutoHotkeyPath = $command.Source
    }
}

if (-not $AutoHotkeyPath -or -not (Test-Path $AutoHotkeyPath)) {
    throw 'AutoHotkey v2 was not found. Install AutoHotkey v2 or pass -AutoHotkeyPath <path-to-exe>.'
}

Write-Host "AutoHotkey: $AutoHotkeyPath"
Write-Host "Tests:       $testFile"

& $AutoHotkeyPath /ErrorStdOut $testFile
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
    throw "Awful Cases tests failed with exit code $exitCode."
}

Write-Host 'Awful Cases tests passed.'
