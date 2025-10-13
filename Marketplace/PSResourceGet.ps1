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



Set-PSResourceRepository -Name MAR -Trusted -Priority 10 -Verbose
<#VERBOSE: Performing the operation "Set repository's value(s) in repository store" on target "MAR".
PS C:\Users\ayanm> Get-PSResourceRepository

Name      Uri                                      Trusted Priority IsAllowedByPolicy
----      ---                                      ------- -------- -----------------
MAR       https://mcr.microsoft.com/               True    10       True
PSGallery https://www.powershellgallery.com/api/v2 True    50       True
#>

