$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not $IsWindows) {
    throw 'Awful Cases installer smoke is supported only on Windows.'
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$version = (Get-Content -LiteralPath (Join-Path $repoRoot 'VERSION') -Raw).Trim()
$setupExe = Join-Path $repoRoot "dist\Awful-Cases-Setup-$version-x64.exe"
if (-not (Test-Path -LiteralPath $setupExe -PathType Leaf)) {
    throw "Installer smoke requires the packaged installer: $setupExe"
}

$runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$runName = 'Awful Cases'
$installRoot = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { [System.IO.Path]::GetTempPath() }
$installDir = Join-Path $installRoot ("awful-cases-install-smoke-" + [guid]::NewGuid().ToString('N'))

function Get-RunValueState {
    try {
        $value = Get-ItemPropertyValue -Path $runKey -Name $runName -ErrorAction Stop
        return [pscustomobject]@{ Exists = $true; Value = [string]$value }
    }
    catch {
        return [pscustomobject]@{ Exists = $false; Value = $null }
    }
}

function Invoke-CheckedInstallerProcess {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList,
        [Parameter(Mandatory = $true)][string]$DisplayName
    )

    $process = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        throw "$DisplayName failed with exit code $($process.ExitCode)."
    }
}

$originalRunValue = Get-RunValueState
try {
    $installArgs = @(
        '/VERYSILENT',
        '/SUPPRESSMSGBOXES',
        '/NORESTART',
        '/SP-',
        '/MERGETASKS="!startup"',
        "/DIR=`"$installDir`""
    )
    Invoke-CheckedInstallerProcess -FilePath $setupExe -ArgumentList $installArgs -DisplayName 'Awful Cases installer'

    $installedExe = Join-Path $installDir 'Awful-Cases.exe'
    $uninstaller = Join-Path $installDir 'unins000.exe'
    if (-not (Test-Path -LiteralPath $installedExe -PathType Leaf)) {
        throw "Installed executable was not found: $installedExe"
    }
    if (-not (Test-Path -LiteralPath $uninstaller -PathType Leaf)) {
        throw "Generated uninstaller was not found: $uninstaller"
    }

    New-Item -Path $runKey -Force | Out-Null
    Set-ItemProperty -Path $runKey -Name $runName -Value ('"' + $installedExe + '"') -Type String
    $enabledState = Get-RunValueState
    if (-not $enabledState.Exists) {
        throw 'Smoke setup could not create the Awful Cases startup value.'
    }

    $uninstallArgs = @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART')
    Invoke-CheckedInstallerProcess -FilePath $uninstaller -ArgumentList $uninstallArgs -DisplayName 'Awful Cases uninstaller'

    if (Test-Path -LiteralPath $installedExe -PathType Leaf) {
        throw "Uninstall left the application executable behind: $installedExe"
    }
    $afterUninstall = Get-RunValueState
    if ($afterUninstall.Exists) {
        throw 'Uninstall left the Awful Cases current-user startup value behind.'
    }

    Write-Host "Installer lifecycle smoke passed for Awful Cases $version."
}
finally {
    if ($originalRunValue.Exists) {
        New-Item -Path $runKey -Force | Out-Null
        Set-ItemProperty -Path $runKey -Name $runName -Value $originalRunValue.Value -Type String
    }
    else {
        Remove-ItemProperty -Path $runKey -Name $runName -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath $installDir -Recurse -Force -ErrorAction SilentlyContinue
}
