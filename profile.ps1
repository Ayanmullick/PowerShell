#Install-Module AzurePSDrive,SHIPS
Import-Module AzurePSDrive
New-PSDrive -Name Azure -PSProvider SHiPS -root 'AzurePSDrive#Azure'
Set-Location Azure:



#Installs Profile--->   Invoke-Expression (Invoke-WebRequest -UseBasicParsing http://bit.ly/ayanProfile)  or  https://git.io/fhGoi
