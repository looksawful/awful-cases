param(
    [string]$OutputDirectory = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not $IsWindows) {
    throw 'Awful Cases packaging is supported only on Windows.'
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $repoRoot 'dist'
} elseif (-not [IO.Path]::IsPathRooted($OutputDirectory)) {
    $OutputDirectory = [IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputDirectory))
} else {
    $OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
}

$autoHotkeyVersion = '2.0.27'
$autoHotkeySha256 = 'F72CAD4B98A7B5AA050B35D6DEAA0B0E3949929B2AAFF7D0D69858F1F380B3EF'
$autoHotkeyUri = "https://github.com/AutoHotkey/AutoHotkey/releases/download/v$autoHotkeyVersion/AutoHotkey_$autoHotkeyVersion.zip"

$ahk2ExeVersion = '1.1.37.02a2'
$ahk2ExeSha256 = 'C29B8C3A5124850D79FC9E66E2CA79677C377D7F31631AD3022BA159C5D9E3BE'
$ahk2ExeUri = "https://github.com/AutoHotkey/Ahk2Exe/releases/download/Ahk2Exe$ahk2ExeVersion/Ahk2Exe$ahk2ExeVersion.zip"

function Require-File([string]$Path, [string]$Label) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Missing required $Label`: $Path"
    }
}

function Download-VerifiedArchive(
    [string]$Uri,
    [string]$Destination,
    [string]$ExpectedSha256,
    [string]$Label
) {
    Write-Host "Downloading $Label..."
    Invoke-WebRequest -Uri $Uri -OutFile $Destination
    $actualSha256 = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash.ToUpperInvariant()
    if ($actualSha256 -ne $ExpectedSha256.ToUpperInvariant()) {
        throw "$Label SHA-256 mismatch. Expected $ExpectedSha256, got $actualSha256."
    }
    Write-Host "$Label SHA-256 verified: $actualSha256"
}

function Wait-ForStableFile(
    [string]$Path,
    [int]$TimeoutSeconds = 30
) {
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    $lastLength = -1L
    $stableSamples = 0

    while ([DateTime]::UtcNow -lt $deadline) {
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            $length = (Get-Item -LiteralPath $Path).Length
            if ($length -gt 0 -and $length -eq $lastLength) {
                $stableSamples += 1
                if ($stableSamples -ge 3) {
                    return
                }
            } else {
                $stableSamples = 0
                $lastLength = $length
            }
        }
        Start-Sleep -Milliseconds 250
    }

    throw "Timed out waiting for generated file: $Path"
}

function Assert-SafeOutputDirectory(
    [string]$Path,
    [string]$RepositoryRoot
) {
    $normalizedOutput = [IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetFullPath($Path))
    $normalizedRepo = [IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetFullPath($RepositoryRoot))
    $driveRoot = [IO.Path]::GetPathRoot($normalizedOutput)

    if ($normalizedOutput -eq $normalizedRepo) {
        throw 'OutputDirectory must not be the repository root. Use dist/ or another dedicated output directory.'
    }
    if ($normalizedOutput -eq [IO.Path]::TrimEndingDirectorySeparator($driveRoot)) {
        throw 'OutputDirectory must not be a drive root.'
    }
}

$versionPath = Join-Path $repoRoot 'VERSION'
$sourceDir = Join-Path $repoRoot 'app'
$sourcePath = Join-Path $sourceDir 'awful-cases.ahk'
$iconPath = Join-Path $sourceDir 'awful-cases.ico'
$configPath = Join-Path $sourceDir 'awful-cases.ini'
$licensePath = Join-Path $repoRoot 'LICENSE'
$repoContractPath = Join-Path $repoRoot 'tests\repo-contract.ps1'

Require-File $versionPath 'VERSION file'
Require-File $sourcePath 'application source'
Require-File (Join-Path $sourceDir 'lib\text-transforms.ahk') 'transform core'
Require-File $iconPath 'application icon'
Require-File $configPath 'default configuration'
Require-File $licensePath 'license'
Require-File $repoContractPath 'repository contract test'

$version = (Get-Content -LiteralPath $versionPath -Raw).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') {
    throw "VERSION must contain x.y.z, got '$version'."
}
$versionResource = "$version.0"

Write-Host 'Running repository contracts before packaging...'
& pwsh -NoProfile -File $repoContractPath
if ($LASTEXITCODE -ne 0) {
    throw "Repository contracts failed with exit code $LASTEXITCODE."
}

Assert-SafeOutputDirectory $OutputDirectory $repoRoot
if (Test-Path -LiteralPath $OutputDirectory -PathType Leaf) {
    throw "OutputDirectory points to an existing file: $OutputDirectory"
}
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$exeName = "awful-cases-v$version-windows-x64.exe"
$zipName = "awful-cases-v$version-windows-x64.zip"
$exeOut = Join-Path $OutputDirectory $exeName
$zipOut = Join-Path $OutputDirectory $zipName
$checksumOut = Join-Path $OutputDirectory 'SHA256SUMS.txt'

# Preserve unrelated files in caller-supplied output directories. Only package-owned
# artifacts for the current version are replaced.
foreach ($artifactPath in @($exeOut, $zipOut, $checksumOut)) {
    if (Test-Path -LiteralPath $artifactPath -PathType Container) {
        throw "Package output path is occupied by a directory: $artifactPath"
    }
    if (Test-Path -LiteralPath $artifactPath -PathType Leaf) {
        Remove-Item -LiteralPath $artifactPath -Force
    }
}

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("awful-cases-package-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

try {
    $ahkZip = Join-Path $tempRoot 'autohotkey.zip'
    $ahkRoot = Join-Path $tempRoot 'autohotkey'
    $ahk2ExeZip = Join-Path $tempRoot 'ahk2exe.zip'
    $ahk2ExeExtract = Join-Path $tempRoot 'ahk2exe-extract'

    Download-VerifiedArchive $autoHotkeyUri $ahkZip $autoHotkeySha256 "AutoHotkey v$autoHotkeyVersion"
    Expand-Archive -LiteralPath $ahkZip -DestinationPath $ahkRoot -Force

    $baseExe = Get-ChildItem -LiteralPath $ahkRoot -Recurse -Filter 'AutoHotkey64.exe' -File | Select-Object -First 1
    if (-not $baseExe) {
        throw 'AutoHotkey64.exe was not found in the verified AutoHotkey archive.'
    }

    Download-VerifiedArchive $ahk2ExeUri $ahk2ExeZip $ahk2ExeSha256 "Ahk2Exe v$ahk2ExeVersion"
    Expand-Archive -LiteralPath $ahk2ExeZip -DestinationPath $ahk2ExeExtract -Force

    $compilerDir = Join-Path $baseExe.Directory.FullName 'Compiler'
    New-Item -ItemType Directory -Path $compilerDir -Force | Out-Null
    Copy-Item -Path (Join-Path $ahk2ExeExtract '*') -Destination $compilerDir -Recurse -Force
    $compilerPath = Get-ChildItem -LiteralPath $compilerDir -Recurse -Filter 'Ahk2Exe.exe' -File | Select-Object -First 1
    if (-not $compilerPath) {
        throw 'Ahk2Exe.exe was not found in the verified Ahk2Exe archive.'
    }

    $buildAppDir = Join-Path $tempRoot 'app'
    New-Item -ItemType Directory -Path $buildAppDir -Force | Out-Null
    Copy-Item -Path (Join-Path $sourceDir '*') -Destination $buildAppDir -Recurse -Force
    $buildSource = Join-Path $buildAppDir 'awful-cases.ahk'
    $buildIcon = Join-Path $buildAppDir 'awful-cases.ico'

    $directives = @(
        ';@Ahk2Exe-SetName Awful Cases',
        ';@Ahk2Exe-SetDescription Windows tray utility for changing text case and cleaning typography.',
        ";@Ahk2Exe-SetVersion $versionResource",
        ';@Ahk2Exe-SetOrigFilename awful-cases.exe',
        ';@Ahk2Exe-SetCompanyName looksawful',
        ';@Ahk2Exe-SetCopyright Copyright (c) 2026 Ivan Krushinsky'
    ) -join "`r`n"
    $sourceText = Get-Content -LiteralPath $buildSource -Raw
    [IO.File]::WriteAllText(
        $buildSource,
        $directives + "`r`n" + $sourceText,
        [Text.UTF8Encoding]::new($false)
    )

    Write-Host "Compiling $exeName with Ahk2Exe v$ahk2ExeVersion / AutoHotkey v$autoHotkeyVersion..."
    Write-Host "Build source: $buildSource (exists: $(Test-Path -LiteralPath $buildSource))"
    & $compilerPath.FullName /in $buildSource /out $exeOut /icon $buildIcon /base $baseExe.FullName /silent verbose
    $compilerExit = $LASTEXITCODE
    if ($compilerExit -ne 0) {
        throw "Ahk2Exe launcher failed with exit code $compilerExit."
    }

    # Ahk2Exe can hand work to another process and return before the output file is complete.
    # Keep the temporary source alive and wait for a stable non-empty executable before cleanup.
    Wait-ForStableFile $exeOut
    Require-File $exeOut 'compiled executable'

    $versionInfo = (Get-Item -LiteralPath $exeOut).VersionInfo
    if ($versionInfo.FileVersion -ne $versionResource) {
        throw "Compiled executable FileVersion '$($versionInfo.FileVersion)' does not match '$versionResource'."
    }
    if ($versionInfo.ProductVersion -ne $versionResource) {
        throw "Compiled executable ProductVersion '$($versionInfo.ProductVersion)' does not match '$versionResource'."
    }

    $portableRootName = "awful-cases-v$version-windows-x64"
    $portableRoot = Join-Path $tempRoot $portableRootName
    New-Item -ItemType Directory -Path $portableRoot -Force | Out-Null
    Copy-Item -LiteralPath $exeOut -Destination (Join-Path $portableRoot 'awful-cases.exe')
    Copy-Item -LiteralPath $configPath -Destination (Join-Path $portableRoot 'awful-cases.ini')
    Copy-Item -LiteralPath $licensePath -Destination (Join-Path $portableRoot 'LICENSE')
    Copy-Item -LiteralPath $versionPath -Destination (Join-Path $portableRoot 'VERSION')

    $releaseReadme = @"
Awful Cases $version

Portable Windows x64 package.

Run awful-cases.exe. Settings are stored in awful-cases.ini beside the executable.
If the INI file is removed, Awful Cases creates a fresh default configuration on next start.

This build is unsigned and is not an installer. Windows may show SmartScreen or reputation warnings for an unsigned application. Do not disable Windows security protections to run it.

Project: https://github.com/looksawful/awful-cases
Website: https://looksawful.github.io/awful-cases/
License: MIT (see LICENSE)
"@
    [IO.File]::WriteAllText(
        (Join-Path $portableRoot 'README.txt'),
        $releaseReadme.Trim() + "`r`n",
        [Text.UTF8Encoding]::new($false)
    )

    Compress-Archive -LiteralPath $portableRoot -DestinationPath $zipOut -CompressionLevel Optimal -Force
    Require-File $zipOut 'portable ZIP'

    $hashLines = foreach ($artifact in @($exeOut, $zipOut)) {
        $hash = (Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash.ToLowerInvariant()
        "$hash  $(Split-Path -Leaf $artifact)"
    }
    [IO.File]::WriteAllLines($checksumOut, $hashLines, [Text.UTF8Encoding]::new($false))

    $verifyRoot = Join-Path $tempRoot 'verify-zip'
    Expand-Archive -LiteralPath $zipOut -DestinationPath $verifyRoot -Force
    foreach ($requiredName in @('awful-cases.exe', 'awful-cases.ini', 'LICENSE', 'VERSION', 'README.txt')) {
        Require-File (Join-Path $verifyRoot "$portableRootName\$requiredName") "portable ZIP member '$requiredName'"
    }

    Write-Host ''
    Write-Host 'Awful Cases package completed.'
    Write-Host "Version: $version"
    Write-Host "EXE: $exeOut"
    Write-Host "ZIP: $zipOut"
    Write-Host "Checksums: $checksumOut"
} finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
