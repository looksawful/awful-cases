$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not $IsWindows) {
    throw 'Awful Cases packaging is supported only on Windows.'
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$version = (Get-Content -LiteralPath (Join-Path $repoRoot 'VERSION') -Raw).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') {
    throw "VERSION must contain x.y.z, got '$version'."
}

$AutoHotkeyVersion = '2.0.27'
$AutoHotkeySha256 = 'F72CAD4B98A7B5AA050B35D6DEAA0B0E3949929B2AAFF7D0D69858F1F380B3EF'
$AutoHotkeyUrl = "https://github.com/AutoHotkey/AutoHotkey/releases/download/v$AutoHotkeyVersion/AutoHotkey_$AutoHotkeyVersion.zip"

$Ahk2ExeVersion = '1.1.37.02a2'
$Ahk2ExeSha256 = 'C29B8C3A5124850D79FC9E66E2CA79677C377D7F31631AD3022BA159C5D9E3BE'
$Ahk2ExeUrl = "https://github.com/AutoHotkey/Ahk2Exe/releases/download/Ahk2Exe$Ahk2ExeVersion/Ahk2Exe$Ahk2ExeVersion.zip"

$InnoSetupVersion = '7.1.0'
$InnoSetupSha256 = '0362A383ED217D4C4239B5933866DD96D3EB2102737DA92F80F6057A4B40DF2F'
$InnoSetupUrl = "https://github.com/jrsoftware/issrc/releases/download/is-$($InnoSetupVersion.Replace('.', '_'))/innosetup-$InnoSetupVersion-x64.exe"

$buildRoot = Join-Path $repoRoot '.build\packaging'
$downloadsDir = Join-Path $buildRoot 'downloads'
$toolsDir = Join-Path $buildRoot 'tools'
$portableStage = Join-Path $buildRoot 'portable\Awful Cases'
$distDir = Join-Path $repoRoot 'dist'

Remove-Item -LiteralPath $buildRoot -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $distDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $downloadsDir, $toolsDir, $portableStage, $distDir -Force | Out-Null

function Get-VerifiedDownload {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][string]$Destination,
        [Parameter(Mandatory = $true)][string]$ExpectedSha256
    )

    Write-Host "Downloading: $Uri"
    Invoke-WebRequest -Uri $Uri -OutFile $Destination
    $actualSha256 = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash
    if ($actualSha256 -ne $ExpectedSha256) {
        Remove-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
        throw "SHA-256 mismatch for $Uri. Expected $ExpectedSha256, got $actualSha256."
    }
    Write-Host "Verified SHA-256: $actualSha256"
}

$autoHotkeyZip = Join-Path $downloadsDir "AutoHotkey_$AutoHotkeyVersion.zip"
$ahk2ExeZip = Join-Path $downloadsDir "Ahk2Exe$Ahk2ExeVersion.zip"
$innoSetupInstaller = Join-Path $downloadsDir "innosetup-$InnoSetupVersion-x64.exe"

Get-VerifiedDownload -Uri $AutoHotkeyUrl -Destination $autoHotkeyZip -ExpectedSha256 $AutoHotkeySha256
Get-VerifiedDownload -Uri $Ahk2ExeUrl -Destination $ahk2ExeZip -ExpectedSha256 $Ahk2ExeSha256
Get-VerifiedDownload -Uri $InnoSetupUrl -Destination $innoSetupInstaller -ExpectedSha256 $InnoSetupSha256

$autoHotkeyDir = Join-Path $toolsDir 'autohotkey'
$ahk2ExeDir = Join-Path $toolsDir 'ahk2exe'
$innoSetupDir = Join-Path $toolsDir 'inno'

Expand-Archive -LiteralPath $autoHotkeyZip -DestinationPath $autoHotkeyDir -Force
Expand-Archive -LiteralPath $ahk2ExeZip -DestinationPath $ahk2ExeDir -Force

$autoHotkeyBase = Get-ChildItem -LiteralPath $autoHotkeyDir -Recurse -Filter 'AutoHotkey64.exe' | Select-Object -First 1
if (-not $autoHotkeyBase) {
    throw 'AutoHotkey64.exe was not found after extraction.'
}

$ahk2Exe = Get-ChildItem -LiteralPath $ahk2ExeDir -Recurse -Filter 'Ahk2Exe.exe' | Select-Object -First 1
if (-not $ahk2Exe) {
    throw 'Ahk2Exe.exe was not found after extraction.'
}

$standaloneExe = Join-Path $distDir "Awful-Cases-$version-x64.exe"
& (Join-Path $PSScriptRoot 'build.ps1') -AutoHotkeyBasePath $autoHotkeyBase.FullName -Ahk2ExePath $ahk2Exe.FullName -OutputDirectory $distDir | Out-Host
if (-not (Test-Path -LiteralPath $standaloneExe -PathType Leaf)) {
    throw "Standalone executable was not produced: $standaloneExe"
}

Copy-Item -LiteralPath $standaloneExe -Destination (Join-Path $portableStage 'Awful-Cases.exe')
Copy-Item -LiteralPath (Join-Path $repoRoot 'app\awful-cases.ini') -Destination (Join-Path $portableStage 'awful-cases.ini')
Copy-Item -LiteralPath (Join-Path $repoRoot 'LICENSE') -Destination (Join-Path $portableStage 'LICENSE')
New-Item -ItemType File -Path (Join-Path $portableStage 'portable.flag') -Force | Out-Null

$portableZip = Join-Path $distDir "Awful-Cases-Portable-$version-x64.zip"
Compress-Archive -Path (Join-Path $portableStage '*') -DestinationPath $portableZip -CompressionLevel Optimal -Force
if (-not (Test-Path -LiteralPath $portableZip -PathType Leaf)) {
    throw "Portable package was not produced: $portableZip"
}

Write-Host "Installing pinned Inno Setup $InnoSetupVersion into temporary tooling directory."
& $innoSetupInstaller /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- "/DIR=$innoSetupDir"
if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup bootstrap installer failed with exit code $LASTEXITCODE."
}

$iscc = Get-ChildItem -LiteralPath $innoSetupDir -Recurse -Filter 'ISCC.exe' | Select-Object -First 1
if (-not $iscc) {
    throw 'ISCC.exe was not found after the pinned Inno Setup installation.'
}

$installerScript = Join-Path $repoRoot 'installer\awful-cases.iss'
Push-Location (Split-Path -Parent $installerScript)
try {
    & $iscc.FullName "/DMyAppVersion=$version" "/DSourceExe=$standaloneExe" $installerScript
    if ($LASTEXITCODE -ne 0) {
        throw "Inno Setup compiler failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}

$setupExe = Join-Path $distDir "Awful-Cases-Setup-$version-x64.exe"
if (-not (Test-Path -LiteralPath $setupExe -PathType Leaf)) {
    throw "Installer was not produced: $setupExe"
}

$checksumPath = Join-Path $distDir 'SHA256SUMS.txt'
$releaseFiles = @($standaloneExe, $portableZip, $setupExe) | ForEach-Object { Get-Item -LiteralPath $_ } | Sort-Object Name
$checksumLines = foreach ($file in $releaseFiles) {
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    "$hash  $($file.Name)"
}
$checksumLines | Set-Content -LiteralPath $checksumPath -Encoding utf8

foreach ($file in @($standaloneExe, $portableZip, $setupExe, $checksumPath)) {
    $item = Get-Item -LiteralPath $file
    Write-Host "Artifact: $($item.Name) ($($item.Length) bytes)"
}

Write-Host "Packaging complete for Awful Cases $version."
