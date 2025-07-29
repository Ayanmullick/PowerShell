function Get-RebootEvents
{
    param([string[]]$computername='localhost')
    $c = New-Object System.Management.Automation.PSCredential "$Computername\BPGDB_ADMINISTRATOR",$(ConvertTo-SecureString "<>" -asplaintext -force)

    Get-WinEvent -LogName system -ComputerName $computername -Credential $c|Where-Object providername -EQ "user32" |Select-Object -First 3
    #(get-winevent -listprovider user32 -ComputerName $global:computername -Credential $global:c).events|Select-Object -First 3
    #Get-EventLog -LogName system -Source user32 -ComputerName $computername -Newest 3 | Format-table -Wrap
}

#Query all logs
(Get-WinEvent -ListLog * -EA silentlycontinue|? {$_.recordcount -AND $_.lastwritetime -gt [datetime]::today}|%{get-winevent -LogName $_.logname -MaxEvents 2}|Format-Table TimeCreated, ID, ProviderName, Message -AutoSize).count

#Works on Powershell 7.3. Uses foreach-object parallel
(Get-WinEvent -ListLog * -EA SilentlyContinue).Where({$PSItem.recordcount -ne '0'}).Logname|
                ForEach-Object -Parallel {Get-WinEvent -FilterHashtable @{logname = "$PSItem";Starttime ='8/24/2019 11:00:00';Endtime ='8/24/2019 11:09:00';Level=1,2,3} -EA SilentlyContinue }

(Get-WinEvent -ListLog * -EA silentlycontinue|? {$_.recordcount}|%{get-winevent -LogName $_.logname|? {$_.timecreated -gt "2/17/2015 19:11:00" -and $_.timecreated -lt "2/17/2015 22:13:00"} }).count

Get-WinEvent -provider *term* -ComputerName emghwp1323|? message -Match "B6011299" |Select-Object -First 10|sort *time*|ft -AutoSize


Get-WinEvent -FilterXml ([xml](Get-Content C:\fso\Past24CustomView.xml))    #Use Custom Views from Windows Event Viewer in PowerShell
       Get-WinEvent -FilterXml ([xml](Get-Content C:\temp\17.xml))|select -First 5 -Property TimeCreated,MachineName,LogName,ProviderName,LevelDisplayName,Level,Id,UserId,Message|ft -AutoSize

Get-EventLog -LogName System -Message *rpc*|sort Message -Unique|ft -Wrap   #Get unique events by event content
Get-WinEvent -LogName *clu*|? level -LE 5|sort id -Unique|ft -Wrap          #Unique cluster events from operational logs


#region v2:Works on PS7 on Windows
#First filter by source and level to identify the duration for gap in the SYSTEM log. Note the log filtering is compounded. One can put array of values inside the hash table 
Get-WinEvent  -FilterHashtable @(
    @{ProviderName=@('eventlog','*kernel*'); Level =@(0,1,2)},
    @{ProviderName=@('user32','*dump*'); Level = 0..4},
    @{ProviderName='*power*'; Level = 0..3}
)|Select-Object -First 50|sort TimeCreated -Descending|
Format-Table TimeCreated,LevelDisplayName,@{n='User'; e={(New-Object System.Security.Principal.SecurityIdentifier($_.UserId)).Translate([System.Security.Principal.NTAccount]).Value}}, ProcessId, LogName, ID, ProviderName, Message


#More optimised to query for the last 2 days
Get-WinEvent  -FilterHashtable @( @{ProviderName=@('eventlog','*kernel*','*power*'); Level = 0..3}, @{ProviderName=@('user32','*dump*'); Level = 0..4})|
Where-Object {$_.TimeCreated -gt (Get-Date).AddHours(-48)}|sort TimeCreated -Descending|
Format-Table TimeCreated,RecordId,LevelDisplayName,@{n='User'; e={(New-Object System.Security.Principal.SecurityIdentifier($_.UserId)).Translate([System.Security.Principal.NTAccount]).Value}}, ProcessId, LogName, ID, ProviderName, Message

#Can Change to Format-List  or -Wrap with Format-Table to view the message in detail



Get-WinEvent | Where-Object {$_.RecordId -eq 64295}
#Error: Get-WinEvent: Log count (469) is exceeded Windows Event Log API limit (256). Adjust filter to return less log names.
(Get-WinEvent -LogName System).Where({$_.RecordId -eq 64295})|FL *  #Works

