#HTML reporting
Get-Process|select -First 2 -Property ProcessName,CPU,WS,Id | ConvertTo-Html -CssUri 'https://cdn.jsdelivr.net/gh/Ayanmullick/AzPaaS@master/test.css'|Out-File proc1.html;   Invoke-Item proc1.html  #Works
Get-Process|select -First 2 -Property ProcessName,CPU,WS,Id | ConvertTo-Html -CssUri 'https://raw.githubusercontent.com/Ayanmullick/AzPaaS/master/test.css'|Out-File proc.html; Invoke-Item proc.html  #doesn't work since GitHub returns in type 'text/plain'
#Acan add property too. However Title didn't work
$vmList|ConvertTo-Html -Property AzVMname,Hostname,VMId,OSType,CreatedUTC,IP,Subscription,SubscriptionId,ResourceGroup,User,DeletedUTC,Operation -Title VMDeletion -Head $head



#region v2
Using namespace System.Net
param($Request, $TriggerMetadata)
$body = Get-Process | Select ProcessName, ID, CPU, WS| ConvertTo-Html -Fragment | Out-String
Push-OutputBinding 'Response' ([HttpResponseContext]@{StatusCode = [HttpStatusCode]::OK; ContentType = "text/html"; Body = $body})
#endregion





#region Append
"Hello, world!" | Out-File -FilePath .\index.html -Encoding utf8 -Append 


Get-Process| ConvertTo-Html -Property ProcessName, ID, CPU, WS, Handles -Title ProcessList| Out-File -FilePath .\index.html -Encoding utf8 -Append 
#endregion

<#Renders GitHub html without github pages
https://htmlpreview.github.io/
https://raw.githack.com/
#>