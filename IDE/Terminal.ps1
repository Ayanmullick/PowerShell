#POWERSHELL_UPDATECHECK environment variable
:SetEnvironmentVariable("POWERSHELL_UPDATECHECK", "LTS", "User")
<#
$env:POWERSHELL_UPDATECHECK = "LTS"
PS C:\Temp> [Environment]::SetEnvironmentVariable("POWERSHELL_UPDATECHECK", "LTS", "User")
PS C:\Temp> [Environment]::GetEnvironmentVariable("POWERSHELL_UPDATECHECK", "User")
LTS
#>