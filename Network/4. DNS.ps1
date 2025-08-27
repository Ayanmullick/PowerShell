#region Server Side
Get-DnsServerResourceRecord -ComputerName "nlgphdqcdc02" -ZoneName "contoso.com" -Name "NLGUTMRASAG2L"

#To change a dns record on the DNS server

$NewObj = $OldObj = Get-DnsServerResourceRecord -ComputerName "nlgphdqcdc02" -ZoneName "contoso.com" -Name "NLGUATMITDBVM2"

$NewObj.TimeToLive = [System.TimeSpan]::FromHours(2)
Set-DnsServerResourceRecord -NewInputObject $NewObj -OldInputObject $OldObj -ZoneName "contoso.com" -PassThru

$NewObj.RecordData   #shows the ip address

#If there is a time to live. it's not static
Get-AzureRmVM|% {Get-DnsServerResourceRecord -ComputerName "nlgphdqcdc02" -ZoneName "contoso.com" -Name $PSItem.name}

Get-DnsServerZone -ComputerName nlgphdqcdc02 #shows all the zones on the server

#endregion




#region Client side
Resolve-DnsName NLGUTMRASAG2L  
Resolve-DnsName -Name www.bing.com -Server 10.0.0.1  #resolves a name against the DNS server at 10.0.0.1
Resolve-DnsName -Name www.bing.com -DnsOnly #resolves a name against the DNS server configured on the local computer. LLMNR and NetBIOS queries are not issued.
Resolve-DnsName -Name www.bing.com -Type MX #resolves a name to a mail exchanger record


Set-DNSClient -InterfaceAlias Storage* -RegisterThisConnectionsAddress $False   ##Disable DNS registration

Get-DnsClientServerAddress | Format-Table -AutoSize
<#InterfaceAlias              InterfaceIndex AddressFamily ServerAddresses                                       
--------------              -------------- ------------- ---------------                                       
Ethernet                                13 IPv4          {10.30.10.10, 10.20.10.10}                            
Ethernet                                13 IPv6          {}                                                    
isatap.reddog.microsoft.com             12 IPv4          {10.30.10.10, 10.20.10.10}                            
isatap.reddog.microsoft.com             12 IPv6          {}                                                    
Loopback Pseudo-Interface 1              1 IPv4          {}                                                    
Loopback Pseudo-Interface 1              1 IPv6          {fec0:0:0:ffff::1, fec0:0:0:ffff::2, fec0:0:0:ffff::3}                                                                                                                                             
#>

Get-DnsClientServerAddress -InterfaceAlias Wi-Fi -AddressFamily IPv4


Set-DnsClientServerAddress -InterfaceIndex 2 -ServerAddresses ("172.17.2.209")


#nslookup for Powershell  ip to name 
[Net.DNS]::GetHostEntry("10.2.1.37")
[Net.Dns]::GetHostAddresses("sgtccemgapwp66")




Register-DnsClient -Verbose


#view and update the DNS suffix search list | https://learn.microsoft.com/en-us/troubleshoot/windows-client/networking/configure-domain-suffix-search-list-domain-name-system-clients
Set-DnsClientGlobalSetting -SuffixSearchList '<>' -Verbose  #No prefixing the '.'
Get-DnsClientGlobalSetting
<#Output
UseSuffixSearchList : True
SuffixSearchList    : {credt.int.metc.state.mn.us}
UseDevolution       : True
DevolutionLevel     : 0
#>
#With multiple suffixes the system will try to resolve the name with each suffix in the list in that order
Set-DnsClientGlobalSetting -SuffixSearchList @("contoso.com","fabrikam.com")

#endregion




#region SWIB



ping  -a 172.17.2.209 -l 9014  #Verify jumbo 

Set-DNSClient -InterfaceAlias Storage* -RegisterThisConnectionsAddress $False   #Disable DNS registration 

Add-WindowsFeature telnet-client  #Install telnet client  

Set-DnsClientServerAddress -InterfaceIndex 2 -ServerAddresses ("172.17.2.209")

#endregion


#Set Dns to point to dynamic and not static :netsh interface ip set dns "Local Area Connection" dhcp
