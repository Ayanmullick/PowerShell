
#Check status of firewall----
Invoke-Command -ComputerName ayn -Credential administrator -ScriptBlock {[Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine",$env:COMPUTERNAME).OpenSubKey("System\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile").GetValue("EnableFirewall")}
(get-wmiobject -list -namespace root\default | where-object { $_.name -eq "StdRegProv"}).GetDwordValue('2147483650', "System\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile","EnableFirewall")  #thru WMI

Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False   #Disable firewall





#region Enable RDP
set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

#endregion

Enable-PSRemoting -SkipNetworkProfileCheck -Force
Set-ExecutionPolicy RemoteSigned


Get-NetFirewallRule -Name FPS-ICMP4-ERQ-In|Set-NetFirewallRule -Enabled True  #Enable ipv4 ping

Get-NetFirewallRule -DisplayName *Echo*|select -Property name, Displayname,Enabled|ft -Wrap -AutoSize
Get-NetFirewallRule -DisplayGroup *Remote*|select -Property name,DisplayGroup,Displayname,Enabled|sort DisplayGroup|ft -Wrap -AutoSize

Get-NetFirewallRule |select -Property DisplayGroup -Unique

Get-NetFirewallRule -Name *NETDIS* |Set-NetFirewallRule -Enabled True
Get-NetFirewallRule -Name *DCom* |Set-NetFirewallRule -Enabled True


#Should enable remote server managementthru mmc & server manager
Get-NetFirewallRule -DisplayGroup 'Remote Event Log Management','Remote Service Management','File and Printer Sharing','Remote Scheduled Tasks Management','Performance Logs and Alerts','Remote Volume Management','Windows Firewall Remote Management','Remote Desktop','Remote Event Monitor'| Set-NetFirewallRule -Enabled True
Get-NetFirewallRule -DisplayGroup *Remote*|Set-NetFirewallRule -Enabled True



#netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol="icmpv4:8,any" dir=in action=allow

#region Firewall rules to move VM to Azure

netsh winhttp reset proxy

netsh advfirewall firewall set rule dir=in name="File and Printer Sharing (Echo Request - ICMPv4-In)" new enable=yes
netsh advfirewall firewall set rule dir=in name="Network Discovery (LLMNR-UDP-In)" new enable=yes
netsh advfirewall firewall set rule dir=in name="Network Discovery (NB-Datagram-In)" new enable=yes
netsh advfirewall firewall set rule dir=in name="Network Discovery (NB-Name-In)" new enable=yes
netsh advfirewall firewall set rule dir=in name="Network Discovery (Pub-WSD-In)" new enable=yes
netsh advfirewall firewall set rule dir=in name="Network Discovery (SSDP-In)" new enable=yes
netsh advfirewall firewall set rule dir=in name="Network Discovery (UPnP-In)" new enable=yes
netsh advfirewall firewall set rule dir=in name="Network Discovery (WSD EventsSecure-In)" new enable=yes
netsh advfirewall firewall set rule dir=in name="Windows Remote Management (HTTP-In)" new enable=yes
netsh advfirewall firewall set rule dir=in name="Windows Remote Management (HTTP-In)" new enable=yes

netsh advfirewall firewall set rule group="Remote Desktop" new enable=yes
netsh advfirewall firewall set rule group="Core Networking" new enable=yes
netsh advfirewall firewall set rule dir=out name="Network Discovery (LLMNR-UDP-Out)" new enable=yes
netsh advfirewall firewall set rule dir=out name="Network Discovery (NB-Datagram-Out)" new enable=yes
netsh advfirewall firewall set rule dir=out name="Network Discovery (NB-Name-Out)" new enable=yes
netsh advfirewall firewall set rule dir=out name="Network Discovery (Pub-WSD-Out)" new enable=yes
netsh advfirewall firewall set rule dir=out name="Network Discovery (SSDP-Out)" new enable=yes
netsh advfirewall firewall set rule dir=out name="Network Discovery (UPnPHost-Out)" new enable=yes
netsh advfirewall firewall set rule dir=out name="Network Discovery (UPnP-Out)" new enable=yes
netsh advfirewall firewall set rule dir=out name="Network Discovery (WSD Events-Out)" new enable=yes
netsh advfirewall firewall set rule dir=out name="Network Discovery (WSD EventsSecure-Out)" new enable=yes
netsh advfirewall firewall set rule dir=out name="Network Discovery (WSD-Out)" new enable=yes
#endregion






