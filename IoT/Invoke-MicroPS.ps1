<#
.SYNOPSIS
Builds MicroPS for Wokwi or deploys it to a provisioned nanoFramework device.

.DESCRIPTION
When executed with -UseSimulator, builds MicroPS with MSBuild and stages the pinned nanoCLR runtime plus the managed
deployment image in build/wokwi. With -UseDevice, builds and deploys the managed image through the nanoFramework Wire
Protocol without updating the device runtime. Dot-source this script to load the serial controller commands.

.EXAMPLE
PS> .\IoT\Invoke-MicroPS.ps1 -UseSimulator -Verbose

Builds MicroPS and prepares build/wokwi/flasher_args.json for the Wokwi VS Code extension.

.EXAMPLE
PS> .\IoT\Invoke-MicroPS.ps1 -UseDevice -DeploymentPort COM4 -Verbose

Builds and deploys MicroPS to an already provisioned nanoFramework device on its deployment port.

.EXAMPLE
PS> . .\IoT\Invoke-MicroPS.ps1
PS> Connect-MicroPS -UseSimulator
PS> Turn-On
PS> Turn-Off
PS> Continue-Blink
PS> Disconnect-MicroPS

Controls the running Wokwi simulation through its RFC2217 endpoint.

.EXAMPLE
PS> . .\IoT\Invoke-MicroPS.ps1
PS> Connect-MicroPS -UseDevice -ApplicationPort COM5
PS> Set-MicroPSLed -State Blink

Controls a physical device through a separate USB-to-UART adapter connected to GPIO16/TX and GPIO17/RX.
#>

[CmdletBinding(DefaultParameterSetName = 'Load', SupportsShouldProcess)]
param(
    [Parameter(Mandatory, ParameterSetName = 'Simulator')] [switch]$UseSimulator,
    [Parameter(Mandatory, ParameterSetName = 'Device')] [switch]$UseDevice,
    [Parameter(Mandatory, ParameterSetName = 'Device')] [ValidateNotNullOrEmpty()] [string]$DeploymentPort,
    [string]$ProjectPath = (Join-Path $PSScriptRoot 'MicroPS\MicroPS.sln'),
    [ValidateSet('Debug', 'Release')] [string]$Configuration = 'Debug',
    [string]$RuntimePath = (Join-Path $PSScriptRoot 'MicroPS\.runtime'),
    [string]$MSBuildPath, [string]$NanoFrameworkProjectSystemPath
)

if ($MyInvocation.InvocationName -eq '.') { . (Join-Path $PSScriptRoot 'MicroPS.Controller.ps1'); return }

