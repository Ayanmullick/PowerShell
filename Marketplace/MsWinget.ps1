#region: PowerShell Client | https://powershellisfun.com/2024/11/28/using-the-powershell-winget-module/  | And installs winget too
#https://learn.microsoft.com/en-us/windows/package-manager/winget/#install-winget-on-windows-sandbox
$progressPreference = 'silentlyContinue'
Write-Host "Installing WinGet PowerShell module from PSGallery..."

#WARNING: Unable to download from URI 'https://go.microsoft.com/fwlink/?LinkID=627338&clcid=0x409' to ''.
#WARNING: Unable to download the list of available providers. Check your internet connection.
Install-PackageProvider -Name NuGet -Force | Out-Null  #Can fail if the internet is not available

Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null  #-Verbose -Scope AllUsers
Write-Host "Using Repair-WinGetPackageManager cmdlet to bootstrap WinGet..."
Repair-WinGetPackageManager  #Worked. Winget was running after this.
Write-Host "Done."


Install-PSResource Microsoft.WinGet.Client -Scope AllUsers -Verbose
Get-WinGetPackage|select -First 10
Get-WinGetPackage|? Source -EQ 'winget'|select -First 1
Get-WinGetPackage|? Source -EQ 'winget'|Update-WinGetPackage -Verbose  #Worked. Equivalent to 'Winget upgrade --all'
Install-WinGetPackage -Id Microsoft.PowerShell
Install-WinGetPackage -Id Postman.Postman -Scope Any -Verbose  #Works

#Older version
Install-Module WingetTools
Get-WGInstalled  #lists all the equivalent to command below

winget list
Get-WGPackage -ID Microsoft.PowerShell|select *  #Show package details


Find-WinGetPackage kubelogin
Install-WinGetPackage -Id Microsoft.Azure.Kubelogin -Verbose

Find-WinGetPackage -Id Microsoft.DotNet
Find-WinGetPackage -Name 'Microsoft .NET'
Find-WinGetPackage | Where-Object Id -like 'Microsoft.DotNet*runtime*'  #Lists only the runtimes
#endregion