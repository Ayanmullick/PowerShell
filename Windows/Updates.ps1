#region Change windows update settings

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "AUOptions" -Value 2 -Force -Confirm:$false
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "CachedAUOptions" -Value 2 -Force -Confirm:$false

   "NoCheck"      { $AuOptions = 1; $Op = "Never check for updates" }
   "CheckOnly"    { $AuOptions = 2; $Op = "Check for updates but let me choose wether to download and install them" }
   "DownloadOnly" { $AuOptions = 3; $Op = "Download updates but let me choose whether to install them" }
   "Install"      { $AuOptions = 4; $Op = "Install updates automatically" }

#endregion

#region Compare installed updates
$a= (Get-WmiObject -Class win32_quickfixengineering).hotfixid
   $b= $(Get-WmiObject -ComputerName EMGVWP745 -Class win32_quickfixengineering).hotfixid

   Compare-Object -ReferenceObject $a -DifferenceObject $b
#endregion

#region Patching date multiple servers
$Computers=Get-Content c:\s.txt
foreach ($server in ($Computers))
{Get-WmiObject -Class win32_quickfixengineering -ComputerName $server -ErrorAction SilentlyContinue|
        sort installedon -Descending|select -First 1 -Property pscomputername,installedon|ft -AutoSize -Wrap}
#endregion


#region Patching automation

Install-PackageProvider -Name "Nuget" -Force
Install-Module pswindowsupdate -Force -SkipPublisherCheck
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -Verbose  #patch windows OS from windows update


<#
Workflow Update-VMs
  {[cmdletbinding()]
   $b=Get-ADComputer -Filter 'Name -like "*dv*MRAS*ai*"'

   foreach -Parallel ($c in $b)
        { Install-WindowsUpdate -ComputerName $c.Name -MicrosoftUpdate -AcceptAll -Install -IgnoreReboot -Verbose}

    }




Workflow Reboot-VMs
  {[cmdletbinding()]
   $b=Get-ADComputer -Filter 'Name -like "*dv*MRAS*ai*"'
   foreach -Parallel ($c in $b)
        {Restart-Computer -ComputerName $c.Name -Force -Verbose}

    }
#>
#endregion


#region Patch or install update thru Powershell remotely
Invoke-Command -ComputerName localhost -Credential SQLSERVER-0\ayan -ScriptBlock {Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot -Verbose}

Install-Module PSWindowsUpdate -Verbose -Force
PsExec64.exe \\SQLSERVER-1 -u SQLSERVER-1\ayan -p '<>'  /accepteula cmd /c "Powershell "Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot -Verbose""
PsExec64.exe \\NLGDVMRASTABVM3 -u .\nladmin -p '<>'  /accepteula cmd /c "Powershell "Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot -Verbose""           #Install-WindowsUpdate  is the Alias
PsExec64.exe \\NLGUATJAMAGTVM1 -u .\nladmin -p '<>'  /accepteula cmd /c "Powershell "Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot -Verbose""               #Get-WindowsUpdate  is the cmdlet. However it didn't install the update.

#Without auto-reboot not all updates get installed
#one could use start-rsjob to further automate
#endregion


#Check in all Azure VM's if a specific KB is installed
Select-AzureRmSubscription -SubscriptionName NLG-CP-NON-PROD
Get-AzureRmVM|%{Get-WUHistory -ComputerName $PSItem.Name|? KB -EQ 'KB4338824'}


Get-WmiObject -Class win32_quickfixengineering      #get installed updates


