#Install-Module AzurePSDrive,SHIPS
#Import-Module AzurePSDrive
#New-PSDrive -Name Azure -PSProvider SHiPS -root 'AzurePSDrive#Azure'
#Set-Location Azure:

#Import-Module -Name PSReadLine -MinimumVersion 2.2.6
#PSReadLine  2.2.6| Az.Tools.Predictor 1.1.0| CompletionPredictor 0.1.1 #All predictors working fine       

Import-Module CompletionPredictor
Import-Module Az.Tools.Predictor
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView




#Installs Profile--->   Invoke-Expression (Invoke-WebRequest -UseBasicParsing http://bit.ly/ayanProfile)
#                       iex (iwr -UseBasicParsing https://git.io/JtzUW)
#Set-PSReadLineKeyHandler -Chord Ctrl+b -ScriptBlock {iex (iwr -UseBasicParsing https://git.io/JtzUW)} -Verbose
#Set-PSReadLineKeyHandler -Chord Ctrl+b -ScriptBlock {iex (iwr -UseBasicParsing https://git.io/JtzUW);[Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()} -Verbose   
