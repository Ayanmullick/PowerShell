function Get-CurrentTime {
    [CmdletBinding()]
    param ()

    process {
        $currentTime = Get-Date
        Write-Output $currentTime
    }
}


<# Installation steps. | The manifest isn't included. 
GitHub doesn't natively support downloading folders. One needs to download the files individually or use sparse checkout to clone one folder.

$Module = 'TestModule'
$DestPath = "$([Environment]::GetFolderPath('MyDocuments'))\PowerShell\Modules\$Module"
New-Item -ItemType Directory -Path $DestPath -Force -ErrorAction SilentlyContinue
(New-Object Net.WebClient).DownloadFile("https://github.com/Ayanmullick/PowerShell/raw/refs/heads/master/$Module/$Module.psm1", "$DestPath\$Module.psm1")

#>