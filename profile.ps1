#Install-Module AzurePSDrive,SHIPS
#Import-Module AzurePSDrive
#New-PSDrive -Name Azure -PSProvider SHiPS -root 'AzurePSDrive#Azure'
#Set-Location Azure:

Import-Module -Name PSReadLine -Version 2.2.0 -Verbose
Import-Module Az.Tools.Predictor -Verbose
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView




#Installs Profile--->   Invoke-Expression (Invoke-WebRequest -UseBasicParsing http://bit.ly/ayanProfile)
#                       iex (iwr -UseBasicParsing https://git.io/JtzUW)
