using namespace WinUIShell
Import-Module MSAL.PS,WinUIShell

<#UAMI App registration update  |It should already have User.Read tenant permissions
1. 'Authentication' blade| 'Add a platform → Mobile and desktop applications'
2. Add these redirect URIs: https://login.microsoftonline.com/common/oauth2/nativeclient; http://localhost
3. 'Advanced settings'| 'Allow public client flows':'Yes' | 'Save'
#>
$params = @{ TenantId = '<>'; ClientId = 'b78956e0-5839-4cf4-8535-2e11ad6a4e44'
             RedirectUri = 'https://login.microsoftonline.com/common/oauth2/nativeclient'
}
try {$auth = Get-MsalToken @params -Interactive -Scopes User.Read
     $username = $auth.Account.Username} catch {$username = 'Unauthenticated'}

$w=[Window]@{Title='WinUI3 PS Entra Auth'}
$w.AppWindow.ResizeClient(800,200)
$w.Content=[TextBlock]@{Text="Hello, $username!"; FontSize=24; HorizontalAlignment='Center'; VerticalAlignment='Center'}
$w.Activate();$w.WaitForClosed()