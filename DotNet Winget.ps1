#.net framework version
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse |Get-ItemProperty -name Version,Release -EA 0 |Where { $_.PSChildName -match '^(?!S)\p{L}'} |Select PSChildName, Version, Release|ft -AutoSize
(Get-ItemProperty "HKLM:Software\Microsoft\NET Framework Setup\NDP\v4\Full").Version

#region Update dotnet framework  .Net   .  check how to install Github packages
Get-PackageSource  #Chocolatey should already be installed
Get-PackageProvider

Register-PackageSource -Name MyNuGet -Location https://www.nuget.org/api/v2 -ProviderName NuGet -Verbose

Find-Package -Source MyNuGet -Name *dotnet*




Register-PackageSource -Name chocolatey -Location http://chocolatey.org/api/v2 -Provider PowerShellGet -Trusted -Verbose
Install-Package -Name Firefox -ProviderName chocolatey -verbose  #the .net one didn't work . Might need troubleshooting

Find-Package -Source Chocolatey

Find-Package -Source Chocolatey -Name GoogleChrome |select *
Install-Package -Name GoogleChrome -ProviderName chocolatey -verbose  #worked even if directly run without anything else.


Find-Package -ProviderName chocolatey -Name dotnet4.7.2 -Verbose  #2 packages located
Install-Package -Name dotnet4.7.2 -ProviderName  chocolatey -Verbose  #doesn't work . couldn't find file specified
#endregion




#region Install or upgrade PowerShell directly from the Web
Install-Module MSI -Verbose -Force  #installs the msi installation module
$releases = Invoke-RestMethod https://api.github.com/repos/powershell/powershell/releases
$url=((($releases.Where({$PSItem.tag_name -NotLike '*preview*'})|Sort-Object tag_name -Descending)[0]).assets).Where({$PSItem.name -like '*x64.msi'}).browser_download_url  #Put '-like' if you need preview version
(New-Object System.Net.WebClient).DownloadFile($url,($path="C:\Temp\PowerShellPreview.msi"))   #Or Invoke-WebRequest -Uri $url -OutFile $output   #In this format . Had to used in azure container
Install-MSIProduct -Path $path -Verbose
#endregion


iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI"

winget install PowerShell


dotnet --version
dotnet --info

choco upgrade chocolatey   #https://docs.chocolatey.org/en-us/choco/commands/upgrade#examples
choco   #Output: Chocolatey v0.9.9.12
choco list --local-only   #Lists packages installed


#region Winget

#region: PowerShell Client | https://powershellisfun.com/2024/11/28/using-the-powershell-winget-module/
#https://learn.microsoft.com/en-us/windows/package-manager/winget/#install-winget-on-windows-sandbox
$progressPreference = 'silentlyContinue'
Write-Host "Installing WinGet PowerShell module from PSGallery..."
Install-PackageProvider -Name NuGet -Force | Out-Null
Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
Write-Host "Using Repair-WinGetPackageManager cmdlet to bootstrap WinGet..."
Repair-WinGetPackageManager  #Worked. Winget was running after this.
Write-Host "Done."


Install-PSResource Microsoft.WinGet.Client -Scope AllUsers -Verbose
Get-WinGetPackage|select -First 10
Get-WinGetPackage|? Source -EQ 'winget'|select -First 1
Get-WinGetPackage|? Source -EQ 'winget'|Update-WinGetPackage -Verbose  #Worked
Install-WinGetPackage -Id Microsoft.PowerShell
Install-WinGetPackage -Id Postman.Postman -Scope Any -Verbose  #Works

#Older version
Install-Module WingetTools
Get-WGInstalled  #lists all the equivalent to command below

winget list
Get-WGPackage -ID Microsoft.PowerShell|select *  #Show package details
#endregion


winget -v
winget list




winget search dotnet                        #Search packages. no wild card
winget show Microsoft.dotnetRuntime.6-x64   #Show package details

Winget upgrade --id Microsoft.Edge
Winget upgrade --all   #Winget upgrade --all --silent  #upgrades all pagka
winget upgrade --all --include-unknown --verbose  #Includes unknown packages 
Winget upgrade --id  Microsoft.dotnet

<#Multiple installed packages found matching input criteria. Please refine the input.
Name                      Id
----------------------------------------------------------------
Microsoft .NET SDK        Microsoft.dotnet
.NET Core SDK 1.1.0 (x64) {67d148ca-6fe2-47ec-bf5c-fbd64345d511}
#>

