[CmdletBinding()]
param ()

process {
    $currentTime = Get-Date
    Write-Output $currentTime
}

<#Script installation steps
$Script   = 'Get-CurrentTime' #Replace with Script name
$DestPath = [Environment]::GetFolderPath('MyDocuments')+"\PowerShell\Scripts"  #User's default script folder

(New-Object System.Net.WebClient).DownloadFile("https://github.com/Ayanmullick/PowerShell/raw/refs/heads/master/$Script.ps1","$DestPath\$Script.ps1")   #Download script
If (($env:PATH -split ';') -notcontains $DestPath) {$env:Path += ";$DestPath"} #Add Script folder path to environment variable, if not present, for intellisense.
#>