
ipconfig        Get-NetIPAddress
ipconfic /displaydns		Get-DnsClientCache|ft -Wrap -AutoSize
nslookup			        Resolve-DnsName
nslookup blob.core.windows.net 8.8.8.8

route print 			    Get-NetRoute|? AddressFamily -EQ ipv4 |select -Property AddressFamily,TypeOfRoute,Protocol,DestinationPrefix,NextHop,InterfaceAlias,InterfaceIndex|sort interfaceindex|ft -AutoSize
				            Get-NetTCPConnection
netsh interface tcp show global
                            Get-NetTCPConnection
traceroute                  tnc fsevwp55 -TraceRoute

netstat                Get-NetTCPConnection

$net = NetStat
$net | select-string "Established"
$net | select-string "80"


Get-NetAdapterHardwareInfo   #On Surface
<#Name                        : Wi-Fi
InterfaceDescription        : Intel(R) Wi-Fi 6 AX201 160MHz
DeviceType                  : PCI Express Root Complex integrated endpoint
SegmentNumber               : 0
BusNumber                   : 0
DeviceNumber                : 20
FunctionNumber              : 3
SlotNumber                  : 
NumaNode                    : 
PciCurrentSpeedAndMode      : 
PciExpressCurrentLinkSpeed  : Unknown
PciExpressCurrentLinkWidth  : 0
PciExpressMaxLinkSpeed      : Unknown
PciExpressMaxLinkWidth      : 0
PciExpressVersion           : 1.0
LineBasedInterruptSupported : True
MsiInterruptSupported       : True
MsiXInterruptSupported      : True
#>

Get-NetAdapter -Name 'Ethernet 2'|fl
<#Name                       : Ethernet 2
InterfaceDescription       : Surface Ethernet Adapter
InterfaceIndex             : 11
MacAddress                 : F0-1D-BC-98-E4-06
MediaType                  : 802.3
PhysicalMediaType          : 802.3
InterfaceOperationalStatus : Up
AdminStatus                : Up
LinkSpeed(Gbps)            : 1
MediaConnectionState       : Connected
ConnectorPresent           : True
DriverInformation          : Driver Date 2024-08-31 Version 1153.16.20.831 NDIS 6.89
#>

netsh interface tcp show global   
Get-NetOffloadGlobalSetting                                                                               
Get-NetAdapterRdma  
Get-NetAdapterRSS                                                                                            
Get-NetAdapterSriov 
Get-NetAdapterSriovVf 
Get-NetAdapterQos                                                                                            
Get-NetAdaptervmq                                                                                               
Get-SmbClientConfiguration 
Get-SmbServerNetworkInterface 
Get-SmbClientNetworkInterface    
Get-NetAdapterAdvancedProperty


Get-NetAdapterBinding 
Get-NetAdapterVPort 


(Get-CimInstance -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE).IPAddress #Gives private IP addresses

Get-WmiObject win32_networkadapterconfiguration | select description, macaddress  #OGet Mac address thru wmi





Get-NetAdapterStatistics #Total network IO \ usage
Netstat -e -s
Get-NetIPInterface
Get-NetIPInterface -AssociatedIPAddress (Get-NetIPAddress -IPAddress 192.168.0.4)



Get-NetAdapterBinding -InterfaceAlias Ethernet

Disable-NetAdapterBinding -Name Ethernet -ComponentID ms_tcpip6

Set-NetIPInterface -InterfaceIndex 2 -AddressFamily IPv6 -InterfaceMetric 5
Restart-server
