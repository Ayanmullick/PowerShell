

Get-AppxPackage|ft  #Remove-appxpackage to uninstall

#region uninstall using wmiobject
Get-WmiObject -Class Win32_Product | Select-Object -Property Name
$MyApp = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq “Some App"}
$MyApp.Uninstall()

#endregion


#Shows Microsoft packages and Windows store apps
Get-AppxProvisionedPackage -Online | Select DisplayName, PackageName, Version

#Shows enabled and disabled features
Get-WindowsOptionalFeature -Online | Group State | %{"`nState: $($_.Name)`n";$_.Group|Sort FeatureName|%{"  $($_.FeatureName)"}}

#Shows enabled and disabled Capabilities
Get-WindowsCapability -Online|Group State| %{"`nState: $($_.Name)`n";$_.Group|Sort Name|%{"  $($_.Name)"}}



Get-WindowsPackage -Online| Group PackageState | %{"`nPackageState: $($_.Name)`n";$_.Group|Sort PackageName|%{"  $($_.PackageName)"}}

Get-WindowsDriver -Online