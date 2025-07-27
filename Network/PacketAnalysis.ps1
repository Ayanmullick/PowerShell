

#region Network packet analysis | https://devblogs.microsoft.com/scripting/packet-sniffing-with-powershell-getting-started/
#https://devblogs.microsoft.com/scripting/use-powershell-to-parse-network-log/
(gcm -Module NetEventPacketCapture | measure).count


New-NetEventSession -Name Session1
<#
Name               : Session1
CaptureMode        : SaveToFile
LocalFilePath      : C:\WINDOWS\system32\config\systemprofile\AppData\Local\NetEventTrace.etl
MaxFileSize        : 250 MB
TraceBufferSize    : 0 KB
MaxNumberOfBuffers : 0
SessionStatus      : NotRunning
#>
logman query providers | select-string tcp   #Get-EtwTraceProvider|select-string tcp   #Doesn't work as expected
<#
Microsoft-Windows-TCPIP                  {2F07E2EE-15DB-40F1-90EF-9D7BA282188A}
TCPIP Service Trace                      {EB004A05-9B1A-11D4-9123-0050047759BC}
#>
Add-NetEventProvider -Name Microsoft-Windows-TCPIP -SessionName Session1
<#
Name            : Microsoft-Windows-TCPIP
SessionName     : Session1
Level           : 4
MatchAnyKeyword : 0xFFFFFFFFFFFFFFFF
MatchAllKeyword : 0x0

#>
Start-NetEventSession -Name Session1 -Verbose
$s = Get-NetEventSession -Verbose
Stop-NetEventSession -Name session1 -Verbose


Get-WinEvent -Path $s.LocalFilePath ï¿½Oldest|select -First 2|fl
$log= Get-WinEvent -Path $s.LocalFilePath ï¿½Oldest
$log[1].Message  #The message could be further split into table columns
#TCP: connection 0xffffb1037d7dd010 (local=192.168.0.4:61670 remote=23.11.208.59:443) exists. State = CloseWaitState, PID = 12220, ProcessSeqNum = 10133099161680487, SendTrackerEnabled = TRUE.

$log | group id -NoElement | sort count -Descending #sort by ID and do a count
New-TimeSpan -end ($log | select -Last 1).timecreated -start ($log | select -first 1).Timecreated  #timespan that represents the amount of log time

#Remove
Remove-NetEventSession
Get-NetEventSession
#endregion


#region HAR analysis
$har=Get-Content '.\www.google.com_Archive `[22-04-09 19-49-46`].har'|ConvertFrom-Json 

$har.log.entries.Request|ft #Browser developer tools view
#endregion