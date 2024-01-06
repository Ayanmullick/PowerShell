#encryption extension https://docs.microsoft.com/en-us/azure/virtual-machines/windows/disk-encryption-powershell-quickstart

#https://docs.microsoft.com/en-us/powershell/module/bitlocker/enable-bitlocker?view=winserver2012r2-ps&redirectedfrom=MSDN
$SecureString = ConvertTo-SecureString "<>" -AsPlainText -Force
Enable-BitLocker -MountPoint "C:" -EncryptionMethod Aes256 -UsedSpaceOnly -Pin $SecureString -TPMandPinProtector #Can't use Pin since asks during boot. and can't enter manually


Enable-BitLocker -MountPoint C: -EncryptionMethod Aes256 -TpmProtector -Verbose #Enable-BitLocker : An external key or password protector is required to enable BitLocker on an operating system volume without a valid TPM.
<#[Window Title]   BitLocker Drive Encryption
[Main Instruction] BitLocker could not be enabled.
[Content]          The BitLocker encryption key cannot be obtained. Verify that the Trusted Platform Module (TPM) is enabled and ownership has been taken. If this computer does not have a TPM, verify that the USB drive is inserted and available.
C: was not encrypted.
[Close]
#>




#Still causes error: Device Encryption Support	Reasons for failed automatic device encryption: Hardware Security Test Interface failed and device is not Modern Standby, WinRE is not configured, TPM is not usable
#https://docs.microsoft.com/en-us/azure/virtual-machines/windows/disk-encryption-sample-scripts#without-using-a-kek
#https://docs.microsoft.com/en-us/powershell/module/az.compute/set-azvmosdisk?view=azps-6.3.0
Set-AzVMOSDisk -VM $vmConfig  -Name $Name'D' -Caching ReadWrite -Windows -CreateOption FromImage -DiskEncryptionKeyVaultId $KeyVault.ResourceId -DiskEncryptionKeyUrl $Secret.Id



#Worked to encrypt on partition on pen drive with password
Get-Partition -DiskNumber 2| Get-Volume
Enable-BitLocker -MountPoint "J:" -EncryptionMethod Aes256 -UsedSpaceOnly -PasswordProtector -Password (ConvertTo-SecureString -String '<>' -AsPlainText -Force) -Verbose
