param(
    [ValidateRange(1, 120)][int] $SampleCount = 12,
    [ValidateRange(1, 30)][int] $SampleIntervalSeconds = 1,
    [ValidateRange(1, 168)][int] $EventHours = 24,
    [ValidateRange(5, 50)][int] $TopProcessCount = 12,
    [ValidateRange(1, 20)][int] $TopFolderCount = 5,
    [ValidateRange(5, 300)][int] $TopFolderScanSeconds = 60,
    [ValidateRange(100, 10000)][int] $MaxEvents = 2000,
    [string] $SruPath,
    [string] $SoftwareHivePath,
    [string] $OutputPath,
    [switch] $Show
)

$ErrorActionPreference = 'Stop'

#region Module imports

# PSWriteHTML supplies the HTML and chart DSL used below.
Import-Module PSWriteHTML -ErrorAction Stop

#endregion Module imports

#region Output setup

$Now = Get-Date
$ScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
if (-not $OutputPath) {
    $OutputPath = Join-Path $ScriptRoot ('Windows-Diagnostics-Dashboard-{0}.html' -f $Now.ToString('yyyyMMdd-HHmmss'))
}

$StyleSheetPath = Join-Path $ScriptRoot 'style.css'
$OutputDirectory = Split-Path -Parent ([IO.Path]::GetFullPath($OutputPath))
$OutputStyleSheetPath = Join-Path $OutputDirectory 'style.css'
if (-not (Test-Path -LiteralPath $StyleSheetPath)) { throw "Missing stylesheet: $StyleSheetPath" }
if (-not (Test-Path -LiteralPath $OutputDirectory)) { New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null }
if (-not [string]::Equals([IO.Path]::GetFullPath($StyleSheetPath), [IO.Path]::GetFullPath($OutputStyleSheetPath), [StringComparison]::OrdinalIgnoreCase)) {
    Copy-Item -LiteralPath $StyleSheetPath -Destination $OutputStyleSheetPath -Force
}

#endregion Output setup

#region Diagnostics data

$DiagnosticsPath = Join-Path $ScriptRoot 'Diagnostics.ps1'
if (-not (Test-Path -LiteralPath $DiagnosticsPath)) { throw "Missing diagnostics script: $DiagnosticsPath" }
$Diagnostics = & $DiagnosticsPath -Now $Now -SampleCount $SampleCount -SampleIntervalSeconds $SampleIntervalSeconds -EventHours $EventHours -TopProcessCount $TopProcessCount -TopFolderCount $TopFolderCount -TopFolderScanSeconds $TopFolderScanSeconds -MaxEvents $MaxEvents -SruPath $SruPath -SoftwareHivePath $SoftwareHivePath

#endregion Diagnostics data

#region Dashboard data model

$OS = $Diagnostics.OS
$Computer = $Diagnostics.Computer
$CPUInfo = $Diagnostics.CPUInfo
$Uptime = $Diagnostics.Uptime
$TotalMemoryGB = $Diagnostics.TotalMemoryGB
$FreeMemoryGB = $Diagnostics.FreeMemoryGB
$MemoryUsedPercent = $Diagnostics.MemoryUsedPercent
$CounterSamples = @($Diagnostics.CounterSamples)
$ProcessDiagnostics = @($Diagnostics.ProcessDiagnostics)
$TopMemoryProcesses = @($Diagnostics.TopMemoryProcesses)
$TopCpuProcesses = @($Diagnostics.TopCpuProcesses)
$ProcessCount = $Diagnostics.ProcessCount
$ThreadCount = $Diagnostics.ThreadCount
$HandleCount = $Diagnostics.HandleCount
$Disks = @($Diagnostics.Disks)
$WorstDisk = $Diagnostics.WorstDisk
$TopDiskFolders = @($Diagnostics.TopDiskFolders)
$ServiceSummary = @($Diagnostics.ServiceSummary)
$StoppedAutomaticServices = @($Diagnostics.StoppedAutomaticServices)
$Events = @($Diagnostics.Events)
$EventByLevel = @($Diagnostics.EventByLevel)
$EventSummaryRows = @($Diagnostics.EventSummaryRows)
$NetworkStats = @($Diagnostics.NetworkStats)
$TopNetwork = @($Diagnostics.TopNetwork)
$TopNetworkUsageProcesses = @($Diagnostics.TopNetworkUsageProcesses)
$CpuNow = ($CounterSamples | Select-Object -Last 1).CpuPercent
$MemoryAvailableNow = ($CounterSamples | Select-Object -Last 1).AvailableMemoryMB
$QueueNow = ($CounterSamples | Select-Object -Last 1).QueueLength
$CriticalOrErrorEvents = @($Events | Where-Object { $_.Level -in 1, 2 }).Count

