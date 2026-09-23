#Install the AWS installer
Install-PSResource -Name AWS.Tools.Installer -Repository PSGallery -Scope AllUsers
Import-Module AWS.Tools.Installer 

#Use the installer to install the required service modules
$Modules = 'AWS.Tools.SecurityToken','AWS.Tools.ResourceExplorer2'
Install-AWSToolsModule -Name $Modules -Version '5.*' -Scope AllUsers

#Import and verify
Import-Module -Name AWS.Tools.Common,AWS.Tools.SecurityToken,AWS.Tools.ResourceExplorer2
Get-Module -Name AWS.Tools.Common,AWS.Tools.SecurityToken,AWS.Tools.ResourceExplorer2 |Select-Object Name,Version
Get-AWSPowerShellVersion -ListServiceVersionInfo

Get-AWSCredential -ListProfileDetail


#https://us-east-1.console.aws.amazon.com/iam/home?region=us-east-1
Invoke-AWSLogin -ProfileName '<>-console' -Region 'us-east-2' -Remote

$Rex = @{ProfileName = 'PSUser'; Region = 'us-east-1'; ErrorAction = 'Stop'}
Get-AREXIndexList @Rex | Select-Object Region, Type, Arn
Get-STSCallerIdentity @Rex

#region Query resources without root access
#$Rex = @{ProfileName = '<>-console'; Region = 'us-east-1'; ErrorAction = 'Stop'}  #User login with root
$Rex = @{ProfileName = 'PSUser'; Region = 'us-east-1'; ErrorAction = 'Stop'}
$ViewArn = Get-AREXDefaultView @Rex
if (-not $ViewArn) { throw 'No default Resource Explorer view found. Stopping without creating one.' }

$Resources = Search-AREXResource @Rex -QueryString '' -ViewArn $ViewArn -Select Resources
$Resources | Sort-Object Service, ResourceType, Arn | Format-Table Service, Region, ResourceType, Arn -AutoSize -Wrap
#endregion