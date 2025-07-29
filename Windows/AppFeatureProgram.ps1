

Get-AppxPackage|ft  #Remove-appxpackage to uninstall

#region uninstall using wmiobject
Get-WmiObject -Class Win32_Product | Select-Object -Property Name
$MyApp = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq “Some App"}
$MyApp.Uninstall()

#endregion


