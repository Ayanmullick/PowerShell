# Windows Diagnostics Dashboard Runbook

This folder contains a Windows diagnostics dashboard built with PowerShell and PSWriteHTML. The examples below are written for a reader who has cloned or copied the project to their own machine, so paths are expressed as variables instead of machine-specific folders.

## Files

- `Dashboard.ps1` renders the HTML dashboard.
- `Diagnostics.ps1` collects Windows inventory, counters, processes, services, events, disks, and network adapter totals.
- `SruNetworkUsage.ps1` is optional. It reads a copied `SRUDB.dat` database and returns top process network usage with sent, received, total GB, and the SRU time window.
- `style.css` contains the dashboard layout and visual styling.
- `Windows-Diagnostics-Dashboard-repo-check.html` is the generated dashboard output used for review.

## View The Generated HTML Report

A committed sample report can be opened directly in a browser through an HTML viewer:

[View the Windows diagnostics dashboard sample report](https://rawcdn.githack.com/Ayanmullick/PowerShell/refs/heads/master/HtmlReport/Dashboard/Windows-Diagnostics-Dashboard-repo-check.html)

This link points to the generated `Windows-Diagnostics-Dashboard-repo-check.html` file in this folder. Use it for a quick review when you do not want to clone the repository or run the dashboard script locally.

## Prerequisites

Run the dashboard from PowerShell 7 or Windows PowerShell on Windows. The dashboard rendering requires `PSWriteHTML` to be installed and available to `Import-Module PSWriteHTML`.

Some diagnostics work best from an elevated PowerShell session. Event log, performance counter, and CIM access can vary by policy and permission. The SRU database copy step normally requires Administrator rights.

## Optional SRU Process Network Usage

`SruNetworkUsage.ps1` is optional. The main dashboard can still run without SRU data. If `SRUDB.dat` is not provided or cannot be read, the dashboard still generates, but the `Top Network Usage` table will be empty or omitted by fallback behavior.

Use SRU data when you want cumulative per-process network usage. The live SRU database is normally locked at:

```powershell
Join-Path $env:SystemRoot 'System32\sru\SRUDB.dat'
```

Copy both of these files to an accessible folder before running the network usage script:

- `SRUDB.dat` from the Windows SRU folder.
- `SOFTWARE` from the Windows config folder.

The `SOFTWARE` hive is copied alongside the database because SRU tooling commonly needs it for app identity resolution. This dashboard currently resolves names primarily from `SruDbIdMapTable` inside `SRUDB.dat`, but keeping the hive with the evidence set is still the right project structure.

Choose an accessible working location. This can be any folder readable by the account running the dashboard, and it does not need to be inside the repository.

```powershell
$WorkingRoot = Join-Path $env:TEMP 'WinDiagDashboard'
$SruRoot = Join-Path $WorkingRoot 'SRU'
New-Item -ItemType Directory -Path $SruRoot -Force | Out-Null
```

## Copy SRU Files

Start PowerShell as Administrator first.

Try a direct copy:

```powershell
$WorkingRoot = Join-Path $env:TEMP 'WinDiagDashboard'
$SruRoot = Join-Path $WorkingRoot 'SRU'
New-Item -ItemType Directory -Path $SruRoot -Force | Out-Null

Copy-Item -LiteralPath "$env:SystemRoot\System32\sru\SRUDB.dat" -Destination $SruRoot -Force
Copy-Item -LiteralPath "$env:SystemRoot\System32\config\SOFTWARE" -Destination $SruRoot -Force
```

If `SRUDB.dat` is locked, copy it from a Volume Shadow Copy:

```powershell
$WorkingRoot = Join-Path $env:TEMP 'WinDiagDashboard'
$SruRoot = Join-Path $WorkingRoot 'SRU'
New-Item -ItemType Directory -Path $SruRoot -Force | Out-Null

$Volume = (Get-Item $env:SystemRoot).PSDrive.Root
$Result = Invoke-CimMethod -ClassName Win32_ShadowCopy -MethodName Create -Arguments @{ Volume = $Volume }
$Shadow = Get-CimInstance Win32_ShadowCopy | Where-Object ID -eq $Result.ShadowID

Copy-Item -LiteralPath "$($Shadow.DeviceObject)\Windows\System32\sru\SRUDB.dat" -Destination $SruRoot -Force
Copy-Item -LiteralPath "$($Shadow.DeviceObject)\Windows\System32\config\SOFTWARE" -Destination $SruRoot -Force

$Shadow | Remove-CimInstance
```

If shadow copy creation fails with `Initialization failure`, confirm the shell is elevated and that Volume Shadow Copy is available on the machine. If VSS is disabled by policy, use another administrative copy method and place the files in the same destination folder.

## Validate SRU Network Usage Separately

Run this from the repository root or use the full script path:

```powershell
$DashboardRoot = '<path-to-your-clone>\HtmlReport\Dashboard'
$SruRoot = Join-Path (Join-Path $env:TEMP 'WinDiagDashboard') 'SRU'

& "$DashboardRoot\SruNetworkUsage.ps1" `
    -SruPath "$SruRoot\SRUDB.dat" `
    -SoftwareHivePath "$SruRoot\SOFTWARE" `
    -Top 5
```

Expected output columns include:

- `Process`
- `SentGB`
- `ReceivedGB`
- `TotalGB`
- `WindowStart`
- `WindowEnd`
- `WindowDays`

Some entries may remain as `AppId:n` when Windows stored an SRU app identifier without a readable identity blob.

## Disk Folder Scan

The disk panel includes the top first-level folders from the most-used fixed disk. Folder sizing uses Windows built-in `robocopy` in list-only mode with `/L` and `/XJ` so it reads folder metadata and does not copy files or follow junctions.

Use `-TopFolderCount` to choose how many folders to show. Use `-TopFolderScanSeconds` to control the soft scan budget before the script stops starting additional folder measurements.
## Generate The Dashboard With SRU Data

Run from any folder by using the full path:

```powershell
$DashboardRoot = '<path-to-your-clone>\HtmlReport\Dashboard'
$SruRoot = Join-Path (Join-Path $env:TEMP 'WinDiagDashboard') 'SRU'

& "$DashboardRoot\Dashboard.ps1" `
    -SampleCount 12 `
    -SampleIntervalSeconds 1 `
    -EventHours 24 `
    -TopProcessCount 12 `
    -TopFolderCount 5 `
    -TopFolderScanSeconds 60 `
    -MaxEvents 2000 `
    -SruPath "$SruRoot\SRUDB.dat" `
    -SoftwareHivePath "$SruRoot\SOFTWARE" `
    -OutputPath "$DashboardRoot\Windows-Diagnostics-Dashboard-repo-check.html"
```

Add `-Show` if you want PSWriteHTML to open the generated dashboard after rendering:

```powershell
& "$DashboardRoot\Dashboard.ps1" -SruPath "$SruRoot\SRUDB.dat" -SoftwareHivePath "$SruRoot\SOFTWARE" -Show
```

## Generate The Dashboard Without SRU Data

SRU network usage is not required for the rest of the dashboard. To run without copied SRU files:

```powershell
$DashboardRoot = '<path-to-your-clone>\HtmlReport\Dashboard'

& "$DashboardRoot\Dashboard.ps1" `
    -SampleCount 12 `
    -SampleIntervalSeconds 1 `
    -EventHours 24 `
    -TopProcessCount 12 `
    -TopFolderCount 5 `
    -TopFolderScanSeconds 60 `
    -MaxEvents 2000 `
    -OutputPath "$DashboardRoot\Windows-Diagnostics-Dashboard-repo-check.html"
```

In this mode, the dashboard still shows CPU, memory, disk, services, events, process, and adapter-level network totals. Only the cumulative per-process SRU network usage depends on the copied SRU files.

## Recommended Sequence

1. Set the dashboard root path to the folder that contains `Dashboard.ps1`.
2. Open PowerShell as Administrator if you want SRU per-process network usage.
3. Choose an accessible SRU working folder outside the protected Windows system folders.
4. Copy `SRUDB.dat` and `SOFTWARE` to that SRU working folder.
5. Optionally run `SruNetworkUsage.ps1` by itself to confirm the copied database is readable.
6. Run `Dashboard.ps1` with `-SruPath` and `-SoftwareHivePath` when SRU files are available.
7. Open the generated dashboard HTML for review.
8. If SRU files are not available, run `Dashboard.ps1` without the SRU parameters.

