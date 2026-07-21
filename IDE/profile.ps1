'CompletionPredictor','Az.Tools.Predictor'|%{(gmo -l $_)??(Install-PSResource $_ -Repository PSGallery -Scope CurrentUser -TrustRepository)}


Import-Module CompletionPredictor
Import-Module Az.Tools.Predictor

Set-PSReadLineOption -EnableScreenReaderMode:$false
Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView



#Installs Profile--->   Invoke-Expression (Invoke-WebRequest -UseBasicParsing http://bit.ly/ayanProfile)
#                       iex (iwr -UseBasicParsing https://git.io/JtzUW)
#       iex (iwr -UseBasicParsing https://raw.githubusercontent.com/Ayanmullick/PowerShell/refs/heads/master/IDE/profile.ps1)
#Set-PSReadLineKeyHandler -Chord Ctrl+b -ScriptBlock {iex (iwr -UseBasicParsing https://git.io/JtzUW)} -Verbose
#Set-PSReadLineKeyHandler -Chord Ctrl+b -ScriptBlock {iex (iwr -UseBasicParsing https://git.io/JtzUW);[Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()} -Verbose   
