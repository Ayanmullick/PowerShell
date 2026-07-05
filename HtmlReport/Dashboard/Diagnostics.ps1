param(
    [Parameter(Mandatory)][datetime] $Now,
    [ValidateRange(1, 120)][int] $SampleCount = 12,
    [ValidateRange(1, 30)][int] $SampleIntervalSeconds = 1,
    [ValidateRange(1, 168)][int] $EventHours = 24,
    [ValidateRange(5, 50)][int] $TopProcessCount = 12,
    [ValidateRange(1, 20)][int] $TopFolderCount = 5,
    [ValidateRange(5, 300)][int] $TopFolderScanSeconds = 60,
    [ValidateRange(100, 10000)][int] $MaxEvents = 2000,
    [string] $SruPath,
    [string] $SoftwareHivePath
)

$ErrorActionPreference = 'Stop'

#region General helpers

function Invoke-Safe {
    param(
        [Parameter(Mandatory)][string] $Name,
        [Parameter(Mandatory)][scriptblock] $ScriptBlock,
        [object] $Fallback = $null
    )

    try {
        & $ScriptBlock
    } catch {
        Write-Warning ("Skipping {0}: {1}" -f $Name, $_.Exception.Message)
        $Fallback
    }
}

function ConvertTo-Percent {
    param([double] $Value)

    [math]::Round([math]::Max(0, [math]::Min(100, $Value)), 1)
}

function Get-CounterValue {
    param([object] $Sample, [string] $PathLike)

    $Match = $Sample.CounterSamples | Where-Object Path -Like $PathLike | Select-Object -First 1
    if ($null -eq $Match) { return 0 }
    [double] $Match.CookedValue
}

function Get-FolderSizeGB {
    param([Parameter(Mandatory)][string] $Path)

    $Scratch = Join-Path ([IO.Path]::GetTempPath()) 'WinDiagFolderSizeScratch'
    New-Item -ItemType Directory -Path $Scratch -Force | Out-Null

    $Output = & robocopy $Path $Scratch /L /S /BYTES /XJ /R:0 /W:0 /NFL /NDL /NJH /NP 2>$null
    $BytesLine = $Output | Where-Object { $_ -match '^\s*Bytes\s*:\s*\d+' } | Select-Object -Last 1
    if ($BytesLine -match '^\s*Bytes\s*:\s*(\d+)') { return [math]::Round(([double]$Matches[1] / 1GB), 1) }
    0
}

function Get-TopFolderUsage {
    param([Parameter(Mandatory)][string] $Drive, [int] $Count = 5, [double] $DriveSizeGB = 0, [int] $MaxSeconds = 60)

    $Root = if ($Drive.EndsWith('\')) { $Drive } else { "$Drive\" }
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) { return @() }

    $Stopwatch = [Diagnostics.Stopwatch]::StartNew()
    $PriorityNames = 'Users', 'Program Files', 'Program Files (x86)', 'ProgramData', 'Windows'
    $Folders = @(Get-ChildItem -LiteralPath $Root -Directory -Force -ErrorAction SilentlyContinue | Where-Object { -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) })
    $Folders = @($Folders | Sort-Object @{ Expression = { [array]::IndexOf($PriorityNames, $_.Name) -lt 0 } }, @{ Expression = { [array]::IndexOf($PriorityNames, $_.Name) } }, Name)

    $ScannedPaths, $ScanCapped = @{}, $false
    $FolderSizes = @(
        foreach ($Folder in $Folders) {
            if ($Stopwatch.Elapsed.TotalSeconds -ge $MaxSeconds) { $ScanCapped = $true; break }
            $ScannedPaths[$Folder.FullName] = $true
            $SizeGB = Get-FolderSizeGB -Path $Folder.FullName
            [pscustomobject]@{
                Folder       = $Folder.FullName
                SizeGB       = $SizeGB
                DrivePercent = if ($DriveSizeGB -gt 0) { ConvertTo-Percent (($SizeGB / $DriveSizeGB) * 100) } else { 0 }
                IsPartial    = $false
            }
        }
    )

    if ($ScanCapped -and $FolderSizes.Count -lt $Count) {
        $RemainingCount = $Count - $FolderSizes.Count
        $FolderSizes += @(
            $Folders | Where-Object { -not $ScannedPaths.ContainsKey($_.FullName) } | Select-Object -First $RemainingCount | ForEach-Object {
                [pscustomobject]@{ Folder = $_.FullName; SizeGB = 0; DrivePercent = 0; IsPartial = $true }
            }
        )
    }

    $FolderSizes | Sort-Object SizeGB -Descending | Select-Object -First $Count
}

