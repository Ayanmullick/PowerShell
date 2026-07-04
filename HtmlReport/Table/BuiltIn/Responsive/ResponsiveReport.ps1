$Title,$OutputPath = 'Processes', (Join-Path $PSScriptRoot 'ResponsiveReport.html')
$stamp = '{0:MMddyy:HHmmss} {1}' -f ($ct = [TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTimeOffset]::UtcNow,'America/Chicago')), (($ct.Offset.TotalHours -eq -5) ? 'CDT' : 'CST')

$head = @'
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<style>
  :root { color-scheme: light dark; }
  body { margin: 0; background: Canvas; color: CanvasText; font: 16px/1.45 system-ui, sans-serif; }
  main { max-width: 1100px; margin: auto; padding: 1rem; }
  p { color: GrayText; }
  .table-scroll { overflow-x: auto; border: 1px solid ButtonBorder; border-radius: .5rem; }
  table { width: 100%; min-width: 42rem; border-collapse: collapse; background: Canvas; }
  th,td { padding: .6rem .75rem; border-bottom: 1px solid ButtonBorder; text-align: left; white-space: nowrap; }
  th+th,td+td { border-left: 1px solid ButtonBorder; }
  th { background: Field; }
  th:not(:first-child),td:not(:first-child) { text-align: right; font-variant-numeric: tabular-nums; }
  @media (max-width: 760px) { table { min-width: 38rem; } th,td { padding: .5rem; font-size: .92rem; } }
</style>
'@

$pre = "<main><h1>$Title</h1><p>Updated $stamp</p><div class='table-scroll' role='region' aria-label='$Title table' tabindex='0'>"
$post = '</div></main>'
$ConvertParams = @{As = 'Table'; Title = $Title; Head = $head; PreContent = $pre; PostContent = $post}

Get-Process |
  Sort-Object WorkingSet64 -Descending |
  Select-Object -First 20 ProcessName, Id, CPU, @{N='WS(MB)';E={[math]::Round($_.WorkingSet64/1MB,2)}} |
  ConvertTo-Html @ConvertParams |
  Set-Content -LiteralPath $OutputPath -Encoding utf8

$OutputPath

