#Installs Task manager
sudo apt-get update
sudo apt-get install gnome-system-monitor
gnome-system-monitor



#region Ubuntu 10.04
lsb_release -a  #check version
# Download the Microsoft repository GPG keys
wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
# Register the Microsoft repository GPG keys
sudo dpkg -i packages-microsoft-prod.deb
# Update the list of products
sudo apt-get update
# Install PowerShell
sudo apt-get install -y powershell
# Start PowerShell
pwsh


install-module SSHSessions
New-SshSession -ComputerName 52.179.171.150 -Username <> -Password <> -Verbose
Enter-SSHSshSession -ComputerName 137.116.36.177

#Worked for a VMSS VM with no Entra login enabled
Enter-AzVM -Ip 172.25.22.11 -LocalUser azureuser -PublicKeyFile ./id_rsa.pub
#endregion



touch test.txt #Creates file


#Install Snap store https://snapcraft.io/docs/installing-snap-on-ubuntu
sudo apt update
sudo apt install snapd  #sudo apt-get install snapd

#https://docs.microsoft.com/en-us/powershell/scripting/install/install-other-linux?view=powershell-7.2#installation-via-snap

ap2admin@Ubuntu-test:~$ sudo snap install powershell   
#error: This revision of snap "powershell" was published using classic confinement and thus may perform arbitrary system changes outside of the security sandbox that snaps are usually confined to, which may put your system at risk.
#If you understand and want to proceed repeat the command including --classic.

sudo snap install powershell --classic  #Worked

sudo snap refresh powershell #This is to update PowerShell once it is installed from the Snap store

#VSCode install | https://code.visualstudio.com/docs/setup/linux#_installation
sudo apt install ./code_1.66.2-1649664567_amd64.deb


#Login as root:  https://linuxize.com/post/how-to-change-root-password-in-ubuntu/


#region Docker file to enable xRDP[Opensource RDP implementation] to create the docker image| https://www.youtube.com/watch?v=0rl5145aEMk
FROM ubuntu:latest

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y ubuntu-desktop

RUN rm /run/reboot-required*

RUN useradd -m testuser -p $(openssl passwd 1234)
RUN usermod -aG sudo testuser

RUN apt install -y xrdp
RUN adduser xrdp ssl-cert

RUN sed -i '3 a echo "\
export GNOME_SHELL_SESSION_MODE=ubuntu\\n\
export XDG_SESSION_TYPE=x11\\n\
export XDG_CURRENT_DESKTOP=ubuntu:GNOME\\n\
export XDG_CONFIG_DIRS=/etc/xdg/xdg-ubuntu:/etc/xdg\\n\
" > ~/.xsessionrc' /etc/xrdp/startwm.sh

EXPOSE 3389

CMD service dbus start; /usr/lib/systemd/systemd-logind & service xrdp start ; bash

#endregion