winget list --name 'Microsoft .NET SDK'

winget install -?
#Couldn't figure upgrading which dotnet in reasonable time. Used below example
winget install -e --id Microsoft.dotnet  #works

winget list --name 'Microsoft .NET SDK'

#Uninstall failed too
winget uninstall --id Microsoft.dotnet --version 5.2.921.52710

<#Multiple installed packages found matching input criteria. Please refine the input.
Name                             Id
-----------------------------------------------------------------------
Microsoft .NET SDK               Microsoft.dotnet
Microsoft .NET SDK 6.0.100 (x64) {7239b982-23ee-406a-8750-f39b61bfd2f2}
.NET Core SDK 1.1.0 (x64)        {67d148ca-6fe2-47ec-bf5c-fbd64345d511}
#>

#Error: Failed when searching source: msstore | An unexpected error occurred while executing the command: |0x8a150044 : The rest source endpoint is not found.
winget source remove --name msstore
#To add back
winget source list
winget source add --name msstore --arg https://storeedgefd.dsx.mp.microsoft.com/v9.0



#Uninstalled from 'Programs & Features'
.Net Core SDK 5
.Net Core SDK 1.1
.Net Core SDK 2.0
.Net Core SDK 2.1
.Net Core SDK 2.1.202
.Net Core SDK 2.1.402
.Net Core SDK 2.1.524

.Net Core SDK 4.6.1  #Got warning that 1 or more products may stop working.


#Only one .Net SDK
<#PS C:\> winget list --name 'Microsoft .NET SDK'
Name               Id               Version      Source
--------------------------------------------------------
Microsoft .NET SDK Microsoft.dotnet 6.1.21.52711 winget
#>





#Installs PowerShell and VSC together. The store versions have issues due to sandboxing
winget install Microsoft.PowerShell Microsoft.VisualStudioCode --verbose  

winget install Microsoft.PowerShell.Preview Microsoft.VisualStudioCode.Insiders --verbose

<#I was facing issues with the store version of Powershell's compatibility with VS code . I uninstalled them and reinstalled from Winget . However eventually it turned out to be an issue with the Modi path priority .  
Powershell was loading an older version of PS readline . Updating the priority of the module paths and making the program files all user scope destination the first priority resolve the issue . 
Set 'C:\program files\powershell\7\Modules' as top priority from  sysdm.cpl>>Advanced>>Environment variables>>PSModulepath

#>

winget install --id Microsoft.WindowsTerminal -e --scope machine  #Installs on machine scope instead of the user scope
#Installed from GitHub release page:  https://github.com/microsoft/terminal/releases
runas /user:<Domain>\adminV-MullicA /savecred c:\temp\terminal\wt.exe

#endregion




#region dotnet

dotnet --list-sdks
<#
2.0.3 [C:\Program Files\dotnet\sdk]
2.1.402 [C:\Program Files\dotnet\sdk]
6.0.100 [C:\Program Files\dotnet\sdk]
#>

#region Uninstall older .Net SDKs  | https://github.com/dotnet/cli-lab/releases
# Define the URL for the installer
$installerUrl = "https://github.com/dotnet/cli-lab/releases/download/1.7.550802/dotnet-core-uninstall-1.7.550802.msi"
$installerPath = "C:\temp\installer.msi"

Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath  # Download the installer
Start-Process -FilePath $installerPath -ArgumentList "/quiet", "/norestart" -Wait    # Install the tool. Need to restart Terminal after this.

dotnet-core-uninstall remove --sdk 8.0.204 --verbosity detailed #Unistall the SDK. Worked

#endregion



dotnet clean   #removes references to old dlls



#First Blazor WASM project
dotnet new blazorwasm -o \HelloBlazor
dotnet run  #Make sure you have the JavaScript debugger extension

dotnet add package markdig


#region: Run PowerShell in .NET |   https://github.com/adamdriscoll/youtube/tree/main/dotnet/Run%20PowerShell%20in%20.NET
dotnet new console -o \Console
dotnet add package Microsoft.PowerShell.SDK


#region:  Program.cs
using System.Management.Automation;
using var ps = PowerShell.Create();
Console.WriteLine("Hello, World!");
#endregion


#endregion

#endregion







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

Get-AppxLog -ActivityID 5f91ee5f-26fe-0001-7d09-925ffe26db01
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
