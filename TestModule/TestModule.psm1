function Get-CurrentTime {
    [CmdletBinding()]
    param ()

    process {
        $currentTime = Get-Date
        Write-Output $currentTime
    }
}