function Resolve-MicroPSMSBuild {
    param([string]$Path)
    if ($Path) { return (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path }
    $command = Get-Command MSBuild.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { return $command.Path }
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (Test-Path -LiteralPath $vswhere -PathType Leaf) {
        $arguments = @('-products', '*', '-all', '-prerelease', '-requires', 'Microsoft.Component.MSBuild')
        foreach ($pattern in 'MSBuild\**\Bin\amd64\MSBuild.exe', 'MSBuild\**\Bin\MSBuild.exe') {
            $match = & $vswhere @arguments -find $pattern 2>$null | Select-Object -First 1
            if ($match) { return $match }
        }
    }
    throw 'MSBuild was not found. Install Visual Studio Build Tools with the managed desktop build workload.'
}

function Resolve-MicroPSNanoff {
    $command = Get-Command nanoff -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { return $command.Path }
    $fallback = Join-Path $env:USERPROFILE '.dotnet\tools\nanoff.exe'
    if (Test-Path -LiteralPath $fallback -PathType Leaf) { return $fallback }
    throw "'nanoff' is required for -UseDevice but is not installed or available on PATH."
}

function Resolve-MicroPSProjectSystem {
    param([string]$Path)
    if ($Path) {
        $resolved = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
        if (Test-Path -LiteralPath (Join-Path $resolved 'NFProjectSystem.CSharp.targets') -PathType Leaf) { return $resolved }
        throw "The nanoFramework project system is incomplete at '$resolved'."
    }
    $roots = (Join-Path $env:USERPROFILE '.vscode-insiders\extensions'), (Join-Path $env:USERPROFILE '.vscode\extensions')
    $extensions = foreach ($root in $roots) {
        Get-ChildItem -LiteralPath $root -Directory -Filter 'nanoframework.vscode-nanoframework-*' -ErrorAction SilentlyContinue
    }
    foreach ($extension in ($extensions | Sort-Object LastWriteTime -Descending)) {
        $candidate = Join-Path $extension.FullName 'dist\utils\nanoFramework\v1.0'
        if (Test-Path -LiteralPath (Join-Path $candidate 'NFProjectSystem.CSharp.targets') -PathType Leaf) { return $candidate }
    }
    throw 'The nanoFramework VS Code extension project system was not found in VS Code or VS Code Insiders.'
}

if (-not ($UseSimulator -or $UseDevice)) {
    throw "Specify -UseSimulator or -UseDevice, or dot-source this script to load the MicroPS controller commands."
}

$solution = (Resolve-Path -LiteralPath $ProjectPath -ErrorAction Stop).Path
$solutionRoot = Split-Path -Parent $solution
$projects = @(Get-ChildItem -LiteralPath $solutionRoot -Recurse -File -Filter 'MicroPS.nfproj')
if ($projects.Count -ne 1) { throw "Expected one MicroPS.nfproj below '$solutionRoot'; found $($projects.Count)." }
$outputPath = Join-Path $projects[0].Directory.FullName "bin\$Configuration"
$managedPe, $managedImage = (Join-Path $outputPath 'MicroPS.pe'), (Join-Path $outputPath 'MicroPS.bin')

$msbuild = Resolve-MicroPSMSBuild -Path $MSBuildPath
$projectSystem = Resolve-MicroPSProjectSystem -Path $NanoFrameworkProjectSystemPath
$buildArguments = @(
    $solution, '/t:Rebuild', '/nologo', '/verbosity:minimal', '/p:Platform=Any CPU', "/p:Configuration=$Configuration"
    "/p:NanoFrameworkProjectSystemPath=$($projectSystem.TrimEnd('\', '/'))/", '/p:UseSharedCompilation=false'
)
Write-Verbose "Building '$solution' with '$msbuild'."
& $msbuild @buildArguments
if ($LASTEXITCODE -ne 0) { throw "MSBuild failed with exit code $LASTEXITCODE." }
foreach ($artifact in $managedPe, $managedImage) {
    if (-not (Test-Path -LiteralPath $artifact -PathType Leaf)) { throw "The build did not produce '$artifact'." }
}

$deploymentBytes = (Get-Item -LiteralPath $managedImage).Length
$deploymentLimit = 0x170000
if ($deploymentBytes -gt $deploymentLimit) { throw "MicroPS.bin exceeds the 0x170000-byte deployment partition." }
if ($UseDevice) {
    $deployed = $PSCmdlet.ShouldProcess("nanoFramework device on $DeploymentPort", "Deploy '$managedImage'")
    if ($deployed) {
        $nanoff = Resolve-MicroPSNanoff
        $nanoffArguments = '--nanodevice', '--deploy', '--serialport', $DeploymentPort, '--image', $managedImage,
            '--suppressnanoffversioncheck'
        Write-Verbose "Deploying '$managedImage' to nanoFramework device on $DeploymentPort with '$nanoff'."
        & $nanoff @nanoffArguments
        if ($LASTEXITCODE -ne 0) { throw "nanoff deployment failed with exit code $LASTEXITCODE." }
    }
    [pscustomobject]@{
        Target = 'Device'; Solution = $solution; ManagedImage = $managedImage
        DeploymentBytes = $deploymentBytes; DeploymentPort = $DeploymentPort; Deployed = $deployed
    }
    return
}

$runtimeRoot = (Resolve-Path -LiteralPath $RuntimePath -ErrorAction Stop).Path
$runtimeVersion, $runtimeHash = '1.17.0.285', '096b533a8b6f22e59d3466545cd3b4a8d8b4cf24bd8249604380c6096e0f9b2f'
$runtimeArchive = Join-Path $runtimeRoot "ESP32_C6_THREAD-$runtimeVersion.zip"
$runtimeVersionPath = Join-Path $runtimeRoot "ESP32_C6_THREAD-$runtimeVersion"
if (-not (Test-Path -LiteralPath $runtimeArchive -PathType Leaf)) {
    throw "Pinned nanoCLR runtime not found. Run '.\IoT\Get-MicroPSRuntime.ps1'."
}
if ((Get-FileHash -LiteralPath $runtimeArchive -Algorithm SHA256).Hash -ne $runtimeHash) {
    throw "The pinned nanoCLR archive failed SHA-256 validation: '$runtimeArchive'."
}
$runtimeFiles = @{}
foreach ($name in 'bootloader.bin', 'partitions_4mb.bin', 'nanoCLR.bin') {
    $runtimeFiles[$name] = Join-Path $runtimeVersionPath $name
    if (-not (Test-Path -LiteralPath $runtimeFiles[$name] -PathType Leaf)) {
        throw "Pinned runtime file not found: '$($runtimeFiles[$name])'. Run '.\IoT\Get-MicroPSRuntime.ps1'."
    }
}

$layout = @(
    @{Name = 'bootloader.bin'; Offset = 0x0; Limit = 0x8000 }
    @{Name = 'partitions_4mb.bin'; Offset = 0x8000; Limit = 0x8000 }
    @{Name = 'nanoCLR.bin'; Offset = 0x10000; Limit = 0x240000 }
    @{Name = 'MicroPS.bin'; Offset = 0x250000; Limit = $deploymentLimit }
)
$stagePath = Join-Path $solutionRoot 'build\wokwi'
New-Item -ItemType Directory -Path $stagePath -Force | Out-Null
foreach ($entry in $layout) {
    $source = $entry.Name -eq 'MicroPS.bin' ? $managedImage : $runtimeFiles[$entry.Name]
    if ((Get-Item -LiteralPath $source).Length -gt $entry.Limit) {
        throw "$($entry.Name) overlaps the next approved flash region at offset 0x$('{0:X}' -f $entry.Offset)."
    }
    Copy-Item -LiteralPath $source -Destination (Join-Path $stagePath $entry.Name) -Force
}

$flasherArguments = [ordered]@{
    write_flash_args = @('--flash_mode', 'dio', '--flash_size', '4MB', '--flash_freq', '40m')
    flash_settings = [ordered]@{flash_mode = 'dio'; flash_size = '4MB'; flash_freq = '40m' }
    flash_files = [ordered]@{
        '0x0' = 'bootloader.bin'; '0x8000' = 'partitions_4mb.bin'
        '0x10000' = 'nanoCLR.bin'; '0x250000' = 'MicroPS.bin'
    }
    extra_esptool_args = [ordered]@{after = 'hard_reset'; before = 'default_reset'; stub = $true; chip = 'esp32c6' }
}
$manifest = Join-Path $stagePath 'flasher_args.json'
$flasherArguments | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $manifest -Encoding utf8

[pscustomobject]@{
    Target = 'Simulator'; Solution = $solution; ManagedImage = $managedImage; DeploymentBytes = $deploymentBytes
    WokwiManifest = $manifest; RuntimeVersion = $runtimeVersion
}