$ChartPalette = "royalblue", "darkturquoise", "darkorange", "mediumorchid", "crimson", "yellowgreen", "deepskyblue", "goldenrod", "slategray"
$EventColors = @{ Critical = "maroon"; Error = "crimson"; Warning = "goldenrod"; None = "darkgray" }
$TopProcessRows = @($ProcessDiagnostics | Sort-Object MemoryMB -Descending | Select-Object -First 6)
$TopMemoryChartRows = @(
    $TopMemoryProcesses | Select-Object -First 6 | ForEach-Object {
        [pscustomobject]@{ ProcessLabel = $_.ProcessLabel; MemoryGB = [math]::Round($_.MemoryMB / 1024, 2) }
    }
)
$TopCpuChartRows = @($TopCpuProcesses | Select-Object -First 6)
$StoppedServiceRows = @($StoppedAutomaticServices | Select-Object -First 5)
$NetworkTotalMB = [math]::Round((($NetworkStats | Measure-Object -Property ReceivedMB -Sum).Sum + ($NetworkStats | Measure-Object -Property SentMB -Sum).Sum), 1)
$SruWindowRow = $TopNetworkUsageProcesses | Where-Object { $_.WindowStart -and $_.WindowEnd } | Select-Object -First 1
$SruWindowLabel = if ($SruWindowRow) {
    "Window: {0} - {1} ({2} days)" -f ([datetime]$SruWindowRow.WindowStart).ToString("MMM d, yyyy"), ([datetime]$SruWindowRow.WindowEnd).ToString("MMM d, yyyy"), $SruWindowRow.WindowDays
}
else {
    "Window: not available"
}

#endregion Dashboard data model

#region HTML helper functions