#get all events from the System log that occurred 10 minutes before that event
$event = (Get-WinEvent -LogName System).Where({$_.RecordId -eq 64295})

#Increment the 'AddMinutes' gradually till you find the first record id right after the reboot.
Get-WinEvent -LogName System | Where-Object {$_.TimeCreated -lt $event.TimeCreated -and $_.TimeCreated -gt $event.TimeCreated.AddMinutes(-10)}|sort TimeCreated -Descending|
Format-Table TimeCreated,RecordId,LevelDisplayName,@{n='User'; e={(New-Object System.Security.Principal.SecurityIdentifier($_.UserId)).Translate([System.Security.Principal.NTAccount]).Value}}, ProcessId, LogName, ID, ProviderName, Message

(Get-WinEvent -LogName System).Where({$_.RecordId -eq (64259-1)})|FL *   #This will get the last system event before the reboot.


#5 events before and after reboot
Get-WinEvent -LogName System | Where-Object {$_.RecordId -ge (64259-5) -and $_.RecordId -le (64259+5)}|sort TimeCreated -Descending|Format-Table TimeCreated,RecordId,LevelDisplayName, ProcessId, LogName, ID, ProviderName, Message
<#
TimeCreated          RecordId LevelDisplayName ProcessId LogName   Id ProviderName                     Message
-----------          -------- ---------------- --------- -------   -- ------------                     -------
3/10/2023 8:15:42 PM    64264 Information           3896 System  6009 EventLog                         Microsoft (R) Windows (R) 10.00. 22621  Multiprocessor Free.
3/10/2023 8:15:42 PM    64263 Error                 3896 System  6008 EventLog                         The previous system shutdown at 8:12:40 PM on 3/10/2023 was unexpected.
3/10/2023 8:15:16 PM    64262 Information              4 System    20 Microsoft-Windows-Kernel-Boot    The last shutdown's success status was false. The last boot's success status was true.
3/10/2023 8:15:16 PM    64261 Information              4 System   153 Microsoft-Windows-Kernel-Boot    Virtualization-based security (policies: VBS Enabled,VSM Required,Hvci,Boot Chain Signer Soft Enforced) is enabled due to VBS registry configuratio…
3/10/2023 8:15:16 PM    64260 Information              4 System    12 Microsoft-Windows-Kernel-General The operating system started at system time 2023-03-11T02:15:15.500000000Z.
3/10/2023 8:11:57 PM    64259 Information           6648 System    16 Microsoft-Windows-Kernel-General The access history in hive \??\C:\WINDOWS\AppCompat\Programs\Amcache.hve.tmp.tmp.tmp.tmp.tmp was cleared updating 0 keys and creating 0 modified pa…
3/10/2023 6:16:56 PM    64258 Information           1620 System  7040 Service Control Manager          The start type of the Background Intelligent Transfer Service service was changed from auto start to demand start.
3/10/2023 6:14:35 PM    64257 Information           1620 System  7040 Service Control Manager          The start type of the Background Intelligent Transfer Service service was changed from demand start to auto start.
3/10/2023 5:41:51 PM    64256 Information           1620 System  7040 Service Control Manager          The start type of the Background Intelligent Transfer Service service was changed from auto start to demand start.
3/10/2023 5:39:46 PM    64255 Information           1620 System  7040 Service Control Manager          The start type of the Background Intelligent Transfer Service service was changed from demand start to auto start.
3/10/2023 4:16:24 PM    64254 Information          27000 System   158 Microsoft-Windows-Time-Service   The time provider 'VMICTimeProvider' has indicated that the current hardware and operating environment is not supported and has stopped.

#>

#8:15 PM is the time that came up for the Critical| 41| Microsoft-Windows-Kernel-Power| 'The system has rebooted'| event. Use this to query all logs for the gap duration
(Get-WinEvent -ListLog *|? recordcount).Logname|% {$Events+= Get-WinEvent -FilterHashtable @{logname = "$PSItem";Starttime ='3/10/2023 18:16:00';Endtime ='3/10/2023 20:14:00';Level=0,1,2,3} -EA SilentlyContinue }
$Events|sort TimeCreated -Descending|Format-Table TimeCreated,LevelDisplayName,ProcessId, LogName, ID, ProviderName, Message

$Events|? LevelDisplayName -NE 'Information'|? Level -LT 3| sort TimeCreated -Descending|   #Only errors. And displays the username too and removes informational security events
    Format-Table TimeCreated,LevelDisplayName,@{n='User'; e={(New-Object System.Security.Principal.SecurityIdentifier($_.UserId)).Translate([System.Security.Principal.NTAccount]).Value}}, ProcessId, LogName, ID, ProviderName, Message

