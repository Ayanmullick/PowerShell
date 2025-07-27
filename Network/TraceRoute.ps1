

#Tracert with Powershell
Test-NetConnection -ComputerName 40.80.221.165 -TraceRoute  #Cannot add port
Resolve-DnsName $((Test-NetConnection cemgportal.dev.att.com -TraceRoute).TraceRoute | Select -SkipLast 1 | Select -Last 1)  #Resolves the last hop
((Test-NetConnection cemgportal.dev.att.com -TraceRoute).TraceRoute)[-1..-2]|Resolve-DnsName #Resolves the last 2 ip addresses
(Test-NetConnection cemgportal.dev.att.com -TraceRoute).TraceRoute|Resolve-DnsName

#region Traceroute with public IP identification
function Get-IpInfo {
    param([string]$IPAddress)
    try {
        (Invoke-WebRequest "http://ipinfo.io/$IPAddress/json" -UseBasicParsing).Content | ConvertFrom-Json
    } catch { $null }
}

$target  = "10.20.10.2"
$result  = Test-NetConnection $target -InformationLevel Detailed -TraceRoute

$traceAsString = ($result.TraceRoute | ForEach-Object {
    $dns = (Resolve-DnsName $_ -ErrorAction SilentlyContinue).NameHost
    if ($dns) { "$_`t$dns" }
    else {
        $ip = Get-IpInfo $_
        "$_`t$($ip ? "$($ip.org)|$($ip.city)" : '')"
    }
}) -join "`n"

$result.PSObject.Properties.Remove('TraceRoute')
$result | Add-Member NoteProperty TraceRoute $traceAsString -Force
$result

<#ComputerName         : google.com
RemoteAddress          : 2607:f8b0:4009:818::200e
NameResolutionResults  : 2607:f8b0:4009:818::200e
                         142.250.190.14
InterfaceAlias         : Ethernet 2
SourceAddress          : 2600:6c44:11f0:2930:bcac:a552:3ab:ab4e
NetRoute (NextHop)     : fe80::2c67:beff:fe14:99a3
PingSucceeded          : True
PingReplyDetails (RTT) : 39 ms
TraceRoute             : 2600:6c44:11f0:2930::1 syn-2600-6c44-11f0-2930-0000-0000-0000-0001.biz6.spectrum.com
                         ::     SrfcL3-W11-1022
                         2001:506:100:2005::2   lag-59.dtr21mdsnwi.netops.charter.com
                         ::     SrfcL3-W11-1022
                         ::     SrfcL3-W11-1022
                         ::     SrfcL3-W11-1022
                         2001:506:100:20d::5    lag-101.bbr01euclwi.netops.charter.com
                         ::     SrfcL3-W11-1022
                         2001:506:100:5::2      lag-1.bbr01chcgil.netops.charter.com
                         2001:506:100:200::7    lag-811.prr01chcgil.netops.charter.com
                         2001:506:100:d300::1f  2001-0506-0100-d300-0000-0000-0000-001f.inf6.spectrum.com
                         2607:f8b0:831f::1      AS15169 Google LLC|Chicago
                         2001:4860:0:1::5682    AS15169 Google LLC|Ashburn
                         2001:4860:0:1::5677    AS15169 Google LLC|Ashburn
                         2607:f8b0:4009:818::200e       ord38s29-in-x0e.1e100.net
#>

#Enforce ipv4
$target  = (Resolve-DnsName -Name 'Google.com' -Type A).Ipaddress
#Or
$target  = [System.Net.Dns]::GetHostAddresses("google.com") | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1

<#ComputerName         : 142.250.190.14
RemoteAddress          : 142.250.190.14
NameResolutionResults  : 142.250.190.14
                         ord37s32-in-f14.1e100.net
InterfaceAlias         : Ethernet 2
SourceAddress          : 192.168.1.31
NetRoute (NextHop)     : 192.168.1.1
PingSucceeded          : True
PingReplyDetails (RTT) : 41 ms
TraceRoute             : 192.168.1.1    SAX2V1R.lan osync.lan
                         35.148.93.41   syn-035-148-093-041.res.spectrum.com
                         0.0.0.0        SrfcL3-W11-1022
                         0.0.0.0        SrfcL3-W11-1022
                         0.0.0.0        SrfcL3-W11-1022
                         0.0.0.0        SrfcL3-W11-1022
                         35.148.93.41   syn-035-148-093-041.res.spectrum.com
                         169.254.250.250        |
                         96.34.26.214   lag-63.crr01euclwi.netops.charter.com
                         96.34.1.20     lag-101.bbr01euclwi.netops.charter.com
                         0.0.0.0        SrfcL3-W11-1022
                         96.34.0.9      lag-1.bbr01chcgil.netops.charter.com
                         96.34.3.119    lag-811.prr01chcgil.netops.charter.com
                         96.34.152.97   prr01chcgil-tge-0-1-0-10.chcg.il.charter.com
                         209.85.240.245 AS15169 Google LLC|Chicago
                         209.85.247.117 AS15169 Google LLC|Chicago
                         142.250.190.14 ord37s32-in-f14.1e100.net
#>


#enddregion





#region Trace over a port
pathping 10.216.20.1 -4

<#Tracing route to 10.216.20.1 over a maximum of 30 hops

  0  EMGHWP1105.aipdomain.tsg [10.216.20.55]
  1  10.216.20.1

Computing statistics for 25 seconds...
            Source to Here   This Node/Link
Hop  RTT    Lost/Sent = Pct  Lost/Sent = Pct  Address
  0                                           EMGHWP1105.aipdomain.tsg [10.216.20.55]
                                0/ 100 =  0%   |
  1    0ms     0/ 100 =  0%     0/ 100 =  0%  10.216.20.1

Trace complete.
#>
#endregion

