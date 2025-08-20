#Expandable section
$PreContent1 = "<h1> This is Bios Info as a List </h1>"
$PreContent2 = "<h2> + This is Bios Info as a Table </h2>"

$Bios = Get-CimInstance -class Win32_BIOS | Select PSComputerName, Manufacturer, BIOSVersion | ConvertTo-EnhancedHTMLFragment -As List -PreContent $PreContent1

$Bios2 = Get-CimInstance -class Win32_BIOS | Select PSComputerName, Manufacturer, BIOSVersion | ConvertTo-EnhancedHTMLFragment -As Table -PreContent $PreContent2 -MakeHiddenSection

ConvertTo-EnhancedHTML -HTMLFragments  $Bios,$Bios2 -CssUri styles2.css | Out-File Example.html







#region Queryable gridview
$Services = Get-Service | Select Name, DisplayName, Status | ConvertTo-EnhancedHTMLFragment -As Table -PreContent "<h2>Dynamic Services</h2>" -MakeTableDynamic
$Services2 = Get-Service | Select Name, DisplayName, Status | ConvertTo-EnhancedHTMLFragment -As Table -PreContent "<h2> Normal Services</h2>"
ConvertTo-EnhancedHTML -HTMLFragments $Services, $Services2 -CssUri styles2.css | Out-File DynamicExample.html



$Process = Get-Process|select -Property ProcessName,CPU,WS,Id|ConvertTo-EnhancedHTMLFragment -As Table -PreContent "<h2>Dynamic Processes</h2>" -MakeTableDynamic
ConvertTo-EnhancedHTML -HTMLFragments $Process -CssUri https://cdn.jsdelivr.net/gh/Ayanmullick/AzPaaS@master/styles2.css |Out-File proc.html; Invoke-Item proc.html






#In an AzFunction it needs the string replacement for https to avoid a 'mixed content' error on the browser. #Add  'EnhancedHTML2' = '2.*'  in requirements.psd  
Using namespace System.Net
param($Request, $TriggerMetadata)

$a = Get-Process | Select ProcessName, ID, CPU, WS|ConvertTo-EnhancedHTMLFragment -As Table -MakeTableDynamic
$body = [string](ConvertTo-EnhancedHTML -HTMLFragments $a -CssUri https://cdn.jsdelivr.net/gh/Ayanmullick/AzPaaS@master/test.css -Title Processes).replace("http://ajax","https://ajax")

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
    ContentType = "text/html"
})
#endregion




#Conditional formatting
$params = @{'As'='Table';
'PreContent'='<h2> All Services</h2>';
'MakeTableDynamic'=$true;
'TableCssClass'='grid';
'Properties'='Name','DisplayName', @{n='Service Status';e={$_.Status};css={if ($_.Status -eq "Stopped") { 'red' }}}}

$Services = Get-Service  | ConvertTo-EnhancedHTMLFragment @params
ConvertTo-EnhancedHTML -HTMLFragments $Services -CssUri C:\Pluralsight\HTML\styles2.css | Out-File paramexample.html


