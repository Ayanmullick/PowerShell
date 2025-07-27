
Get-WmiObject Win32_NetworkAdapter | Where { $_.NetEnabled -eq $true } | Select Name, Index, @{N="TimeOfLastReset";E={[System.Management.ManagementDateTimeConverter]::ToDateTime($_.TimeOfLastReset)}} #Connection duration of a NIC

nic agents, group policy, msxmp, snmp, cpqteam, dnsclient, netlogon, l2nd,hpqilo  event and network-diagnostics log  #sources for connectivity loss 

((Get-Counter '\\mullick1\network interface(intel[r] centrino[r] advanced-n 6205)\bytes total/sec').countersamples).cookedvalue*8/102400000*100   #Wifi utilisation   

[Math]::Round((Get-Counter -Counter "\Network Interface(Microsoft Hyper-V Network Adapter)\Bytes Sent/sec").CounterSamples.CookedValue/1024, 2)  #Kbps. for Ethernet on an Azure VM
[Math]::Round((Get-Counter -Counter "\Network Interface(Microsoft Hyper-V Network Adapter)\Bytes Received/sec").CounterSamples.CookedValue/1024, 0)







#region check latency
Test-Connection www.uat.nationallife.com
psping64.exe 10.191.98.135:8543

(Measure-Command {(([system.Net.WebRequest]::Create('https://www.uat.nationallife.com/app/mras/ais-admin/adminLogin')).GetResponse()).StatusCode}).Milliseconds



$sw = [system.diagnostics.stopwatch]::startNew()
(([system.Net.WebRequest]::Create('https://www.uat.nationallife.com/app/mras/ais-admin/adminLogin')).GetResponse()).StatusCode
$sw.Stop()
$sw.Elapsed.Milliseconds

#v2 continuous api call to validate connectivity
while ($true) {$sw = [system.diagnostics.stopwatch]::startNew()
$StatusCode = (([system.Net.WebRequest]::Create('https://nprd-passcard.test.att.com')).GetResponse()).StatusCode
$sw.Stop()
"ResponseTime: $($sw.Elapsed.Milliseconds)| StatusCode: $StatusCode"
}



#endregion

