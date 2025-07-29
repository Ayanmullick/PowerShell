#region New PSResourceGet module
Get-InstalledPSResource
Set-PSResourceRepository -Name PSGallery -Trusted -Verbose
Get-PSResourceRepository

Install-PSResource Microsoft.PowerShell.PSResourceGet -Prerelease -Verbose
Find-PSResource Microsoft.PowerShell.* #Works after module installation
#endregion



#Microsoft Artifact repository
Register-PSResourceRepository -Name MAR -Uri 'https://mcr.microsoft.com' -ApiVersion ContainerRegistry  -Verbose
Install-PSResource -Name Az -Repository MAR -Scope AllUsers -Verbose
