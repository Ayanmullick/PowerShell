param(
    [string] $SruPath,
    [string] $SoftwareHivePath,
    [ValidateRange(1, 50)][int] $Top = 5
)

$ErrorActionPreference = 'Stop'

function Resolve-SruDatabasePath {
    param([string] $Path)
    $Candidates = @($Path, (Join-Path $PSScriptRoot 'SRUDB.dat'), 'C:\temp\CodexOutputs\SRU\SRUDB.dat') | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    foreach ($Candidate in $Candidates) {
        if (Test-Path -LiteralPath $Candidate -PathType Leaf) { return (Resolve-Path -LiteralPath $Candidate).Path }
    }
    throw 'SRUDB.dat was not found. Pass -SruPath or copy SRUDB.dat beside this script.'
}

function ConvertFrom-SruIdentity {
    param([int] $AppId, [string] $Raw)
    if ([string]::IsNullOrWhiteSpace($Raw)) { return [pscustomobject]@{ Process = ('AppId:{0}' -f $AppId); Identity = ('AppId:{0}' -f $AppId) } }
    $Identity, $Suffix = $Raw, ''
    if ($Raw.StartsWith('!!')) {
        $Parts = $Raw.Split('!', [StringSplitOptions]::RemoveEmptyEntries)
        if ($Parts.Count -gt 0) { $Identity = $Parts[0] }
        if ($Parts.Count -gt 3) { $Suffix = $Parts[3].Trim() }
    }
    $Process = if ($Identity -match '[\\/]') { Split-Path -Leaf $Identity } else { $Identity }
    if (-not [string]::IsNullOrWhiteSpace($Suffix)) { $Process = "$Process $Suffix" }
    [pscustomobject]@{ Process = $Process; Identity = $Identity }
}

function Get-EseInt64 {
    param($Session, $TableId, $ColumnId)
    $Value = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsInt64($Session, $TableId, $ColumnId)
    if ($null -eq $Value) { return 0 }
    [double] $Value
}

function Get-SruAppMap {
    param($Session, $Dbid)
    $Map = @{}
    $TableId = [Microsoft.Isam.Esent.Interop.JET_TABLEID]::Nil
    try {
        [void][Microsoft.Isam.Esent.Interop.Api]::JetOpenTable($Session, $Dbid, 'SruDbIdMapTable', $null, 0, [Microsoft.Isam.Esent.Interop.OpenTableGrbit]::ReadOnly, [ref]$TableId)
        $Columns = [Microsoft.Isam.Esent.Interop.Api]::GetColumnDictionary($Session, $TableId)
        if ([Microsoft.Isam.Esent.Interop.Api]::TryMoveFirst($Session, $TableId)) {
            do {
                $Blob = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumn($Session, $TableId, $Columns['IdBlob'])
                if ($null -eq $Blob -or $Blob.Length -eq 0) { continue }
                $IdIndex = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsInt32($Session, $TableId, $Columns['IdIndex'])
                $Raw = [Text.Encoding]::Unicode.GetString($Blob).Trim([char]0)
                $Map[[int]$IdIndex] = ConvertFrom-SruIdentity -AppId $IdIndex -Raw $Raw
            } while ([Microsoft.Isam.Esent.Interop.Api]::TryMoveNext($Session, $TableId))
        }
    }
    finally {
        if ($TableId -ne [Microsoft.Isam.Esent.Interop.JET_TABLEID]::Nil) { [Microsoft.Isam.Esent.Interop.Api]::JetCloseTable($Session, $TableId) }
    }
    $Map
}

