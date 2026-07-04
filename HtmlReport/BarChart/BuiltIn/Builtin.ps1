$Root = if ($PSScriptRoot) { $PSScriptRoot } else { Join-Path (Get-Location) 'HtmlReport/BarChart' }
$OutputPath = Join-Path $Root 'SimpleBarChart.html'
$Processes = Get-Process | Where-Object WS -gt 0 | Sort-Object WS -Descending
$Last = $Processes.Count - 1
$Data = $Processes[0, [int]($Last*.25), [int]($Last*.5), [int]($Last*.75), -1] | ForEach-Object {
    [pscustomobject]@{Label = "$($_.ProcessName) ($($_.Id))"; Value = [math]::Round($_.WS / 1MB, 2)}
}

$Max = ($Data.Value | Measure-Object -Maximum).Maximum
$Rows = foreach ($Item in $Data) {
    $Width = [math]::Round(($Item.Value / $Max) * 100, 1)
    "<div class='row'><span>$($Item.Label)</span><div class='track'><div class='bar' style='width:$Width%'></div></div><b>$('{0:n2}' -f $Item.Value)</b></div>"
}

@"
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<style>
  :root { color-scheme: light dark; }
  body { background: Canvas; color: CanvasText; font: 16px/1.45 system-ui, sans-serif; padding: 1rem; }
  .chart { max-width: 900px; }
  .row { display: grid; grid-template-columns: 14rem 1fr 5rem; gap: .75rem; align-items: center; margin: .6rem 0; }
  span { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .track { background: Canvas; border: 1px solid ButtonBorder; border-radius: .4rem; overflow: hidden; }
  .bar { height: 1.5rem; background: Highlight; }
  b { text-align: right; font-variant-numeric: tabular-nums; }
</style>
<h1>Process Memory (MB)</h1>
<div class="chart">
$($Rows -join "`n")
</div>
"@ | Set-Content -LiteralPath $OutputPath -Encoding utf8

$OutputPath



