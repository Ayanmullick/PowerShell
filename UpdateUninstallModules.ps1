#Works in parallel. However Update and uninstall verbosity aren't in sequence. I want it to wait till Azmodule update completes and uninstall child modules in one go.
#Test on Terminal.
#Remove Scope and parallel while running on PS5.1.
#Ran sucessfully in updating. However, didn't uninstall. Had to run again. Add '-Wait' parameter so it waits till update finishes to uninstall
$WarningPreference='silentlyContinue'
Get-InstalledModule | ForEach-Object -Parallel {$Name= $PSItem.Name; $Vpresent=$PSItem.Version; $Vavailable=$(Find-Module $Name).Version  #Get Variables so parallel works fine
      if($Vavailable -gt $Vpresent) {Write-Host "Updating $Name at $($PSItem.InstalledLocation) from $Vpresent to $Vavailable" -ForegroundColor Magenta; Update-Module -Name $Name -Scope AllUsers -Force}   
            else {Write-Host "$Name's version $Vpresent is up-to-date." -ForegroundColor Green}                                           #Update outdated module

      Get-InstalledModule $Name -AllVersions|Where-Object {$_.Version -lt $Vpresent}|ForEach-Object {Write-Host "- Uninstalling $Name version $($PSItem.Version)..." -ForegroundColor Magenta; $PSItem | 
            Uninstall-Module -Force -Verbose}                                                                                             #Uninstall older versions
                                          }