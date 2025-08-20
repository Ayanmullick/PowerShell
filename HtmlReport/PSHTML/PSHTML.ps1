#Import-Module PSHTML

$procs = Get-Process |
  Sort-Object WorkingSet64 -Descending |
  Select-Object -First 20 ProcessName, Id, CPU,
    @{N='WS(MB)';E={[math]::Round($_.WorkingSet64/1MB,2)}}

# Use the new cmdlet (not the deprecated one)
$t = ConvertTo-PSHTMLTable -Object $procs `
     -Properties ProcessName, Id, CPU, 'WS(MB)'      # optional but explicit

html {
  head {
    title 'Processes'
    style { 'html.dark{background:black!important;color:white!important}html.dark *{background:transparent!important;color:inherit!important;border-color:white!important}' }
  }
  body {
    button '🌓' -Id 't' -Attributes @{style='position:fixed;top:8px;right:12px;z-index:9999'}
    div { $t }
    script -content 'd=document.documentElement;document.getElementById("t").onclick=()=>d.classList.toggle("dark")'
  }
} | Out-File site/pshtml-processes.html -Encoding utf8
