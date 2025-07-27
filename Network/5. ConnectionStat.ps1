
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
