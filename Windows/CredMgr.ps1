Find-PSResource TUN.CredentialManager|fl *

Install-PSResource -Scope AllUsers -Verbose -TrustRepository -Repository PSGallery -Name TUN.CredentialManager

#region discovery

Get-StoredCredential
Get-StoredCredential -AsCredentialObject

Get-StoredCredential|? UserName -EQ '<>'


(Get-StoredCredential -AsCredentialObject).Where({ $_.Type -eq 'Generic'})

Get-StoredCredential -AsCredentialObject|ft

(Get-StoredCredential -AsCredentialObject -ExcludeClearPassword).Where({ $_.TargetName -match '<domain>'})|
    sort LastWritten|Format-Table UserName,Type,LastWritten, PaswordSize,Persist


(Get-StoredCredential -AsCredentialObject -ExcludeClearPassword).Where({ $_.TargetName -notmatch '<domain>' -and $_.TargetName -notmatch '<domain>' })|
        sort LastWritten| Format-Table UserName,Type,LastWritten, PaswordSize,Persist,TargetName
#endregion

#region inspect credential object
$UserName = '<>'

$StoredCredentials = @(
    foreach ($Credential in (Get-StoredCredential -AsCredentialObject -ExcludeClearPassword)) {
        if ($Credential.UserName -eq $UserName) {
            $Credential
        }
    }
)

$StoredCredentials | Select-Object TargetName,Type,UserName,Persist,LastWritten

$StoredCredentials = (Get-StoredCredential -AsCredentialObject -ExcludeClearPassword).Where({ $_.UserName -eq $UserName })

(Get-StoredCredential -AsCredentialObject).Where({ $_.UserName -eq '<>'})
#endregion

#region remove credential
$StoredCredential = (Get-StoredCredential -AsCredentialObject).Where({ $_.UserName -eq '<>'})
Remove-StoredCredential -Target $StoredCredential.TargetName -Type $StoredCredential.Type
#endregion


#region remove credential in groups
$StoredCredential = (Get-StoredCredential -AsCredentialObject).Where({ $_.UserName -match '<domain>'})
Remove-StoredCredential -Target $StoredCredential.TargetName

$StoredCredential = (Get-StoredCredential -AsCredentialObject).Where({ $_.TargetName -match '<domain>'})
Remove-StoredCredential -Target $StoredCredential.TargetName

#Works only if all returned credentials are of type 'Generic'
(Get-StoredCredential -AsCredentialObject).Where({$_.TargetName -like '*<domain>*'}).TargetName | Remove-StoredCredential
#otherwise
(Get-StoredCredential -AsCredentialObject).Where({$_.TargetName -like '*<domain>*'}) | % {Remove-StoredCredential -Target $_.TargetName -Type $_.Type}

#endregion