#endregion General helpers

#region Hardware and OS inventory

$OS = Invoke-Safe -Name 'operating system inventory' -Fallback $null -ScriptBlock { Get-CimInstance -ClassName Win32_OperatingSystem }
$Computer = Invoke-Safe -Name 'computer inventory' -Fallback $null -ScriptBlock { Get-CimInstance -ClassName Win32_ComputerSystem }
$CPUInfo = Invoke-Safe -Name 'processor inventory' -Fallback $null -ScriptBlock { Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1 }
$DisksRaw = @(Invoke-Safe -Name 'logical disks' -Fallback @() -ScriptBlock { Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" })

$BootTime = if ($OS) { $OS.LastBootUpTime } else { $null }
$Uptime = if ($BootTime) { New-TimeSpan -Start $BootTime -End $Now } else { [timespan]::Zero }
$TotalMemoryGB = if ($OS -and $OS.TotalVisibleMemorySize) { [math]::Round($OS.TotalVisibleMemorySize / 1MB, 1) } else { 0 }
$FreeMemoryGB = if ($OS -and $OS.FreePhysicalMemory) { [math]::Round($OS.FreePhysicalMemory / 1MB, 1) } else { 0 }
$UsedMemoryGB = [math]::Max(0, [math]::Round($TotalMemoryGB - $FreeMemoryGB, 1))
$MemoryUsedPercent = if ($TotalMemoryGB -gt 0) { ConvertTo-Percent (($UsedMemoryGB / $TotalMemoryGB) * 100) } else { 0 }

#endregion Hardware and OS inventory

#region Performance counters

$CounterPaths = @(
    '\Processor(_Total)\% Processor Time',
    '\Memory\Available MBytes',
    '\PhysicalDisk(_Total)\% Disk Time',
    '\System\Processor Queue Length'
)
$RawCounters = @(Invoke-Safe -Name 'performance counters' -Fallback @() -ScriptBlock {
    Get-Counter -Counter $CounterPaths -SampleInterval $SampleIntervalSeconds -MaxSamples $SampleCount
})

$CounterSamples = @(
    foreach ($Sample in $RawCounters) {
        [pscustomobject]@{
            Time              = $Sample.Timestamp.ToString('HH:mm:ss')
            CpuPercent        = ConvertTo-Percent (Get-CounterValue -Sample $Sample -PathLike '*\processor(_total)\% processor time')
            AvailableMemoryMB = [math]::Round((Get-CounterValue -Sample $Sample -PathLike '*\memory\available mbytes'), 0)
            DiskTimePercent   = ConvertTo-Percent (Get-CounterValue -Sample $Sample -PathLike '*\physicaldisk(_total)\% disk time')
            QueueLength       = [math]::Round((Get-CounterValue -Sample $Sample -PathLike '*\system\processor queue length'), 2)
            MemoryUsedPercent = if ($TotalMemoryGB -gt 0) {
                ConvertTo-Percent (100 - (((Get-CounterValue -Sample $Sample -PathLike '*\memory\available mbytes') / ($TotalMemoryGB * 1024)) * 100))
            } else { 0 }
        }
    }
)
if ($CounterSamples.Count -eq 0) {
    $CpuFallback = if ($CPUInfo -and $null -ne $CPUInfo.LoadPercentage) { [double] $CPUInfo.LoadPercentage } else { 0 }
    $CounterSamples = @([pscustomobject]@{
        Time = $Now.ToString('HH:mm:ss'); CpuPercent = ConvertTo-Percent $CpuFallback
        AvailableMemoryMB = [math]::Round($FreeMemoryGB * 1024, 0); DiskTimePercent = 0; QueueLength = 0; MemoryUsedPercent = $MemoryUsedPercent
    })
}

#endregion Performance counters

#region Process diagnostics

$AllProcesses = @(Invoke-Safe -Name 'process inventory' -Fallback @() -ScriptBlock { Get-Process })
$ProcessDiagnostics = @(
    foreach ($Process in $AllProcesses) {
        [pscustomobject]@{
            Process      = $Process.ProcessName
            ProcessLabel = "{0} ({1})" -f $Process.ProcessName, $Process.Id
            Id           = $Process.Id
            CPUSeconds   = if ($null -ne $Process.CPU) { [math]::Round($Process.CPU, 1) } else { 0 }
            MemoryMB     = [math]::Round($Process.WorkingSet64 / 1MB, 1)
            Handles      = $Process.HandleCount
            Threads      = $Process.Threads.Count
        }
    }
)
$TopMemoryProcesses = @($ProcessDiagnostics | Sort-Object MemoryMB -Descending | Select-Object -First $TopProcessCount)
$TopCpuProcesses = @($ProcessDiagnostics | Sort-Object CPUSeconds -Descending | Select-Object -First $TopProcessCount)
$ProcessCount = $ProcessDiagnostics.Count
$ThreadCount = [int](($ProcessDiagnostics | Measure-Object -Property Threads -Sum).Sum)
$HandleCount = [int](($ProcessDiagnostics | Measure-Object -Property Handles -Sum).Sum)

#endregion Process diagnostics

#region Disk diagnostics

$Disks = @(
    foreach ($Disk in ($DisksRaw | Where-Object { $_.Size -gt 0 })) {
        $FreePercent = ConvertTo-Percent (($Disk.FreeSpace / $Disk.Size) * 100)
        [pscustomobject]@{
            Drive       = $Disk.DeviceID
            Label       = $Disk.VolumeName
            SizeGB      = [math]::Round($Disk.Size / 1GB, 1)
            FreeGB      = [math]::Round($Disk.FreeSpace / 1GB, 1)
            UsedPercent = ConvertTo-Percent (100 - $FreePercent)
            FreePercent = $FreePercent
        }
    }
)
if ($Disks.Count -eq 0) {
    $Disks = @([pscustomobject]@{ Drive = 'n/a'; Label = ''; SizeGB = 0; FreeGB = 0; UsedPercent = 0; FreePercent = 0 })
}
$WorstDisk = $Disks | Sort-Object UsedPercent -Descending | Select-Object -First 1
$TopDiskFolders = @(Invoke-Safe -Name 'top disk folders' -Fallback @() -ScriptBlock {
    if ($WorstDisk -and $WorstDisk.Drive -ne 'n/a') {
        Get-TopFolderUsage -Drive $WorstDisk.Drive -Count $TopFolderCount -DriveSizeGB $WorstDisk.SizeGB -MaxSeconds $TopFolderScanSeconds
    } else {
        @()
    }
})

#endregion Disk diagnostics

#region Service diagnostics

$Services = @(Invoke-Safe -Name 'service inventory' -Fallback @() -ScriptBlock { Get-Service })
$ServiceSummary = @(
    foreach ($Status in 'Running', 'Stopped', 'Paused') {
        [pscustomobject]@{ Status = $Status; Count = @($Services | Where-Object Status -EQ $Status).Count }
    }
)
$StoppedAutomaticServices = @(Invoke-Safe -Name 'stopped automatic services' -Fallback @() -ScriptBlock {
    Get-CimInstance -ClassName Win32_Service |
        Where-Object { $_.StartMode -eq 'Auto' -and $_.State -ne 'Running' } |
        Select-Object Name, DisplayName, State, StartMode
})

#endregion Service diagnostics

#region Event diagnostics

$EventStart = $Now.AddHours(-$EventHours)
$Events = @(Invoke-Safe -Name 'System/Application warning and error events' -Fallback @() -ScriptBlock {
    Get-WinEvent -FilterHashtable @{ LogName = @('System', 'Application'); StartTime = $EventStart; Level = @(1, 2, 3) } -MaxEvents $MaxEvents
})
$EventSummaryStart = $Now.AddDays(-7)
$SummaryEvents = @(Invoke-Safe -Name '7-day System/Application warning and error summary' -Fallback @() -ScriptBlock {
    Get-WinEvent -FilterHashtable @{ LogName = @('System', 'Application'); StartTime = $EventSummaryStart; Level = @(1, 2, 3) } -MaxEvents $MaxEvents
})
$EventByLevel = @(
    $Events | Group-Object LevelDisplayName | Sort-Object Count -Descending |
        ForEach-Object { [pscustomobject]@{ Level = $_.Name; Count = $_.Count } }
)
if ($EventByLevel.Count -eq 0) {
    $EventByLevel = @([pscustomobject]@{ Level = 'None'; Count = 0 })
}
$EventByLog = @(
    $Events | Group-Object LogName | Sort-Object Name |
        ForEach-Object { [pscustomobject]@{ Log = $_.Name; Count = $_.Count } }
)
if ($EventByLog.Count -eq 0) {
    $EventByLog = @([pscustomobject]@{ Log = 'System/Application'; Count = 0 })
}
$EventSummaryRows = @(
    $SummaryEvents | Group-Object LevelDisplayName, Id, ProviderName, LogName | ForEach-Object {
        $SampleEvent = $_.Group | Select-Object -First 1
        [pscustomobject]@{
            Type      = $SampleEvent.LevelDisplayName
            EventId   = $SampleEvent.Id
            Source    = $SampleEvent.ProviderName
            Log       = $SampleEvent.LogName
            LastHour  = @($_.Group | Where-Object TimeCreated -GE $Now.AddHours(-1)).Count
            Last24H   = @($_.Group | Where-Object TimeCreated -GE $Now.AddHours(-24)).Count
            Last7Days = $_.Count
        }
    } | Sort-Object -Property @{ Expression = 'Last7Days'; Descending = $true }, Type, Source | Select-Object -First 8
)

#endregion Event diagnostics

#region Network diagnostics

$NetworkStats = @(Invoke-Safe -Name 'network adapter statistics' -Fallback @() -ScriptBlock {
    Get-NetAdapterStatistics | ForEach-Object {
        [pscustomobject]@{
            Adapter    = $_.Name
            ReceivedMB = [math]::Round($_.ReceivedBytes / 1MB, 1)
            SentMB     = [math]::Round($_.SentBytes / 1MB, 1)
            ReceivedPk = $_.ReceivedUnicastPackets
            SentPk     = $_.SentUnicastPackets
        }
    }
})
if ($NetworkStats.Count -eq 0) {
    $NetworkStats = @([pscustomobject]@{ Adapter = 'n/a'; ReceivedMB = 0; SentMB = 0; ReceivedPk = 0; SentPk = 0 })
}
$TopNetwork = @($NetworkStats | Sort-Object { $_.ReceivedMB + $_.SentMB } -Descending | Select-Object -First 8)
$TopNetworkUsageProcesses = @(Invoke-Safe -Name 'SRU process network usage' -Fallback @() -ScriptBlock {
    $SruReaderPath = Join-Path $PSScriptRoot 'SruNetworkUsage.ps1'
    if (Test-Path -LiteralPath $SruReaderPath -PathType Leaf) {
        & $SruReaderPath -SruPath $SruPath -SoftwareHivePath $SoftwareHivePath -Top 5
    } else {
        @()
    }
})

#endregion Network diagnostics

#region Diagnostics output

[pscustomobject]@{
    OS                       = $OS
    Computer                 = $Computer
    CPUInfo                  = $CPUInfo
    BootTime                 = $BootTime
    Uptime                   = $Uptime
    TotalMemoryGB            = $TotalMemoryGB
    FreeMemoryGB             = $FreeMemoryGB
    UsedMemoryGB             = $UsedMemoryGB
    MemoryUsedPercent        = $MemoryUsedPercent
    CounterSamples           = @($CounterSamples)
    ProcessDiagnostics       = @($ProcessDiagnostics)
    TopMemoryProcesses       = @($TopMemoryProcesses)
    TopCpuProcesses          = @($TopCpuProcesses)
    ProcessCount             = $ProcessCount
    ThreadCount              = $ThreadCount
    HandleCount              = $HandleCount
    Disks                    = @($Disks)
    WorstDisk                = $WorstDisk
    TopDiskFolders           = @($TopDiskFolders)
    ServiceSummary           = @($ServiceSummary)
    StoppedAutomaticServices = @($StoppedAutomaticServices)
    Events                   = @($Events)
    EventByLevel             = @($EventByLevel)
    EventByLog               = @($EventByLog)
    EventSummaryRows         = @($EventSummaryRows)
    NetworkStats             = @($NetworkStats)
    TopNetwork               = @($TopNetwork)
    TopNetworkUsageProcesses = @($TopNetworkUsageProcesses)
}

#endregion Diagnostics output
