
#Add PowerShell 7 modules' path to ISE for cmdlet discovery
$env:PSModulePath -split ';'
#This adds to the module path successfully. However, the ISE Show-command add-on still can't see the PS7 modules until the module is imported in the current session
$CurrentValue = [Environment]::GetEnvironmentVariable("PSModulePath", "Machine")
#[Environment]::SetEnvironmentVariable("PSModulePath", $CurrentValue + [System.IO.Path]::PathSeparator + "C:\Users\ayan\Documents\PowerShell\Modules", "Machine")
[Environment]::SetEnvironmentVariable("PSModulePath", $CurrentValue + [System.IO.Path]::PathSeparator + "C:\Program Files\PowerShell\Modules", "Machine")  #And restart ISE.  Worked

#Ended up installing powershellget and psreadline thru the ISA using force parameter to get the latest version so I could install other modules on the Terminal
#However, removing path with replace method didn't work. I had to manually move the Windows powershell module path down
$env:PSModulePath = $env:PSModulePath -replace "$escapedPath;", ""



#region Use PowerShell 7 in ISE using a portable PS7. 'Pwsh' was opening the preview version. https://subscription.packtpub.com/book/networking_and_servers/9781789137231/1/ch01lvl1sec12/installing-powershell
$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Clear()
$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("Switch to PowerShell 7", { 
        function New-OutOfProcRunspace {
            param($ProcessId)

            $ci = New-Object -TypeName System.Management.Automation.Runspaces.NamedPipeConnectionInfo -ArgumentList @($ProcessId)
            $tt = [System.Management.Automation.Runspaces.TypeTable]::LoadDefaultTypeFiles()

            $Runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($ci, $Host, $tt)

            $Runspace.Open()
            $Runspace
        }

        $PowerShell = Start-Process pwsh.exe -ArgumentList @("-NoExit") -PassThru -WindowStyle Hidden
        $Runspace = New-OutOfProcRunspace -ProcessId $PowerShell.Id
        $Host.PushRunspace($Runspace)
}, "ALT+F5") | Out-Null

$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("Switch to Windows PowerShell", { 
    $Host.PopRunspace()

    $Child = Get-CimInstance -ClassName win32_process | where {$_.ParentProcessId -eq $Pid}
    $Child | ForEach-Object { Stop-Process -Id $_.ProcessId }

}, "ALT+F6") | Out-Null
#endregion




(Resolve-Path "$env:LOCALAPPDATA\Microsoft_Corporation\powershell_ise*").Path  #PowerShell ISE Autosave path | Recovered file location
