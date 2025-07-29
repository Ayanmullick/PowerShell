gwmi win32_pnpsigneddriver -Filter "DeviceClass = 'NET'"  | ft DeviceName,DriverVersion     #Driver version of all NIC's

Get-WindowsDriver -Online|select -Property *class* -Unique         #list driver classes on a system

Get-WmiObject win32_pnpsigneddriver | select Description , Manufacturer, driverdate, driverversion, signer


Get-PnpDevice   #Device manager cmdlets 2016 onwards
Get-PnpDevice|select Class -Unique  #list the classes of devices
(Get-PnpDevice|select Class -Unique).count  #number of device categories #My azure VM had 22, laptop had 30, DC2 confidential Gen2 azure vm had 20 and nested Hyper-V Gen2 vm with 2019 Core has 15


#3rd party drivers
gwmi win32_systemdriver -ComputerName ayn -Credential administrator|? pathname|?{(Get-ItemProperty $psitem.pathname -ErrorAction Ignore).VersionInfo.companyname -NotLike "*microsoft*"}|sort state|ft -AutoSize
gwmi win32_systemdriver | select *, @{ N='CompanyName';E={ (Get-ItemProperty $_.pathname -ErrorAction Ignore).VersionInfo.companyname }} | Where companyname -NotLike "*microsoft*" | sort state | ft Status, State, Name, ExitCode, CompanyName -AutoSize -Wrap

#3rd party software
gwmi win32_product|? {$_.name -notlike "*Microsoft*"}|   select name
gwmi win32_product|? {$_.name -notlike "*Microsoft*" -and $_.vendor -notlike "*Microsoft*" }|select name, version,installdate,vendor|sort installdate -Debug|ft -AutoSize -Wrap
