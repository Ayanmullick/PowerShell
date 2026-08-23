<#
.SYNOPSIS
Downloads and validates the pinned nanoFramework runtime used by MicroPS.

.DESCRIPTION
Downloads the official ESP32_C6_THREAD 1.17.0.285 archive, verifies its exact SHA-256 digest, and extracts it beneath
MicroPS/.runtime. A valid cached archive is reused and extracted afresh whenever this script is run explicitly.

.EXAMPLE
PS> .\IoT\Get-MicroPSRuntime.ps1

Reuses a valid cached archive or downloads it when needed, then refreshes the extracted runtime.
#>

[CmdletBinding()]
param([string]$RuntimePath = (Join-Path $PSScriptRoot 'MicroPS\.runtime'))

$ErrorActionPreference = 'Stop'

$target,$version,$expectedHash = 'ESP32_C6_THREAD','1.17.0.285','096b533a8b6f22e59d3466545cd3b4a8d8b4cf24bd8249604380c6096e0f9b2f'
$uri = "https://dl.cloudsmith.io/public/net-nanoframework/nanoframework-images/raw/names/$target/versions/$version/$target-$version.zip"
$runtimeRoot = [IO.Path]::GetFullPath($RuntimePath)
$archivePath = Join-Path $runtimeRoot "$target-$version.zip"
$versionPath = Join-Path $runtimeRoot "$target-$version"
$downloadPath = Join-Path $runtimeRoot "$target-$version.download"
$extractPath = Join-Path $runtimeRoot ('.extracting-' + [Guid]::NewGuid().ToString('N'))
$requiredFiles = 'bootloader.bin','partitions_4mb.bin','nanoCLR.bin'
New-Item -ItemType Directory -Path $runtimeRoot -Force | Out-Null

$archiveValid = (Test-Path -LiteralPath $archivePath -PathType Leaf) -and
    ((Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash -eq $expectedHash)
try {
    if (-not $archiveValid) {
        Write-Verbose "Downloading $uri"
        Invoke-WebRequest -Uri $uri -OutFile $downloadPath
        $actualHash = (Get-FileHash -LiteralPath $downloadPath -Algorithm SHA256).Hash
        if ($actualHash -ne $expectedHash) { throw "Downloaded archive SHA-256 was '$actualHash'; expected '$expectedHash'." }
        Move-Item -LiteralPath $downloadPath -Destination $archivePath -Force
    }

    Expand-Archive -LiteralPath $archivePath -DestinationPath $extractPath
    foreach ($name in $requiredFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $extractPath $name) -PathType Leaf)) {
            throw "The authenticated archive does not contain '$name'."
        }
    }
    if (Test-Path -LiteralPath $versionPath) { Remove-Item -LiteralPath $versionPath -Recurse -Force }
    Move-Item -LiteralPath $extractPath -Destination $versionPath
}
finally {
    Remove-Item -LiteralPath $downloadPath,$extractPath -Recurse -Force -ErrorAction SilentlyContinue
}

[pscustomobject]@{Target = $target; Version = $version; Path = $versionPath; Archive = $archivePath; SHA256 = $expectedHash }
