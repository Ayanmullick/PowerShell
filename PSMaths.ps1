#region rounding

$decimalNum = 63.82

[Math]::Truncate($decimalNum)  #63  Truncating Numbers 

[Math]::Floor($decimalNum)     #63  Rounding Down to Whole Numbers

[Math]::Ceiling($decimalNum)   #64  Rounding Up to Whole Numbers 


[Math]::Round($decimalNum,0)   #64  Rounding in General in PowerShell
[Math]::Round($decimalNum,1)   #63.8
[Math]::Round($decimalNum,2)   #63.83
[Math]::Round($decimalNum,5)   #63.82744

[int]$decimalNum               #64
#endregion

(5/21).ToString("P")  #Percentage | Output: 23.81%

#region Time & Date

Get-Date -UnixTimeSeconds    #Converts unix seconds to .Net time

Get-Date -Format "MM.dd.yy|hh:mm"
Get-Date -Format 'MM.dd.yy-HH:mm'  #05.22.21-00:54
Get-Date -Format 'MM.dd.yy-HH:mm:ss'  #06.10.23-21:33:11
Get-Date -Format MM.yy     #05.21
Get-Date -Format 'MMM yy' #May 21  #4 M's spells the full month
Get-Date -Format "MM/dd/yyyy HH:mm:ss (zzz)"  #08 08 2023 22:56:20 (-05:00)  #Shows timezone calculation
@{ "$((Get-TimeZone).Id)" = Get-Date}  #Shows timezone and date

$FileName = "DummyFile_" + (Get-Date -Format HHmm)  + -join ((Get-TimeZone).Id -split '' | Where-Object { $_ -cmatch '[A-Z]' }) + ".txt"  #Output:  DummyFile_1422CST.txt
$FileName = "DummyFile_" +(Get-Date -F HHmm) + -join ((Get-TimeZone).Id -split ''|? { $_ -cmatch '[A-Z]' })

get-date -UFormat “%Y_%m_%d_%H_%M_%S”
Get-Date -Format "dddd MM/dd/yyyy HH:mm K"  #Friday 05/21/2021 22:23 -05:00  #K denotes timezone

[Datetime]::ParseExact('07/15/2019', 'MM/dd/yyyy', $null) 

(Get-Date 'Saturday, August 19, 2023 12:43:28 AM').ToString('dddd MM/dd/yyyy HH:mm') #Parses and converts inline


(Find-Module PowerShellForGitHub -Repository PSGallery).AdditionalMetadata.created.tostring('MMM yy')

$date=(Find-Module PowerShellForGitHub -Repository PSGallery).AdditionalMetadata.created
([DateTime]$date).tostring('MMM yy')

ddd M.d.yy  #My custom date format in System regional settings. 'ddd' is short for day of week. 'dddd' is the full day

Get-Date -Format "ddd M.d.yy H:m" #Thu 3.16.23 10:33

#Most Microsoft Windows text logs have a 19 character timestamp 

#Time setup on a machine
w32tm /query /status  #Shows the time source and time offset|  source IP: 
w32tm /query /configuration | Select-String -Pattern "NtpServer"
w32tm /query /configuration  

chronyc sources  #Linux equicalent



#endregion



#region Converts UTC time phrase to CST
$dateTime = [DateTime]::SpecifyKind([DateTime]::Parse("2023-03-21T17:05:10.9957745Z"), [DateTimeKind]::Utc)
[TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($dateTime, [TimeZoneInfo]::Utc.Id, 'Central Standard Time')

#v2
[TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTime]::SpecifyKind([DateTime]::Parse("2023-03-21T17:05:10.9957745Z"), [DateTimeKind]::Utc), [TimeZoneInfo]::Utc.Id, 'Central Standard Time')
#v3
([TimeZoneInfo]::ConvertTime([DateTime]::Parse("2023-03-21T17:05:10.9957745Z"), [TimeZoneInfo]::FindSystemTimeZoneById('Central Standard Time'))).ToString('MM.dd.yy-HH:mm:ss')

#Converts IST to cST
[TimeZoneInfo]::ConvertTime([DateTime]::ParseExact('2023-03-21T17:05:10', 'yyyy-MM-ddTHH:mm:ss', $null), [TimeZoneInfo]::FindSystemTimeZoneById('India Standard Time'), [TimeZoneInfo]::FindSystemTimeZoneById('Central Standard Time'))

#endregion