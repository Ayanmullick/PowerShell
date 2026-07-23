#POWERSHELL_UPDATECHECK environment variable
:SetEnvironmentVariable("POWERSHELL_UPDATECHECK", "LTS", "User")
<#
$env:POWERSHELL_UPDATECHECK = "LTS"
PS C:\Temp> [Environment]::SetEnvironmentVariable("POWERSHELL_UPDATECHECK", "LTS", "User")
PS C:\Temp> [Environment]::GetEnvironmentVariable("POWERSHELL_UPDATECHECK", "User")
LTS
#>


#region #Sets the prompt to the last foldername in the path
#-Leaf  Indicates that this cmdlet returns only the last item or container in the path.
function prompt {     
    $folderName = Get-Location| Split-Path -Leaf   
    "$folderName > "
}
#endregion