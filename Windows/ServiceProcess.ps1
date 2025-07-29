#region Services and Processes
(gps *prun*).StartTime #Service start time

(Get-WmiObject win32_service -filter "Name='bthserv'").Change($null, $null, 16) # 16 = "Own Process"   #Set service scontainer to 'own'

Get-Process |where Company -NotMatch micro |select -Unique -Property Name,Company|ft -AutoSize   #3rd party processes

get-wmiobject win32_service -ComputerName BP1XEUTS744 -Credential $xeu |? {$_.startmode -EQ 'auto'-and $_.state -EQ 'stopped'}|ft -AutoSize  #Automatic services in stopped state


#endregion