function ConvertTo-HtmlText {
    param([object] $Value)

    [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function New-DashboardStyle {
    # PSWriteHTML creates the link tag; styling is kept in the external CSS file next to this script.
    New-HTMLTag -Tag "link" -Attributes @{ rel = "stylesheet"; type = "text/css"; href = "style.css" } -SelfClosing
}

function New-MetricTile {
    param([string] $Label, [string] $Value, [string] $Detail, [string] $Color)

    New-HTMLTag -Tag "div" -Attributes @{ class = "metric" } {
        New-HTMLTag -Tag "div" -Attributes @{ class = "metric-bar"; style = "background:$Color" } { "" }
        New-HTMLTag -Tag "div" {
            New-HTMLTag -Tag "div" -Attributes @{ class = "metric-label" } { ConvertTo-HtmlText $Label }
            New-HTMLTag -Tag "div" -Attributes @{ class = "metric-value" } { ConvertTo-HtmlText $Value }
            New-HTMLTag -Tag "div" -Attributes @{ class = "metric-detail" } { ConvertTo-HtmlText $Detail }
        }
    }
}

function New-DashboardFrame {
    param([string] $Class, [string] $Title, [scriptblock] $Content)

    New-HTMLTag -Tag "div" -Attributes @{ class = "dash-frame $Class" } {
        New-HTMLTag -Tag "div" -Attributes @{ class = "frame-title" } { ConvertTo-HtmlText $Title }
        New-HTMLTag -Tag "div" -Attributes @{ class = "frame-body" } { & $Content }
    }
}

function New-CompactTable {
    param([array] $Data, [string[]] $Columns, [hashtable] $Headers = @{}, [string[]] $NumericColumns = @())

    New-HTMLTag -Tag "table" -Attributes @{ class = "mini-table" } {
        New-HTMLTag -Tag "thead" {
            New-HTMLTag -Tag "tr" {
                foreach ($Column in $Columns) {
                    $Text = if ($Headers.ContainsKey($Column)) { $Headers[$Column] } else { $Column }
                    $Class = if ($Column -in $NumericColumns) { "num" } else { "" }
                    New-HTMLTag -Tag "th" -Attributes @{ class = $Class } { ConvertTo-HtmlText $Text }
                }
            }
        }
        New-HTMLTag -Tag "tbody" {
            foreach ($Row in $Data) {
                New-HTMLTag -Tag "tr" {
                    foreach ($Column in $Columns) {
                        $Class = if ($Column -in $NumericColumns) { "num" } else { "" }
                        New-HTMLTag -Tag "td" -Attributes @{ class = $Class; title = [string]$Row.$Column } { ConvertTo-HtmlText $Row.$Column }
                    }
                }
            }
            if ($Data.Count -eq 0) {
                New-HTMLTag -Tag "tr" {
                    New-HTMLTag -Tag "td" -Attributes @{ colspan = $Columns.Count } { "No data" }
                }
            }
        }
    }
}

function Convert-GeneratedColorHexToName {
    param([string] $Path, [string[]] $ColorName)

    if (-not (Test-Path -LiteralPath $Path)) { return }
    if (-not (Get-Command ConvertFrom-Color -ErrorAction SilentlyContinue)) { return }

    $Html = Get-Content -Raw -LiteralPath $Path
    foreach ($Name in ($ColorName | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)) {
        $Converted = @(ConvertFrom-Color -Color $Name)
        foreach ($Value in $Converted) {
            if ([string]::IsNullOrWhiteSpace($Value) -or $Value -notlike "#*") { continue }
            $Html = $Html.Replace($Value, $Name).Replace($Value.ToLowerInvariant(), $Name).Replace($Value.ToUpperInvariant(), $Name)
        }
    }
    Set-Content -LiteralPath $Path -Value $Html -Encoding UTF8
}

#endregion HTML helper functions

#region Render dashboard

# Diagnostics.ps1 gathers the machine data; PSWriteHTML renders the dashboard HTML.
New-HTML -TitleText "Windows Performance and Diagnostics Dashboard" -Author $env:USERNAME -FilePath $OutputPath -ShowHTML:$Show {
    New-DashboardStyle
    New-HTMLTag -Tag "div" -Attributes @{ class = "dash-grid" } {
        New-HTMLTag -Tag "div" -Attributes @{ class = "dash-header" } {
            New-HTMLTag -Tag "div" -Attributes @{ class = "dash-title" } { "Windows Performance and Diagnostics" }
            New-HTMLTag -Tag "div" -Attributes @{ class = "dash-meta" } {
                $Meta = "{0} | {1} | uptime {2}d {3}h | samples {4} x {5}s" -f $env:COMPUTERNAME, $Now.ToString("yyyy-MM-dd HH:mm"), [int]$Uptime.TotalDays, $Uptime.Hours, $CounterSamples.Count, $SampleIntervalSeconds
                ConvertTo-HtmlText $Meta
            }
        }

        New-HTMLTag -Tag "div" -Attributes @{ class = "metric-strip" } {
            New-MetricTile -Label "CPU" -Value ("{0}%" -f $CpuNow) -Detail ($CPUInfo.Name) -Color "royalblue"
            New-MetricTile -Label "Memory" -Value ("{0}%" -f $MemoryUsedPercent) -Detail ("{0} GB free of {1} GB" -f $FreeMemoryGB, $TotalMemoryGB) -Color "darkturquoise"
            New-MetricTile -Label "Disk" -Value ("{0}%" -f $WorstDisk.UsedPercent) -Detail ("{0} used, {1} GB free" -f $WorstDisk.Drive, $WorstDisk.FreeGB) -Color "darkorange"
            New-MetricTile -Label "Events" -Value $CriticalOrErrorEvents -Detail ("errors in last {0}h" -f $EventHours) -Color "crimson"
            New-MetricTile -Label "Processes" -Value $ProcessCount -Detail ("{0:n0} threads, {1:n0} handles" -f $ThreadCount, $HandleCount) -Color "mediumorchid"
            New-MetricTile -Label "Network" -Value ("{0:n1} MB" -f $NetworkTotalMB) -Detail ("{0} adapters" -f $NetworkStats.Count) -Color "deepskyblue"
        }

        New-DashboardFrame -Class "span-6" -Title "System Activity" -Content {
            # One compact timeline overlays CPU, memory, and queue to keep the dashboard single-page.
            New-HTMLChart -Height 220 -TitleAlignment left {
                New-ChartLine -Name "CPU %" -Value @($CounterSamples.CpuPercent) -Color "royalblue" -Curve smooth -Width 3
                New-ChartLine -Name "Memory used %" -Value @($CounterSamples.MemoryUsedPercent) -Color "darkturquoise" -Curve smooth -Width 3
                New-ChartLine -Name "Queue" -Value @($CounterSamples.QueueLength) -Color "mediumorchid" -Curve smooth -Width 2
                New-ChartAxisX -Names @($CounterSamples.Time)
                New-ChartAxisY -TitleText "Percent / queue" -MinValue 0 -MaxValue 100
                New-ChartDataLabel
            }
        }
        New-DashboardFrame -Class "span-6 event-summary" -Title "Event Viewer Summary" -Content {
            # Event Viewer-style rollup grouped by level, event id, source, and log.
            $Headers = @{ Type = "Event Type"; EventId = "Event ID"; Source = "Source"; Log = "Log"; LastHour = "Last hour"; Last24H = "24 hours"; Last7Days = "7 days" }
            New-CompactTable -Data $EventSummaryRows -Columns @("Type", "EventId", "Source", "Log", "LastHour", "Last24H", "Last7Days") -Headers $Headers -NumericColumns @("EventId", "LastHour", "Last24H", "Last7Days")
        }
        New-DashboardFrame -Class "span-3" -Title "Process Memory (GB)" -Content {
            New-HTMLChart -Height 160 -Gradient {
                New-ChartBarOptions -Distributed -DataLabelsEnabled $false
                New-ChartLegend -HideLegend
                New-ChartAxisX -TitleText "GB"
                for ($Index = 0; $Index -lt $TopMemoryChartRows.Count; $Index++) {
                    $Process = $TopMemoryChartRows[$Index]
                    New-ChartBar -Name $Process.ProcessLabel -Value $Process.MemoryGB -Color $ChartPalette[$Index % $ChartPalette.Count]
                }
            }
        }
        New-DashboardFrame -Class "span-3" -Title "Process CPU Seconds" -Content {
            New-HTMLChart -Height 160 -Gradient {
                New-ChartBarOptions -Distributed -DataLabelsEnabled $false
                New-ChartLegend -HideLegend
                for ($Index = 0; $Index -lt $TopCpuChartRows.Count; $Index++) {
                    $Process = $TopCpuChartRows[$Index]
                    New-ChartBar -Name $Process.ProcessLabel -Value $Process.CPUSeconds -Color $ChartPalette[$Index % $ChartPalette.Count]
                }
            }
        }
        New-DashboardFrame -Class "span-2 disk-usage" -Title "Disk Used and Top Folders" -Content {
            $DiskFolderScanCapped = @($TopDiskFolders | Where-Object IsPartial).Count -gt 0
            $DiskLabel = "{0} {1}% used | {2:n1} GB free" -f $WorstDisk.Drive, $WorstDisk.UsedPercent, $WorstDisk.FreeGB
            if ($DiskFolderScanCapped) { $DiskLabel = "$DiskLabel | folder scan capped" }
            New-HTMLTag -Tag "div" -Attributes @{ class = "frame-label"; title = $DiskLabel } { ConvertTo-HtmlText $DiskLabel }
            $Headers = @{ Folder = "Folder"; SizeGB = "GB"; DrivePercent = "%" }
            New-CompactTable -Data $TopDiskFolders -Columns Folder, SizeGB, DrivePercent -Headers $Headers -NumericColumns SizeGB, DrivePercent
        }
        New-DashboardFrame -Class "span-2" -Title "Services" -Content {
            New-HTMLChart -Height 160 {
                foreach ($Item in $ServiceSummary) {
                    $Color = switch ($Item.Status) { Running { "forestgreen" } Stopped { "crimson" } Paused { "goldenrod" } default { "darkgray" } }
                    New-ChartDonut -Name $Item.Status -Value $Item.Count -Color $Color
                }
                New-ChartDataLabel
            }
        }
        New-DashboardFrame -Class "span-2" -Title "Event Severity" -Content {
            New-HTMLChart -Height 160 {
                foreach ($Item in $EventByLevel) {
                    $Color = if ($EventColors.ContainsKey($Item.Level)) { $EventColors[$Item.Level] } else { "slategray" }
                    New-ChartDonut -Name $Item.Level -Value $Item.Count -Color $Color
                }
                New-ChartDataLabel
            }
        }

        New-DashboardFrame -Class "span-4" -Title "Top Processes" -Content {
            $Headers = @{ Process = "Process"; CPUSeconds = "CPU"; MemoryMB = "MB"; Threads = "Th" }
            New-CompactTable -Data $TopProcessRows -Columns Process, CPUSeconds, MemoryMB, Threads -Headers $Headers -NumericColumns CPUSeconds, MemoryMB, Threads
        }
        New-DashboardFrame -Class "span-5" -Title "Top Network Usage" -Content {
            $Headers = @{ Process = "Process"; SentGB = "Sent GB"; ReceivedGB = "Received GB"; TotalGB = "Total GB" }
            New-HTMLTag -Tag "div" -Attributes @{ class = "frame-label"; title = $SruWindowLabel } { ConvertTo-HtmlText $SruWindowLabel }
            New-CompactTable -Data $TopNetworkUsageProcesses -Columns Process, SentGB, ReceivedGB, TotalGB -Headers $Headers -NumericColumns SentGB, ReceivedGB, TotalGB
        }
        New-DashboardFrame -Class "span-3" -Title "Stopped Automatic Services" -Content {
            $Headers = @{ DisplayName = "Service"; State = "State"; StartMode = "Start" }
            New-CompactTable -Data $StoppedServiceRows -Columns DisplayName, State, StartMode -Headers $Headers
        }
    }
} | Out-Null

#endregion Render dashboard

#region Generated output cleanup

$DashboardColorNames = @($ChartPalette + $EventColors.Values + @(
        "forestgreen", "crimson", "goldenrod", "darkgray", "slategray", "gainsboro", "black", "lightsteelblue",
        "white", "ghostwhite", "midnightblue", "darkslategray"
    ))
Convert-GeneratedColorHexToName -Path $OutputPath -ColorName $DashboardColorNames

Get-Item -LiteralPath $OutputPath

#endregion Generated output cleanup






