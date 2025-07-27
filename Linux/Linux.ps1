ssh -l nladmin 10.191.97.196


Find-Module -Tag PSEdition_Core



#Carbon Black installation----Use sep or WinSCP to copy files to the Linux box
tar -xzvf CarbonBlackLinuxInstaller-v6.1.3.71227-Servers-Azure.tar.gz
ls
cat readme.txt
sudo ./CarbonBlackClientSetup-linux-v6.1.3.71227.sh


#view log contents
nano commandexecution.log


mkdir /var/lib/test


#DomainJoin  --> Didn't work
sudo yum install realmd sssd krb5-workstation krb5-lib 
sudo yum install realmd sssd krb5-workstation krb5-libs samba-common-tools samba-client samba-common cifs-utils oddjob oddjob-mkhomedir
 
sudo realm join --computer-ou="ou=CMS-CP-NON-PROD,ou=Servers,ou=NLGAzure,dc=CORP,dc=NLG,dc=NET" -U '<>@CORP.NLG.NET' --verbose CORP.NLG.NET



sudo yum install httpd -y 
systemctl enable httpd --now
sudo systemctl status firewalld
sudo firewall-cmd --add-service=http 
sudo systemctl stop firewalld  #disables firewall service


#PowerShell SSH
Install-Module Posh-SSH -Verbose
New-SSHSession -ComputerName NLGPDAPIBASVM01
Invoke-SSHCommand -SessionId 0 -Command {hostname}






#Debian|  https://dejanstojanovic.net/powershell/2018/june/remote-powershell-core-session-to-a-linux-host-from-windows-machine/
#Enter-pssession worked fine
#Setting up PowerShell on Linux
sudo apt-get update  
sudo apt-get install curl gnupg apt-transport-https  
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -  
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-stretch-prod stretch main" &gt; /etc/apt/sources.list.d/microsoft.list'    #https://packages.microsoft.com/repos/microsoft-debian-stretch-prod/dists/stretch/main/
sudo apt-get update  
# Install PowerShell  
sudo apt-get install -y powershell  

pwsh -V  

#Configure OpenSSH on Linux host
sudo nano /etc/ssh/sshd_config 
Subsystem powershell /usr/bin/pwsh -sshs -NoLogo -NoProfile 
#Save the file and exit nano editor with CTRL+O ENTER to save and CTRL+X key combination to close nano editor
#Could add using Add-Content too. However need to be signed as root. sudo doesn't work in PowerShell. 
#https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/add-content?view=powershell-7.1#example-1--add-a-string-to-all-text-files-with-an-exception
sudo service sshd restart  

#Setting up PowerShell 6 Core on Windows machine             https://github.com/PowerShell/PowerShell#get-powershell
cd C:\Program Files\PowerShell\6.0.2  
pwsh -V  
rundll32 sysdm.cpl,EditEnvironmentVariables  
setx PATH "%PATH%;C:\Program Files\PowerShell\6.0.2" /M 

#Setting up OpenSSH on Windows machine     https://github.com/PowerShell/Win32-OpenSSH/releases
PowerShell -ExecutionPolicy bypass -File "C:\Program Files\OpenSSH\install-sshd.ps1"
rundll32 sysdm.cpl,EditEnvironmentVariables  
#Path list should already contain path to OpenSSH with value %SYSTEMROOT%\System32\OpenSSH\. If this value is not present in the Path list, add the path of OpenSSH installation which is in our case C:\Program Files\OpenSSH.


netsh advfirewall firewall add rule name=sshd dir=in action=allow protocol=TCP localport=22  
PowerShell -command "Restart-Service sshd -Force"  

#Connect to remote session from PowerShell 6 Core with OpenSSH
Invoke-Command -Hostname "IP or Hostname" -UserName "Username" -ScriptBlock {PowerShell commands}  
Enter-Pssession -Hostname "IP or Hostname" -UserName "Username" -ScriptBlock {PowerShell commands}
#--------------------------------------------------------------------------------


#region  Connect Linux VM to Azure AD

Get-AzureRmVM -ResourceGroupName Linux -Name Ubuntu

Set-AzureRmVMExtension -Publisher Microsoft.Azure.ActiveDirectory.LinuxSSH -Name AADLoginForLinux -ResourceGroupName Linux -VMName Ubuntu -Location eastus2 -ExtensionType AADLoginForLinux -TypeHandlerVersion 1.0 -Verbose
#This is the extension to add AAD login for a Linux VM







$VmName = '<vm-name>'
$vm = Get-AzureVM -ServiceName $VmName -Name $VmName

$ExtensionName = 'VMAccessForLinux'                            #This is the extension to do RBAC
$Publisher = 'Microsoft.OSTCExtensions'
$Version = '1.5'

$PublicConf = '{}'
$PrivateConf = '{
  "username": "<username>",
  "password": "<>"
}'

Set-AzureVMExtension -ExtensionName $ExtensionName -VM $vm `
  -Publisher $Publisher -Version $Version `
  -PrivateConfiguration $PrivateConf -PublicConfiguration $PublicConf |
  Update-AzureVM








