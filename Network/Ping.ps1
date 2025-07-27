#region PowerShell DNS client for Linux| Module: DnsClient-PS
Resolve-Dns google.com
(Resolve-Dns mc.local).answers  #Shows the IPs
#endregion



#PowerShell continuous ping
while ($true){"$(Get-Date);$(Test-Connection -ComputerName NLGUATJAMDBVM2 -Quiet)"}



#Get Public IP of desktop
(Invoke-WebRequest ifconfig.me/ip).Content
(Invoke-WebRequest ifconfig.me/ip).Content.Trim()  #removes additional line
#(iwr https://api.ipify.org/).Content  Another option


#https://ipinfo.io/json  #Gets public ip details
{
  "ip": "20.98.0.25",
  "city": "Chicago",
  "region": "Illinois",
  "country": "US",
  "loc": "41.8500,-87.6500",
  "org": "AS8075 Microsoft Corporation",
  "postal": "60666",
  "timezone": "America/Chicago",
  "readme": "https://ipinfo.io/missingauth"
}


netstat -ano  #check if port 80 and 443 ate taken up


#region Use PowerShell to Determine What Your System is Talking to Per process
Get-NetTCPConnection -State Established | 
            Select-Object -Property LocalAddress, LocalPort, RemoteAddress, RemotePort, State,@{name='Process';expression={(Get-Process -Id $_.OwningProcess).Name}}, CreationTime |
                    Sort-Object RemotePort|Format-Table -AutoSize

#v2
Get-NetTCPConnection -State Established | 
    Select-Object -Property LocalAddress, LocalPort, RemotePort,RemoteAddress,@{name='RemoteURL';expression={(Resolve-DnsName $_.RemoteAddress).NameHost}},@{name='Process';expression={(Get-Process -Id $_.OwningProcess).Name}},OwningProcess, CreationTime,State |
                    Sort-Object RemotePort|Format-Table -AutoSize

#v3.  Not optimizing with custom object and parallel processing since no network calls happening 
#It will fail if you set the variable name to $Pid. $Pid is the id of the current process 
#For v5. Add total IOPS:   https://github.com/tvfischer/ps-srum-hunting
Get-NetTCPConnection -State Established | 
    Select-Object -Property LocalAddress,LocalPort,RemotePort,RemoteAddress,CreationTime,State,@{n='RemoteURL';e={(Resolve-DnsName $_.RemoteAddress).NameHost}},
            @{n='PId';e={$($script:processid = $_.OwningProcess; $processid)}},@{n='Process';e={(Get-Process -Id $_.OwningProcess).Name}},
            @{n='ParentPId';e={$($script:ParentPId=(Get-CimInstance -Class Win32_process|? ProcessId -EQ $processid).ParentProcessId;$ParentPId)}},@{n='ParentProcess';e={(Get-Process -Id $ParentPId).Name}}|
                    Sort-Object RemotePort|Format-Table -Property LocalAddress, LocalPort, RemotePort,RemoteAddress,RemoteURL,Process,PId,CreationTime,ParentPId,ParentProcess,State -AutoSize


#region v4Gets Public ip owner and location
function Get-IpInfo {param ( [string]$IPAddress )  # Function to get IP information
    $ipInfo = (Invoke-WebRequest "http://ipinfo.io/$IPAddress/json").Content | ConvertFrom-Json
    $ipInfo}

Get-NetTCPConnection -State Established |   # Enhanced Get-NetTCPConnection script
    Select-Object -Property LocalAddress, LocalPort, RemotePort, RemoteAddress, CreationTime, State, 
        @{n='RemoteURL';e={$dnsName = (Resolve-DnsName $_.RemoteAddress).NameHost
            if (-not $dnsName) {"$(Get-IpInfo -IPAddress $_.RemoteAddress | ForEach-Object { $_.org + '|' + $_.city })" } else {$dnsName}  }},
        @{n='PId';e={$($script:processid = $_.OwningProcess; $processid)}},
        @{n='Process';e={(Get-Process -Id $_.OwningProcess).Name}},
        @{n='ParentPId';e={$($script:ParentPId=(Get-CimInstance -Class Win32_process | Where-Object ProcessId -EQ $processid).ParentProcessId; $ParentPId)}},
        @{n='ParentProcess';e={(Get-Process -Id $ParentPId).Name}} |
    Sort-Object RemoteURL | 
    Format-Table -Property LocalAddress, LocalPort, RemotePort, RemoteAddress, RemoteURL, Process, PId, CreationTime, ParentPId, ParentProcess, State -AutoSize


