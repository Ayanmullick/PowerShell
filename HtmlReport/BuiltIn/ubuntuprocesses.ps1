$null = New-Item -Path site -ItemType Directory -Force

$stamp= '{0:MMddyy:HHmmss} {1}' -f ($ct=[TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTimeOffset]::UtcNow,'America/Chicago')),(($ct.Offset.TotalHours -eq -5)?'CDT':'CST')

Get-Process |Sort-Object -Property WorkingSet64 -Descending | Select-Object -First 20 ProcessName, Id, CPU, @{N = 'WS(MB)'; E = {[math]::Round($_.WorkingSet64/1MB, 2)}} |
  ConvertTo-Html -As Table -Title 'Processes' -PreContent "<h1>Processes (Ubuntu runner)</h1><p>Updated $stamp</p>" |
  Set-Content site/ubuntuprocesses2.html -Encoding utf8
