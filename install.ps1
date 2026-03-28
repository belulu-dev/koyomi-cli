#Requires -Version 5.1
<#
.SYNOPSIS
    koyomi CLI installer for Windows
.DESCRIPTION
    Downloads and installs the latest koyomi CLI from GitHub Releases.
    Verifies SHA-256 checksum. Installs to ~/AppData/Local/koyomi-cli/.
.EXAMPLE
    irm https://raw.githubusercontent.com/belulu-dev/koyomi-cli/main/install.ps1 | iex
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Repo = 'belulu-dev/koyomi-cli'
$BinaryName = 'koyomi'
$InstallDir = if ($env:KOYOMI_INSTALL_DIR) { $env:KOYOMI_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA 'koyomi-cli' }

function Get-LatestVersion {
    $release = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest"
    $tag = $release.tag_name
    if ($tag -notmatch '^v(\d+\.\d+\.\d+)$') {
        throw "Invalid version format: $tag"
    }
    return $Matches[1]
}

function Get-Arch {
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    switch ($arch) {
        'X64'   { return 'amd64' }
        'Arm64' { return 'arm64' }
        default { throw "Unsupported architecture: $arch" }
    }
}

try {
    $version = Get-LatestVersion
    $arch = Get-Arch
    $archiveName = "$BinaryName-$version-windows-$arch"
    $archive = "$archiveName.zip"
    $checksums = "$BinaryName-$version-checksums.txt"
    $baseUrl = "https://github.com/$Repo/releases/download/v$version"

    Write-Host "Installing koyomi v$version (windows/$arch)..."

    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "koyomi-install-$(Get-Random)"
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

    try {
        Write-Host "Downloading $archive..."
        Invoke-WebRequest "$baseUrl/$archive" -OutFile (Join-Path $tmpDir $archive)
        Invoke-WebRequest "$baseUrl/$checksums" -OutFile (Join-Path $tmpDir $checksums)

        Write-Host 'Verifying checksum...'
        $expected = (Get-Content (Join-Path $tmpDir $checksums) | Select-String $archive).ToString().Split(' ')[0]
        if (-not $expected) { throw "Checksum not found for $archive" }
        $actual = (Get-FileHash (Join-Path $tmpDir $archive) -Algorithm SHA256).Hash.ToLower()
        if ($expected -ne $actual) {
            throw "Checksum mismatch`n  expected: $expected`n  actual:   $actual"
        }
        Write-Host 'Checksum OK.'

        Write-Host 'Extracting...'
        Expand-Archive (Join-Path $tmpDir $archive) -DestinationPath $tmpDir -Force

        if (-not (Test-Path $InstallDir)) {
            New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
        }
        $src = Join-Path $tmpDir $archiveName "$BinaryName.exe"
        $dst = Join-Path $InstallDir "$BinaryName.exe"
        Copy-Item $src $dst -Force

        # Add to user PATH if not already present
        $userPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
        if ($userPath -notlike "*$InstallDir*") {
            [Environment]::SetEnvironmentVariable('PATH', "$userPath;$InstallDir", 'User')
            Write-Host "Added $InstallDir to user PATH."
        }

        Write-Host ''
        Write-Host "Done! koyomi v$version installed to $dst"
        Write-Host "Restart your terminal, then run 'koyomi version' to verify."
    }
    finally {
        Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Error "Installation failed: $_"
    exit 1
}