function Get-SruNetworkUsage {
    param([string] $Path, [int] $Limit = 5)
    $DatabasePath = Resolve-SruDatabasePath -Path $Path
    Add-Type -AssemblyName Microsoft.Isam.Esent.Interop

    $NetworkTable = '{973F5D5C-1D90-4944-BE8E-24B94231A174}'
    $Instance = [Microsoft.Isam.Esent.Interop.Instance]::new(('SruNetworkUsage{0}' -f [guid]::NewGuid().ToString('N')))
    $Instance.Parameters.Recovery = $false
    $Instance.Init()
    $Session = [Microsoft.Isam.Esent.Interop.Session]::new($Instance)
    $Dbid = [Microsoft.Isam.Esent.Interop.JET_DBID]::Nil

    try {
        [void][Microsoft.Isam.Esent.Interop.Api]::JetAttachDatabase($Session, $DatabasePath, [Microsoft.Isam.Esent.Interop.AttachDatabaseGrbit]::ReadOnly)
        [void][Microsoft.Isam.Esent.Interop.Api]::JetOpenDatabase($Session, $DatabasePath, $null, [ref]$Dbid, [Microsoft.Isam.Esent.Interop.OpenDatabaseGrbit]::ReadOnly)
        $AppMap = Get-SruAppMap -Session $Session -Dbid $Dbid
        $Totals = @{}
        $WindowStart, $WindowEnd = $null, $null
        $TableId = [Microsoft.Isam.Esent.Interop.JET_TABLEID]::Nil
        try {
            [void][Microsoft.Isam.Esent.Interop.Api]::JetOpenTable($Session, $Dbid, $NetworkTable, $null, 0, [Microsoft.Isam.Esent.Interop.OpenTableGrbit]::ReadOnly, [ref]$TableId)
            $Columns = [Microsoft.Isam.Esent.Interop.Api]::GetColumnDictionary($Session, $TableId)
            if ([Microsoft.Isam.Esent.Interop.Api]::TryMoveFirst($Session, $TableId)) {
                do {
                    $AppId = [int][Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsInt32($Session, $TableId, $Columns['AppId'])
                    $App = if ($AppMap.ContainsKey($AppId)) { $AppMap[$AppId] } else { [pscustomobject]@{ Process = ('AppId:{0}' -f $AppId); Identity = ('AppId:{0}' -f $AppId) } }
                    $Key = $App.Identity
                    if (-not $Totals.ContainsKey($Key)) {
                        $Totals[$Key] = [pscustomobject]@{ Process = $App.Process; Identity = $App.Identity; SentBytes = 0.0; ReceivedBytes = 0.0 }
                    }
                    $Totals[$Key].SentBytes += Get-EseInt64 -Session $Session -TableId $TableId -ColumnId $Columns['BytesSent']
                    $Totals[$Key].ReceivedBytes += Get-EseInt64 -Session $Session -TableId $TableId -ColumnId $Columns['BytesRecvd']
                    $TimeStamp = [Microsoft.Isam.Esent.Interop.Api]::RetrieveColumnAsDateTime($Session, $TableId, $Columns['TimeStamp'])
                    if ($null -ne $TimeStamp) {
                        if ($null -eq $WindowStart -or $TimeStamp -lt $WindowStart) { $WindowStart = $TimeStamp }
                        if ($null -eq $WindowEnd -or $TimeStamp -gt $WindowEnd) { $WindowEnd = $TimeStamp }
                    }
                } while ([Microsoft.Isam.Esent.Interop.Api]::TryMoveNext($Session, $TableId))
            }
        }
        finally {
            if ($TableId -ne [Microsoft.Isam.Esent.Interop.JET_TABLEID]::Nil) { [Microsoft.Isam.Esent.Interop.Api]::JetCloseTable($Session, $TableId) }
        }

        $Totals.Values | ForEach-Object {
            [pscustomobject]@{
                Process     = $_.Process
                SentGB      = [math]::Round($_.SentBytes / 1GB, 2)
                ReceivedGB  = [math]::Round($_.ReceivedBytes / 1GB, 2)
                TotalGB     = [math]::Round(($_.SentBytes + $_.ReceivedBytes) / 1GB, 2)
                WindowStart = $WindowStart
                WindowEnd   = $WindowEnd
                WindowDays  = if ($WindowStart -and $WindowEnd) { [math]::Round(($WindowEnd - $WindowStart).TotalDays, 1) } else { 0 }
            }
        } | Sort-Object TotalGB -Descending | Select-Object -First $Limit
    }
    finally {
        if ($Dbid -ne [Microsoft.Isam.Esent.Interop.JET_DBID]::Nil) { [Microsoft.Isam.Esent.Interop.Api]::JetCloseDatabase($Session, $Dbid, 0) }
        if ($Session) { $Session.Dispose() }
        if ($Instance) { $Instance.Dispose() }
    }
}

# A copied SRU evidence set often includes SOFTWARE; this reader keeps the parameter but resolves per-app names from SruDbIdMapTable.
$null = $SoftwareHivePath
Get-SruNetworkUsage -Path $SruPath -Limit $Top



