#Dependencies: PS 5.1. and PSFTP module

#region Zip logs
$Directory= Get-ChildItem C:\FleetAtlas -Name *WFS*
$folder=New-Item -ItemType Directory -Path $("d:\"+$Directory+'_'+$(Get-Date -Format "MM.dd.yy"))
'Archiv\Tour','Archiv\Verkauf','Archiv\Export','FTP\Device','Log\Tour\201910','Log\ExternalApiConnector','Log\Verkauf'|
                % {$source = Get-Item -Path $('C:\FleetAtlas\'+$Directory+'\Data\'+$PSItem)                                     #can add last modified condition for this month
                   Compress-Archive -Path $source.FullName -DestinationPath $($folder.FullName+"\"+$source.Parent+$source.Name) -CompressionLevel Optimal}
#endregion

#region FTP connection
$FTPCredential = New-Object System.Management.Automation.PSCredential('WFSUS',$(ConvertTo-SecureString -String $([System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String("cAAhAHsAVwBgAFkAcQAhADIAXgA="))) -AsPlainText -Force))
Set-FTPConnection -Credentials $FTPCredential -Server 209.99.46.140 -Session MySession -UsePassive 
$Session = Get-FTPConnection -Session MySession 
#endregion

#region Upload logs
New-FTPItem -Session $Session -Name $folder.Name
Get-ChildItem $folder.FullName|%{Add-FTPItem -Session $Session -LocalPath $PSItem.FullName -Path $folder.Name}
#endregion

Remove-Item $folder -Force -Recurse

#Remove-FTPItem -Session $Session -Path $folder.Name -Recurse -Verbose
#Get-FTPChildItem -Session $Session -Path /htdocs 
