


#Proxy https://www.scriptinglibrary.com/languages/powershell/how-to-modify-your-proxy-settings-with-powershell/
netsh winhttp show proxy
Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' | findstr ProxyServer

netsh winhttp reset proxy
netsh winhttp set proxy proxy-server=proxy.conexus.svc.local:3128 bypass-list="*itservices.sbc.com;localhost;"


$env:HTTPS_PROXY="proxy.conexus.svc.local:3128" #Setup proxy in code if if needed
$env:HTTP_PROXY = "proxy.conexus.svc.local:3128"


#Set at the registry level if the environment variable doesn't work
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -name ProxyServer -Value "$($server):$($port)"
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -name ProxyEnable -Value 1

#Set at session level in the command prompt
set HTTP_PROXY=http://proxy.conexus.svc.local:3128
set HTTPS_PROXY=http://proxy.conexus.svc.local:3128

#set HTTP_PROXY=http://proxy_userid:proxy_password@proxy_ip:proxy_port  #Syntax for authentication too