<#LocalAddress LocalPort RemotePort RemoteAddress  RemoteURL                                            Process                  PId CreationTime           ParentPId ParentProcess       State
------------ --------- ---------- -------------  ---------                                            -------                  --- ------------           --------- -------------       -----
192.168.0.5      54166        443 23.220.246.174 a23-220-246-174.deploy.static.akamaitechnologies.com msedge                 10108 Fri 7.25.25 7:40:58 PM      9432 msedge        Established
192.168.0.5      53754        443 172.64.148.235 AS13335 Cloudflare, Inc.|San Francisco               msedge                 10108 Fri 7.25.25 7:28:41 PM      9432 msedge        Established
192.168.0.5      53850        443 154.52.16.202  AS40934 Fortinet Inc.|Singapore                      msedge                 10108 Fri 7.25.25 7:30:50 PM      9432 msedge        Established
192.168.0.5      53289        443 146.75.79.9    AS54113 Fastly, Inc.|Chicago                         msedge                 10108 Fri 7.25.25 7:17:16 PM      9432 msedge        Established
192.168.0.5      54008        443 52.112.95.83   AS8075 Microsoft Corporation|Boydton                 msedge                 10108 Fri 7.25.25 7:35:46 PM      9432 msedge        Established
192.168.0.5      53127        443 52.123.250.169 AS8075 Microsoft Corporation|Chicago                 msedge                 10108 Fri 7.25.25 7:11:40 PM      9432 msedge        Established
192.168.0.5      50355        443 172.183.7.194  AS8075 Microsoft Corporation|Chicago                 OneDrive               15132 Fri 7.25.25 7:51:25 AM     16096 OneDrive      Established
192.168.0.5      50383        443 172.183.7.194  AS8075 Microsoft Corporation|Chicago                 OneDrive               16096 Fri 7.25.25 7:51:35 AM      5640 explorer      Established
192.168.0.5      49835        443 172.183.7.194  AS8075 Microsoft Corporation|Chicago                 svchost                 4104 Fri 7.25.25 7:49:13 AM       892 services      Established
192.168.0.5      53685        443 52.109.16.41   AS8075 Microsoft Corporation|Chicago                 msedge                 10108 Fri 7.25.25 7:28:29 PM      9432 msedge        Established
192.168.0.5      49686      32526 168.63.129.16  AS8075 Microsoft Corporation|Redmond                 WindowsAzureGuestAgent  4084 Fri 7.25.25 7:45:34 AM       892 services      Established
192.168.0.5      49712      32526 168.63.129.16  AS8075 Microsoft Corporation|Redmond                 WaAppAgent              4012 Fri 7.25.25 7:45:52 AM       892 services      Established
192.168.0.5      49700         80 168.63.129.16  AS8075 Microsoft Corporation|Redmond                 WindowsAzureGuestAgent  4084 Fri 7.25.25 7:45:37 AM       892 services      Established
192.168.0.5      54173         80 168.63.129.16  AS8075 Microsoft Corporation|Redmond                 WaAppAgent              4012 Fri 7.25.25 7:41:12 PM       892 services      Established
192.168.0.5      49907        443 20.169.174.231 AS8075 Microsoft Corporation|Washington              msedge                 10108 Fri 7.25.25 7:49:29 AM      9432 msedge        Established
192.168.0.5      49911        443 20.169.174.231 AS8075 Microsoft Corporation|Washington              msedge                 10108 Fri 7.25.25 7:49:30 AM      9432 msedge        Established
#>


#endregion

#endregion






#Test connection to multiple IP's and display result in a tabular format.
$table=@()
(7..17)|% {$table+= Test-NetConnection -ComputerName ("10.1.2."+$PSItem) -Port 443}
$table|ft

#region  Example. Test connection to multiple URL's and display results in tabular format. Checks for TCP and HTTP connectivity
$urls = @(
    "https://www.powershellgallery.com",
    "https://github.com",
    "https://www.nuget.org",
    "https://go.microsoft.com",
    "https://apps.microsoft.com",
    "https://api.nuget.org",
    "https://psg-prod-eastus.azureedge.net",
    "https://psg-prod-eastus.cloudapp.net",
    "https://onegetcdn.azureedge.net",
    "https://psg-prod-eastus.azureedge.net"
    
)

$results = $urls | ForEach-Object {
    $hostname = [System.Uri]::new($_).Host
    $tcpTest = Test-NetConnection -ComputerName $hostname -Port 443
    $httpTest = try { (Invoke-WebRequest -Uri $_ -UseBasicParsing -ErrorAction Stop).StatusCode -eq 200 } catch { $false }
    [PSCustomObject]@{
        URL = $_        
        TcpResult = $tcpTest.TcpTestSucceeded
        HttpResult = $httpTest
    }
}

