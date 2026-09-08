param(
    [string]$AutoHotkeyPath
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$testFiles = Get-ChildItem (Join-Path $repoRoot 'tests') -Filter '*.ahk' | Sort-Object Name

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

if ($testFiles.Count -eq 0) {
    throw 'No AutoHotkey tests were found in tests/.'
}

Write-Host "AutoHotkey: $AutoHotkeyPath"
Write-Host "Test files: $($testFiles.Count)"

$failedTests = @()
foreach ($testFile in $testFiles) {
    Write-Host "`n==> $($testFile.Name)"
    $process = Start-Process -FilePath $AutoHotkeyPath -ArgumentList @('/ErrorStdOut', $testFile.FullName) -Wait -PassThru -NoNewWindow
    if ($process.ExitCode -ne 0) {
        $failedTests += "$($testFile.Name) (exit $($process.ExitCode))"
    }
}

if ($failedTests.Count -gt 0) {
    throw "Awful Cases tests failed: $($failedTests -join ', ')."
}

Write-Host "`nAll Awful Cases tests passed."