#endregion





Get-WinEvent -ListLog system | ft -Property filesize,maximumsizeinbytes -AutoSize   #Current and max size of a log

#hp web dump, HP system, eventlog, user32, kernel boot, kernel power,kernel processor power, power troubleshooter, bugcheck   :  sources for reboot events



<#region  Compare various logs' event' timeline thru remote wmi query

$time = [System.Management.ManagementDateTimeConverter]::ToDmtfDateTime((Get-Date).AddHours(-12))-------Need to get the remote server's time

$sys = Get-WmiObject -Class win32_ntlogevent -ComputerName BP1XEUTS399 -Credential $xeu -filter "logfile = 'System' AND Sourcename = 'Srv' AND TimeGenerated>='$time'"|select -First 10
$app = Get-WmiObject -Class win32_ntlogevent -ComputerName BP1XEUTS399 -Credential $xeu -filter "logfile = 'Application' AND eventType < '3' AND TimeGenerated>='$time'"|select -First 10

$($sys + $app)|sort TimeWritten -Descending|select -Property @{n="Created";e={[System.Management.ManagementDateTimeConverter]::ToDateTime($_.TimeWritten)}},logfile,EventCode,sourcename,Message| ft -AutoSize


--->Thru get-eventlog


$c = @()
$a = Get-EventLog -LogName system -computername BP1XEUTS399 -After "28 January 2014 16:30" -Before "28 January 2014 20:00" -Source SRV
$c += $a
$b = get-eventLog -LogName Application -computername BP1XEUTS399 -After "28 January 2014 16:30" -Before "28 January 2014 20:00" -EntryType Error|? {$_.Source -notmatch 'Frame'}
$c += $b
$c|sort TimeWritten -Descending|select -property EntryType,TimeWritten,Source,EventID,Message|Export-Csv -Path a.csv

#endregion
#>

<# Get the inWords section of the data of an event.

$bytes = (Get-EventLog application -Source vss -Newest 1 ).Data

for ($i = 0; $i -lt $bytes.Length; $i += 4)
     {[System.BitConverter]::ToUInt32($bytes, $i).ToString("X8")}
#>


#Get username from events  -------Get-WinEvent -LogName 'Microsoft-Windows-User Profile Service/Operational'|? {$_.message -match "pg003318"}|
#                                                   select -Property TimeCreated,@{n='AccountName';e={$($_.userid).Translate([System.Security.Principal.NTAccount])}},Id,LevelDisplayName,Message|ft -Wrap -AutoSize

#region Search logon events with session id or username----------------------
Get-WinEvent -LogName 'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'| ?{$_.message -match "108"}|
                                select -Property TimeCreated,@{n='AccountName';e={$($_.userid).Translate([System.Security.Principal.NTAccount])}},Id,LevelDisplayName,Message -First 10|ft -Wrap -AutoSize

#endregion

#region Collect MSDT like logs from a Windows VM
md C:\guestlogs
cd C:\guestlogs
C:\WindowsAzure\GuestAgent_VERSION\CollectGuestLogs.exe #(VERSION will be different values, use the highest version value)

Get-WinEvent -Path .\System.evtx|select -First 1


#endregion




#region Boot time
$a= Get-WmiObject win32_OperatingSystem;$a.ConvertToDateTime($a.LocalDateTime) - $a.ConvertToDateTime($a.LastBootUpTime)  #Up duration
(Get-WmiObject win32_OperatingSystem).ConvertToDateTime((Get-WmiObject win32_OperatingSystem -ComputerName bp1xgbap314).LastBootUpTime)   #uptime

Get-WinEvent -LogName system |? message -Match "operating system started" |Select-Object -First 10

<#TimeCreated                     Id LevelDisplayName Message
-----------                     -- ---------------- -------
Mon 8.28.23 8:18:14 AM          12 Information     The operating system started at system time 2023-08-28T13:18:14.406372300Z.
Fri 8.25.23 8:33:54 AM          12 Information     The operating system started at system time 2023-08-25T13:33:53.753012000Z.
Thu 8.24.23 8:11:20 AM          12 Information     The operating system started at system time 2023-08-24T13:11:19.669028300Z.
#>

(Get-WinEvent -LogName system |? message -Match "operating system started" )[1]  #The last time the system was started

#endregion
