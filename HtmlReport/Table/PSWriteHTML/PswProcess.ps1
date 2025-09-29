#Creates a process report with timestamp in the HTML title and generates an HTML report in the site folder in the repo
Install-PSResource PSWriteHTML -Repository PSGallery -TrustRepository -Quiet -AcceptLicense

$null = New-Item -Path 'site' -ItemType Directory -Force
$stamp = '{0:MMdd:HHmm}{1}' -f ($ct=[TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTimeOffset]::UtcNow,'America/Chicago')), ( ($ct.Offset.TotalHours -eq -5) ? 'CDT' : 'CST' )
#Get data
$procs = Get-Process | Sort-Object WorkingSet64 -Descending |Select-Object -First 20 ProcessName, Id, CPU, @{N='WS(MB)';E={[math]::Round($_.WorkingSet64/1MB,2)}}

#Web Conversion
New-HTML -TitleText "Process$stamp" -Online -FilePath 'site/PswProcess.html'{
  New-HTMLSection{New-HTMLContainer -Width auto {New-HTMLTable -DataTable $procs}}
  #Button, CSS, JS: for basic theme toggle
  New-HTMLTag -Tag 'button' -Attributes @{id='t';type='button';style='position:fixed;top:8px;right:12px;z-index:9999'}{'◐'}
  Add-HTMLStyle -Content 'html.dark{background:black!important;color:white!important}html.dark *{background:transparent!important;color:inherit!important;border-color:white!important}'
  Add-HTMLScript -Placement Footer -Content 'd=document.documentElement;document.getElementById("t").onclick=()=>d.classList.toggle("dark")'
}
