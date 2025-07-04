#Install-PSResource -Name WinUIShell -Scope AllUsers -Verbose
#Install-PSResource -Name MSAL.PS -Scope AllUsers -Verbose

using namespace WinUIShell  #somehow both are needed
Import-Module WinUIShell

$w=[Window]::new()
$w.Title='WinUI from PowerShell'
$w.AppWindow.ResizeClient(800,200)
$t=[TextBlock]@{Text='Hello World!';FontSize=24;HorizontalAlignment='Center';VerticalAlignment='Center'}
$w.Content=$t
$w.Activate()
$w.WaitForClosed()