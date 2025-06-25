#region  Enable remote desktop
Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections"

Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

#Disable
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 1
Disable-NetFirewallRule -DisplayGroup "Remote Desktop"


#https://theitbros.com/how-to-remotely-enable-remote-desktop-using-powershell/
$comps = "Server1", "Server2", "Server3", "Server4"
Invoke-Command -ComputerName $comps -ScriptBlock {Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0}
Invoke-Command -ComputerName $comps -ScriptBlock {Enable-NetFirewallRule -DisplayGroup "Remote Desktop"}
Invoke-Command -ScriptBlock {net localgroup "remote desktop users" /add "contoso\asmith"} -ComputerName Server1.contoso.com

#How to Enable Remote Desktop over WMI?  
Get-WmiObject -Class Win32_TerminalServiceSetting -Namespace root\CIMV2\TerminalServices -Computer 192.168.1.90 -Authentication 6  #To check if RDP access is enabled on the remote computer 
Get-WmiObject -Class Win32_TerminalServiceSetting -Namespace root\CIMV2\TerminalService #To enable RDP and add a Windows Firewall exception rule




#Import a module from a remote computer

$adsession = New-pssession -computerName dc
Import-pssession -session $adsession -Module ActiveDirectory

#creates shortcuts that points to the module on the domain controller

#endregion