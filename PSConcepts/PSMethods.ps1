#Intrinsic methods:  https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_intrinsic_members?view=powershell-7.3#foreach-and-where

#region foreach method  : https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_arrays?view=powershell-7.3#foreach

@('a', 'b', 'c').ForEach({ $PSItem.ToUpper() })


1,2,3|% {$PSItem}

(1,2,3).ForEach( {$PSItem})

#endregion



#region where method
(Get-Service).Where({ $_.Status -eq "Running" }, 'First') #Similar to Select-Object, there is a First and Last mode.   https://mcpmag.com/articles/2015/12/02/where-method-in-powershell.aspx

#split mode. Effectively splitting the collection in two parts; the first which meets the condition and the second which doesn't.  https://www.jonathanmedd.net/2017/05/powershell-where-where-or-where.html
$Services = (Get-Service).Where({ $_.Status -eq "Running" }, 'Split')
$Services[0]
$Services[1]
#endregion

#foreach-and-where-methods
@('a', 'b', 'c').ForEach({ $PSItem.ToUpper() }).Where({ $PSItem -ceq 'B' }) #https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_psitem?view=powershell-7.3#foreach-and-where-methods



#region split method
#https://devblogs.microsoft.com/scripting/using-the-split-method-in-powershell/
#https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_split?view=powershell-7.3