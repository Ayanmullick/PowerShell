
#region WMI or CIM

gwmi -namespace "root" -class "__Namespace" | Select Name      #List namespaces
Get-CimClass -Namespace root\hpq             #List classes in a namespace
Get-CimClass -Namespace root\hpq -ClassName *net*
Get-WmiObject -Class Win32_OperatingSystem | Get-Member| Where-Object {$_.name -Notmatch "__" -And $_.MemberType -eq "Property"}   #Members of a wmi clasS

#endregion
