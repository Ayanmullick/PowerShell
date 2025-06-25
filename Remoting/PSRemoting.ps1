#region Remoting

Get-NetIPAddress -InterfaceIndex 12 -AddressFamily IPv4

set-NetIPAddress -InterfaceIndex 12 -AddressFamily IPv4 -IPAddress 192.168.0.3 -PrefixLength 24

New-NetFirewallRule -Name Allow_Ping -DisplayName "Allow Ping" -Description "Packet Internet Groper ICMPv4" -Protocol ICMPv4 -IcmpType 8 -Enabled True -Profile Any -Action Allow

Test-connection
Test-WSMan -ComputerName 192.168.0.3
Test-NetConnection -ComputerName ayn.centralus.cloudapp.azure.com -Port 5985 -InformationLevel Detailed
Test-NetConnection -ComputerName ayn.centralus.cloudapp.azure.com -CommonTCPPort WINRM
New-CimSession -ComputerName container.northcentralus.cloudapp.azure.com -Credential test\ayanm
Enter-PSSession -Credential test\ayanm

#Then turn off private network firewall to connect Honolulu

Test-Connection -ComputerName '<>'.centralus.cloudapp.azure.com -WsmanAuthentication Basic -Credential myvm\ayan -Source "localhost"

New-CimSession -ComputerName container.northcentralus.cloudapp.azure.com -Credential test\ayan -Authentication Basic -Port 5985
Match Credential
New-CimSession -ComputerName container.northcentralus.cloudapp.azure.com -Credential test\ayanm


Enable-WSManCredSSP -Role "Server"
Enable-WSManCredSSP -Role "Client" -DelegateComputer container.northcentralus.cloudapp.azure.com

netsh firewall set service type=remotedesktop mode=enable

netsh firewall set service type = remoteadmin mode = enable
netsh firewall set service type=fileandprint mode=enable
netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in localport=5985 protocol=TCP action=allow
netsh advfirewall firewall add rule name="WinRM-HTTPS" dir=in localport=5986 protocol=TCP action=allow

Enable-PSRemoting -SkipNetworkProfileCheck
Set-WSManQuickConfig
winrm quickconfig -transport:http   
#powershell version


Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private

cmdkey /addtarget:core /username: admin /pass:
set-item wsman:\localhost\client\TrustedHosts servername -Concatenate -Force
set-item -force WSMan:\localhost\Service\AllowUnencrypted $true
winrm set winrm/config/client '@{AllowUnencrypted="true"}' #---------------on client

winrm set winrm/config/client/auth '@{Basic="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

winrm get winrm/config

#region Powershell Web access

Configure-SMRemoting.exe -enable

Install-WindowsFeature -Name WindowsPowerShellWebAccess -ComputerName '<computer_name>' -IncludeManagementTools -Restart

Install-PswaWebApplication -webApplicationName myWebApp -useTestCertificate

Add-PswaAuthorizationRule -UserName R2x64\administrator -ComputerName R2x64 -ConfigurationName microsoft.powershell

<#Id    RuleName         User                       Destination                ConfigurationName
--    --------                    ----                       -----------                -----------------
0     Rule 0           R2x64\administrator        R2x64                      microsoft.powershell

Connected over 5985  without ssl
#>

#Configure on another port

Get-NetConnectionProfile
Set-NetConnectionProfile -InterfaceAlias Ethernet -NetworkCategory Private

Set-Item WSMan:\localhost\Service\EnableCompatibilityHttpListener -Value true
winrm set winrm/config/service @{EnableCompatibilityHttpListener="true"}

Set-Item WSMan:\localhost\Service\EnableCompatibilityHttpsListener -Value true
Set-Item wsman:\localhost\listener\listener*\port -value '<Port>'

Enter-PSSession ComputerName '<Netbios>' -Port '<Port>'

#endregion

#Enable multi-hop
winrm get winrm/config



winrm e winrm/config/listener  #https://forums.ivanti.com/s/article/WinRM-related-errors-are-seen-when-browsing-through-the-Server-Configuration-Portal?language=en_US
#Runs successfully. There are ports listening
Compare-Object -ReferenceObject $(winrm get winrm/config) -DifferenceObject $(ICm -ComputerName ACE2D23243SQ001 -ScriptBlock {winrm get winrm/config})

#endregion