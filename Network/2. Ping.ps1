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

