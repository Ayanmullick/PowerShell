#region Winget on Server
#https://4sysops.com/archives/install-winget-on-windows-server-and-activate-preview-features/comment-page-1/?unapproved=1256561&moderation-hash=1a7bb4761f01b2fb1cc3e1b1663de55c#comment-1256561

Invoke-WebRequest -Uri "https://dot.net/v1/dotnet-install.ps1" -OutFile "dotnet-install.ps1"   # Download the installation script
#.\dotnet-install.ps1 -Channel 7.0 -InstallDir "C:\dotnet"  # Execute the script to install .NET SDK
./dotnet-install.ps1 -Channel 8.0 -InstallDir "C:\dotnet" -verbose

[System.Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";C:\dotnet", [System.EnvironmentVariableTarget]::Machine)
dotnet --version




dotnet add package Microsoft.UI.Xaml --version 2.7.3

#https://learn.microsoft.com/en-us/troubleshoot/developer/visualstudio/cpp/libraries/c-runtime-packages-desktop-bridge#how-to-install-and-update-desktop-framework-packages
Invoke-WebRequest -Uri "https://dotnet.microsoft.com/download/dotnet/thank-you/sdk-7.0.0-windows-x64-installer" -OutFile "Microsoft.VCLibs.arm64.14.00.Desktop.appx"
Add-AppxPackage -Path "Microsoft.VCLibs.x64.14.00.Desktop.appx"



Add-AppxPackage -Path "c:\temp\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
<# Error on Server 2016
Add-AppxPackage : Deployment failed with HRESULT: 0x80073CF0, Package could not be opened.
error 0x8007007B: Opening the package from location Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle failed.
NOTE: For additional information, look for [ActivityId] 5f91ee5f-26fe-0001-7d09-925ffe26db01 in the Event Log or use the command line Get-AppxLog -ActivityID 5f91ee5f-26fe-0001-7d09-925ffe26db01
At line:1 char:1
+ Add-AppxPackage -Path "c:\temp\Microsoft.DesktopAppInstaller_8wekyb3d ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OpenError: (C:\temp\Microso...bbwe.msixbundle:String) [Add-AppxPackage], FileNotFoundException
    + FullyQualifiedErrorId : DeploymentError,Microsoft.Windows.Appx.PackageManager.Commands.AddAppxPackageCommand
 
#>

Get-AppxLog -ActivityID '5f91ee5f-26fe-0001-7d09-925ffe26db01'
Get-AppxPackage -AllUsers


dotnet tool install --global PowerShell --verbosity detailed  #succeeds. But couldn't find .net 8 while starting.

Invoke-WebRequest -Uri "https://aka.ms/dotnet-core-applaunch?missing_runtime=true&arch=x64&rid=win-x64&os=win10&apphost_version=8.0.10" -OutFile "dotnet-runtime-installer.exe"
start /wait dotnet-runtime-installer.exe 
#ended up manually downloading and installing runtime.  Worked

Invoke-WebRequest -Uri "https://aka.ms/getwinget" -OutFile "AppInstaller.msixbundle"
Add-AppxPackage -Path ".\AppInstaller.msixbundle"  #Still errors out

#Installing chocolatey:  https://chocolatey.org/install
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))  #erroring since no .net 4.8. Manually downloaded and installed. And rebooted
#https://dotnet.microsoft.com/en-us/download/dotnet-framework/thank-you/net48-web-installer

choco install winget  -verbose

<#
ERROR: This package requires a minimum of Windows 10 / Server 2019 version 1709 / OS build 16299.
The install of microsoft-vclibs-140-00 was NOT successful.
Error while running 'C:\ProgramData\chocolatey\lib\microsoft-vclibs-140-00\tools\chocolateyInstall.ps1'.
 See log for details.


winget-cli v1.8.1911 [Approved]
winget-cli package files install completed. Performing other installation steps.
ERROR: 'winget-cli' requires at least Windows 10 version 1809 (build 17763). See https://github.com/microsoft/winget-cli#installing-the-client for more information.
The install of winget-cli was NOT successful.
Error while running 'C:\ProgramData\chocolatey\lib\winget-cli\tools\chocolateyInstall.ps1'.
 See log for details.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading winget 1.8.1911... 100%
#>


choco install microsoft-windows-terminal -y -verbose
<#
microsoft-windows-terminal package files install completed. Performing other installation steps.
ERROR: This package requires at least Windows 10 version 1903/OS build 18362.x.
The install of microsoft-windows-terminal was NOT successful.
Error while running 'C:\ProgramData\chocolatey\lib\microsoft-windows-terminal\tools\chocolateyInstall.ps1'.
 See log for details.
#>
#endregion


#region PowerShell 7 on server 2012
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI" -Verbose

#Azure module install works
Set-PSRepository psgallery -InstallationPolicy Trusted -Verbose
Register-PSResourceRepository -Name MAR -Uri 'https://mcr.microsoft.com' -ApiVersion ContainerRegistry  -Verbose
Install-PSResource -Name Az.Compute,Az.Network,Az.Resources,Az.Storage -Repository MAR -Scope AllUsers -TrustRepository -Verbose


#Winget install fails. Choco install succeeds but Winget and Windows Terminal install from choco fails.
iex ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

#choco install winget  -verbose
#choco install microsoft-windows-terminal -y
choco install conemu -y  #Alternate terminal works
#endregion