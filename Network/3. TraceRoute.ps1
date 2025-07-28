#Tracert with Powershell
Test-NetConnection -ComputerName 40.80.221.165 -TraceRoute  #Cannot add port
Resolve-DnsName $((Test-NetConnection cemgportal.dev.att.com -TraceRoute).TraceRoute | Select -SkipLast 1 | Select -Last 1)  #Resolves the last hop
((Test-NetConnection cemgportal.dev.att.com -TraceRoute).TraceRoute)[-1..-2]|Resolve-DnsName #Resolves the last 2 ip addresses
(Test-NetConnection cemgportal.dev.att.com -TraceRoute).TraceRoute|Resolve-DnsName

#region Traceroute with public IP identification
#Enforce ipv4
function Test-PublicConnection {                                                                                
     [CmdletBinding()]
     param([Parameter(Mandatory)][string]$ComputerName)

     $target  = (Resolve-DnsName $ComputerName -Type A).IpAddress | Select-Object -First 1
     $result  = Test-NetConnection $target -InformationLevel Detailed -TraceRoute

     $traceAsString = ($result.TraceRoute | ForEach-Object {
         $dns    = (Resolve-DnsName $_ -ErrorAction SilentlyContinue).NameHost
         $ipInfo = (Invoke-WebRequest "http://ipinfo.io/$($_)/json" -UseBasicParsing -ErrorAction SilentlyContinue).Content |ConvertFrom-Json

         "$($_)`t$(@($dns;  $ipInfo ? "$($ipInfo.org)|$($ipInfo.city)" : $null) -ne $null -join ' , ')"   #This concatenates the FQDN and the Public ip info
     }) -join "`n"                

     $result.PSObject.Properties.Remove('TraceRoute')
     $result | Add-Member NoteProperty TraceRoute $traceAsString -Force
     $result
    }


Test-PublicConnection -ComputerName 'google.com'

<#ComputerName         : 142.250.191.142
RemoteAddress          : 142.250.191.142
NameResolutionResults  : 142.250.191.142
                         ord38s29-in-f14.1e100.net
InterfaceAlias         : Ethernet 2
SourceAddress          : 192.168.1.31
NetRoute (NextHop)     : 192.168.1.1
PingSucceeded          : True
PingReplyDetails (RTT) : 40 ms
TraceRoute             : 192.168.1.1    SAX2V1R.lan , osync.lan , |
                         35.148.93.41   syn-035-148-093-041.res.spectrum.com , AS20115 Charter Communications LLC|Madison
                         0.0.0.0        SrfcL3-W11-1022 , |
                         0.0.0.0        SrfcL3-W11-1022 , |
                         0.0.0.0        SrfcL3-W11-1022 , |
                         0.0.0.0        SrfcL3-W11-1022 , |
                         35.148.93.41   syn-035-148-093-041.res.spectrum.com , AS20115 Charter Communications LLC|Madison
                         169.254.250.250        |
                         96.34.26.214   lag-63.crr01euclwi.netops.charter.com , |Englewood
                         96.34.2.153    lag-100.bbr01euclwi.netops.charter.com , |Englewood
                         96.34.0.7      lag-5.bbr02euclwi.netops.charter.com , |Englewood
                         96.34.0.9      lag-1.bbr01chcgil.netops.charter.com , |Englewood
                         96.34.3.119    lag-811.prr01chcgil.netops.charter.com , |Englewood                             
                         96.34.152.97   prr01chcgil-tge-0-1-0-10.chcg.il.charter.com , |Englewood                       
                         74.125.251.149 AS15169 Google LLC|Chicago                                                      
                         142.251.60.7   AS15169 Google LLC|Chicago                                                      
                         142.250.191.142        ord38s29-in-f14.1e100.net , AS15169 Google LLC|Chicago        
#>
#enddregion





#region Pathping provides trace statistics
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

