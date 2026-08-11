#region POWERSHELL_UPDATECHECK environment variable
$env:POWERSHELL_UPDATECHECK = "LTS"
[Environment]::SetEnvironmentVariable("POWERSHELL_UPDATECHECK", "LTS", "User")
[Environment]::GetEnvironmentVariable("POWERSHELL_UPDATECHECK", "User")       #LTS
#endregion


#region #Sets the prompt to the last foldername in the path
#-Leaf  Indicates that this cmdlet returns only the last item or container in the path.
function prompt {     
    $folderName = Get-Location| Split-Path -Leaf   
    "$folderName > "
}

function prompt {"$(Get-Location| Split-Path -Leaf)>"}  #OneLiner
#endregion