$results | Format-Table -AutoSize
<#Output
WARNING: TCP connect to (40.117.81.22 : 443) failed
WARNING: Ping to 40.117.81.22 failed with status: TimedOut

URL                                   TcpResult HttpResult
---                                   --------- ----------
https://www.powershellgallery.com          True       True
https://github.com                         True       True
https://www.nuget.org                      True       True
https://go.microsoft.com                   True       True
https://apps.microsoft.com                 True       True
https://api.nuget.org                      True      False
https://psg-prod-eastus.azureedge.net      True      False
https://psg-prod-eastus.cloudapp.net      False      False
https://onegetcdn.azureedge.net            True      False
https://psg-prod-eastus.azureedge.net      True      False
#>


#endregion





#region  Test connectivity To and from by name. You can add remote port and remove properties
$vmNames = @("DC", "Desktop", "Consolidate")
$results = @()

foreach ($sourceVM in $vmNames) {
    foreach ($destinationVM in $vmNames) {
        if ($sourceVM -ne $destinationVM) {
            $scriptBlock = { param($dest) 
                                Test-NetConnection -ComputerName $dest | Select-Object SourceAddress, ComputerName, RemoteAddress, PingSucceeded, 
                @{n='TTL'; e={$_.PingReplyDetails.Options.Ttl}}, TcpTestSucceeded, RemotePort, InterfaceAlias, NameResolutionSucceeded, 
                @{n='ResolvedName'; e={$_.BasicNameResolution.Name}}, IsAdmin, NetworkIsolationContext }   #The last two properties didn't show
            
            $results += Invoke-Command -ComputerName $sourceVM -ScriptBlock $scriptBlock -ArgumentList $destinationVM
        }
    }
}

$results | Format-Table -AutoSize

<#Output
SourceAddress ComputerName RemoteAddress PingSucceeded TTL TcpTestSucceeded RemotePort InterfaceAlias NameResolutionSucceeded ResolvedName         
------------- ------------ ------------- ------------- --- ---------------- ---------- -------------- ----------------------- ------------         
10.132.64.228 Desktop      10.132.66.216          True 128            False          0 Ethernet 2                        True Desktop.vcd.local    
10.132.64.228 Consolidate  10.132.65.134          True 128            False          0 Ethernet 2                        True Consolidate.vcd.local
10.132.66.216 DC           10.132.64.228          True 128            False          0 Ethernet 6                        True DC.vcd.local         
10.132.66.216 Consolidate  10.132.65.134          True 128            False          0 Ethernet 6                        True Consolidate.vcd.local
10.132.65.134 DC           10.132.64.228          True 128            False          0 Ethernet 3                        True DC.vcd.local         
10.132.65.134 Desktop      10.132.66.216          True 128            False          0 Ethernet 3                        True Desktop.vcd.local   




#>



#region v2: Transposed table for  result grouped by source IP
$vmNames = @("DC", "Desktop", "Consolidate")
$results = @()

foreach ($sourceVM in $vmNames) {
    foreach ($destinationVM in $vmNames) {
        if ($sourceVM -ne $destinationVM) {
            $scriptBlock = { param($dest) Test-NetConnection -ComputerName $dest | Select-Object SourceAddress, ComputerName, RemoteAddress, PingSucceeded, @{Name='TTL'; Expression={$_.PingReplyDetails.Options.Ttl}}, TcpTestSucceeded, RemotePort, InterfaceAlias, NameResolutionSucceeded, @{Name='ResolvedName'; Expression={$_.BasicNameResolution.Name}}, IsAdmin, NetworkIsolationContext }
            $results += Invoke-Command -ComputerName $sourceVM -ScriptBlock $scriptBlock -ArgumentList $destinationVM
        }
    }
}

$groupedResults = $results | Group-Object SourceAddress

foreach ($group in $groupedResults) {
    Write-Host "`n[Source: $($group.Name)]"

    $properties = $group.Group[0].PSObject.Properties.Name
    $transposedResults = @()

    foreach ($property in $properties) {
        $row = New-Object PSObject -Property @{Property=$property}
        foreach ($result in $group.Group) {
            $row | Add-Member -NotePropertyName $result.ComputerName -NotePropertyValue $result.$property
        }
        $transposedResults += $row
    }

    $transposedResults | Format-Table -AutoSize
}

#endregion

#endregion

