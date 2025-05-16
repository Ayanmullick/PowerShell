#region Windows to Redhat
rpm -qia '*release*'  #RedHat version

#https://superuser.com/questions/1296024/windows-ssh-permissions-for-private-key-are-too-open/1296046#1296046
ssh -i .\ayan.pem ayan@192.168.0.5  #worked

#On RHEL 8: Direct download option dodn't work. https://docs.microsoft.com/en-us/powershell/scripting/install/install-rhel?view=powershell-7.1#installation-via-package-repository
curl https://packages.microsoft.com/config/rhel/8/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo # Register the Microsoft RedHat repository
sudo dnf install powershell # Install PowerShell
pwsh # Start PowerShell


#On Windows client
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'

#Add subsystem to SSH config
sudo nano /etc/ssh/sshd_config
Subsystem powershell /usr/bin/pwsh -sshs -NoLogo -NoProfile #CTRL+O ENTER to save and CTRL+X key to close nano editor
sudo service sshd restart


#Connect
ssh -i .\ayan.pem ayan@192.168.0.5   #Over private IP
ssh -i .\ayan.pem ayan@20.80.38.198  #Over public IP


$pssession = New-PSSession -Name RHELSession -HostName 192.168.0.5 -Port 22 -Subsystem powershell -UserName ayan -KeyFilePath .\ayan.pem -SSHTransport -Verbose  #Over private IP
$pssession = New-PSSession -Name RHELSession -HostName 20.80.38.198 -Port 22 -Subsystem powershell -UserName ayan -KeyFilePath .\ayan.pem -SSHTransport -Verbose  #Over public IP
Invoke-Command -Session $pssession -ScriptBlock {hostname}


#With password. Additional steps needed while connecting with password.
ssh ayan@192.168.0.6  #works


$Cred= New-Object System.Management.Automation.PSCredential "<>",$(ConvertTo-SecureString '<>' -asplaintext -force)
#Without storing credential on disk
$Cred= New-Object System.Management.Automation.PSCredential "<>",$(ConvertTo-SecureString "$(Get-AzKeyVaultSecret -VaultName RHEL84 -Name ayanPswd -AsPlainText)" -asplaintext -force)
New-SSHSession -ComputerName 65.52.236.54 -Port 22 -Credential $Cred -Verbose
(Invoke-SSHCommand -SessionId 0 -Command {hostname}).Output

#endregion
#Passwordless cert-based remoting isn't an option cross-platform. https://adamtheautomator.com/winrm-ssl/



#region Didn't work | Creating PS session using password didn't work. Friedrich Weinmann [friedrich.weinmann@microsoft.com ] confirmed SSH is the way forward with Linux
New-PSSession -ComputerName 192.168.0.6 -Port 22 -Name RHELSession -Credential $Cred -SessionOption $o  -Verbose
#-UseSSL: Needs cert configured on Linux VM
#  -Authentication Kerberos : -Kerberos is used when no authentication method and no user name are specified.  Kerberos accepts domain user names, but not local user names.


$o = New-PSSessionOption -SkipCACheck -SkipRevocationCheck -SkipCNCheck

set-item wsman:\localhost\client\TrustedHosts RHELPW -Concatenate -Force

  set winrm/config/client '@{AllowUnencrypted="true"}'
  winrm set winrm/config/client/auth '@{Basic="true"}'
  winrm set winrm/config/service/auth '@{Basic="true"}'

#endregion



#Doesn't work

New-SSHSession -ComputerName ayan@20.80.38.198 -Port 22 -KeyString $(Get-AzSshKey -ResourceGroupName RHEL -Name ayan).publicKey -Verbose

New-SSHSession -ComputerName 20.80.38.198 -Port 22 -Credential ayan -KeyString $((Get-AzSshKey -ResourceGroupName RHEL -Name ayan).publicKey) -AcceptKey -Verbose

New-SSHSession -ComputerName 20.80.38.198 -Port 22 -Credential ayan -KeyFile .\ayan.pem -AcceptKey -Verbose

New-SSHSession -ComputerName 20.80.38.198 -Port 22 -KeyFile .\ayan.pem -AcceptKey -Verbose