$scope = (Get-AzureRmVM -ResourceGroupName Linux -Name Ubuntu).id



New-AzureRmRoleAssignment -SignInName ayn@<>.onmicrosoft.com -RoleDefinitionName "Virtual Machine Administrator Login" -Scope $scope -Verbose  
New-AzureRmRoleAssignment -ObjectId '832b1bdf-d0bc-4c03-a97b-91279eb9ab21' -RoleDefinitionName "Virtual Machine Administrator Login" -Scope $scope -Verbose



New-AzureRmRoleAssignment -SignInName ayanmullick@<>.com -RoleDefinitionName "Virtual Machine Administrator Login" -Scope $scope -Verbose  #didn't work with sign in name. had to use object id
New-AzureRmRoleAssignment -ObjectId 16fe1c2a-8a92-4615-9a34-99453d2b6c9c -RoleDefinitionName "Virtual Machine Administrator Login" -Scope $scope -Verbose


New-AzureRmRoleAssignment -SignInName testuser@ayanmullickhotmail.onmicrosoft.com -RoleDefinitionName "Virtual Machine Administrator Login" -Scope $scope -Verbose #didn't work with sign in name. had to use object id

#endregion



#region set IP address on Linux VM NIC

#https://danielmiessler.com/study/manually-set-ip-linux/

sudo ifconfig eth0 192.168.1.5 netmask 255.255.255.0 up
sudo route add default gw 192.168.1.1
sudo echo "nameserver 1.1.1.1" > /etc/resolv.conf
sudo ping google.com
#worked

#endregion



df #is equivalent of Get-Volume
df -H --output=size,used,avail
df -H --output=source,size,used,avail
df -ah

#region tiny core install
tce-load -wi tc-install  #wi stands for windows manager.  tc install stands for tiny core install

sudo tc-install.sh

#endregion





#region Tiny core tests
sudo touch hello.sh   #create a new sh file

rm filename   #delete filename

filetool.sh -b
backing up files to  /mnt/sda1/tce/mydata.tgz/



tce-load -wi vim -y   #installs vim

cat /mnt/sda1/tce/onboot.lst
cat /opt/bootlocal.sh  #bootsync.sh loads before that


cat file >> file2
echo 'text to append' >> file2
printf "text to append\n" >> fileName



installed git

tce-load -wi git -y 


https://github.com/PowerShell/PowerShell/releases/download/v6.2.1/powershell-6.2.1-linux-arm64.tar.gz

#endregion


#region TinyCore install
n  install from net

64  architecture

F   for hard drive installation

1 to install on whole disk

2 select sda disk for the install    #had failed with fd0

y for installing bootloader
enter   installextensions

3  select ext4 as formatting option

y  select mark fd0 active bootable

vga=normal  syslog  showapps waitusb=5


eject disk and 'sudo reboot'


update ip address

tce-load -wi Xfbdev openbox obconf bash aterm firefox-ESR  #loads some apps

#endregion


#region  TinyCore Persistence
sudo vi /opt/bootlocal.sh  #to edit bootlocal.sh 

#add the network commands

:q Enter  to exit
Esc for command mode
:wq Enter to save and quit



filetool.sh -b  backup the file to ensure persistence

#endregion


#region interview questions
uname -a  #checks kernel version
ifconfig   and ip addr #checks ip address
service name status   #checks service status
service name start
service name stop

systemctl status servicename  #checks service status

su -sh foldername   #folder size check

netstat 
netstat -tulpn

ps aux| grep processname  #cpu consumption of specific process
htop  #searchable task manager

ls/mnt
mount /dev/sda2/ /mnt  #mounts a partition in a device to the mount folder
/etc/fstab  #shows volumes mounted at boot.


free -m  #shows free memory

#endregion


#region https://docs.microsoft.com/en-us/dotnet/core/install/linux-package-manager-ubuntu-1804#install-the-net-core-runtime
sudo add-apt-repository universe
sudo apt-get update
sudo apt-get install apt-transport-https
sudo apt-get update
sudo apt-get install dotnet-runtime-3.1
#endregion

#region SNap  https://snapcraft.io/docs/installing-snap-on-ubuntu     https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7#snap-package
sudo apt update
sudo apt install snapd
#endregion



#region Alpine Linux
#Check version
cat /etc/os-release  
cat /etc/issue


alpine.exe config --default-user root  #Need to run this and reconnect otherwise it 

#Then run the commands without Sudo to install PowerShell
#https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7.2#installation-via-direct-download---alpine-39-and-310

ifconfig
netstat #didn't work
route
ping google.com

#While updating PowrShell. Failed so far
rm -r /opt/microsoft/powershell/7
apk add tar
rm /tmp/powershell.tar.gz


#Image for Azure container instance: mcr.microsoft.com/powershell:alpine-3.12|  https://hub.docker.com/_/microsoft-powershell
#https://www.microsoft.com/en-us/p/alpine-wsl/9p804crf0395?activetab=pivot:overviewtab
#endregion
