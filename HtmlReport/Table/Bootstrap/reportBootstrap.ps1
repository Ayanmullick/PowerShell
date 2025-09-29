
$null = New-Item -Path site -ItemType Directory -Force

$stamp = '{0:MMddyy:HHmmss} {1}' -f ($ct=[TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTimeOffset]::UtcNow,'America/Chicago')), ( ($ct.Offset.TotalHours -eq -5) ? 'CDT' : 'CST' )

$css  = 'https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css'
$head = @'
<meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css">
<script>
(()=>{const r=document.documentElement;
  // theme toggle (per Bootstrap color modes)
  addEventListener('click',e=>{if(e.target.closest('[data-toggle-theme]')) r.setAttribute('data-bs-theme', r.getAttribute('data-bs-theme')==='dark'?'light':'dark');});
  // give the generated table Bootstrap classes
  addEventListener('DOMContentLoaded',()=>{const t=document.querySelector('table'); if(t) t.className='table table-bordered table-sm w-auto mx-auto text-nowrap';});
})();
</script>
'@

$pre  = "<div class='d-flex justify-content-end'><button data-toggle-theme class='btn btn-outline-secondary btn-sm' aria-label='Toggle'><i class='bi bi-moon'></i></button></div><h1>Processes</h1><p>Updated $stamp</p><div class='table-responsive'>"
$post = "</div>"

Get-Process |
  Sort-Object WorkingSet64 -Descending |
  Select-Object -First 20 ProcessName, Id, CPU, @{N='WS(MB)';E={[math]::Round($_.WorkingSet64/1MB,2)}} |
  ConvertTo-Html -As Table -Title 'Processes' -CssUri $css -Head $head -PreContent $pre -PostContent $post |
  Set-Content processes4.html -Encoding utf8
