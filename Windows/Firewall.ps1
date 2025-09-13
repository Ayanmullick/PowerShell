Test-NetConnection 127.0.0.1 -Port 3389   # Should be True if the listener is healthy
<#ComputerName     : 127.0.0.1
RemoteAddress    : 127.0.0.1
RemotePort       : 3389
InterfaceAlias   : Loopback Pseudo-Interface 1
SourceAddress    : 127.0.0.1
TcpTestSucceeded : True
#>

Get-NetFirewallProfile|ft Name,Enabled,NotifyOnListen,LogFileName
<#Name    Enabled NotifyOnListen LogFileName
----    ------- -------------- -----------
Domain     True           True %systemroot%\system32\LogFiles\Firewall\pfirewall.log
Private    True           True %systemroot%\system32\LogFiles\Firewall\pfirewall.log
Public     True           True %systemroot%\system32\LogFiles\Firewall\pfirewall.log
#>



Get-NetConnectionProfile | Select-Object InterfaceAlias, NetworkCategory
 <#InterfaceAlias NetworkCategory
-------------- ---------------
Ethernet 284           Private
#>


Get-NetFirewallRule -DisplayGroup 'Remote Desktop' -Enabled True | Sort Profile|ft DisplayName,Profile,Direction,Action,Enabled
<#DisplayName                                         Profile Direction Action Enabled
-----------                                         ------- --------- ------ -------
Remote Desktop - Shadow (TCP-In)    Domain, Private, Public   Inbound  Allow    True
Remote Desktop - User Mode (TCP-In) Domain, Private, Public   Inbound  Allow    True
Remote Desktop - User Mode (UDP-In) Domain, Private, Public   Inbound  Allow    True
#>



Get-NetFirewallServiceFilter -Service TermService -PolicyStore ActiveStore | Get-NetFirewallRule|ft Name,DisplayName,DisplayGroup,Enabled,Profile,Action
<#Name                          DisplayName                           DisplayGroup           Enabled                 Profile Action
----                          -----------                           ------------           -------                 ------- ------
RemoteDesktop-UserMode-In-UDP Remote Desktop - User Mode (UDP-In)   Remote Desktop            True Domain, Private, Public  Allow
MCX-TERMSRV-In-TCP            Media Center Extenders - XSP (TCP-In) Media Center Extenders   False                     Any  Allow
RemoteDesktop-UserMode-In-TCP Remote Desktop - User Mode (TCP-In)   Remote Desktop            True Domain, Private, Public  Allow
#>



Set-NetFirewallProfile -Profile Private -Enabled False  #disable the Windows Firewall for the Private profile




Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'  #fDenyTSConnections     : 0


Set-Service -Name TermService -StartupType Automatic
Restart-Service -Name TermService


#region Delete existing rules and recreate new rules to allow RDP
# --- Remove any leftover custom rules with our names (idempotent) ---
'RDP (TCP-In) 3389','RDP (UDP-In) 3389','RDP (TCP-In) 3389 - From My IP' |ForEach-Object { Get-NetFirewallRule -DisplayName $_ -ErrorAction SilentlyContinue | Remove-NetFirewallRule }

# --- Create fresh inbound rules for RDP ---
# TCP 3389 is required; UDP 3389 is optional for RDP performance on Win8+/Server 2012+.
New-NetFirewallRule -Name 'RemoteDesktop-UserMode-In-TCP' -DisplayName 'RDP (TCP-In) 3389' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 3389 -Profile Any -Program '%SystemRoot%\system32\svchost.exe' -Service TermService

New-NetFirewallRule -Name 'RemoteDesktop-UserMode-In-TCP' -DisplayName 'RDP (UDP-In) 3389' -Direction Inbound -Action Allow -Protocol UDP -LocalPort 3389 -Profile Any -Program '%SystemRoot%\system32\svchost.exe' -Service TermService


Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private


Get-NetTCPConnection -LocalPort 3389
<#LocalAddress                        LocalPort RemoteAddress                       RemotePort State       AppliedSetting OwningProcess
------------                        --------- -------------                       ---------- -----       -------------- -------------
::                                  3389      ::                                  0          Listen                     5240
192.168.0.5                         3389      184.58.203.74                       60080      Established Internet       5240
0.0.0.0                             3389      0.0.0.0
#>


Get-NetUDPEndpoint -LocalPort 3389
<#LocalAddress                             LocalPort
------------                             ---------
::                                       3389
0.0.0.0                                  3389
#>


Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True -AllowInboundRules True -AllowLocalFirewallRules True

#endregion