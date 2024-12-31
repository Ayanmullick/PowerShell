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

                                          
#region v24 for Az modules
# Get all Az modules and their submodules
$azModules = Get-Module -ListAvailable Az.*,Microsoft.Graph*

# Group modules by name to handle all versions of each submodule
$groupedModules = $azModules | Group-Object -Property Name

foreach ($moduleGroup in $groupedModules) {
    $moduleName = $moduleGroup.Name
    $moduleVersions = $moduleGroup.Group | Select-Object -Property Name, Version, ModuleBase -Unique

    if ($moduleVersions.Count -gt 1) {
        # Sort versions and exclude the latest one
        $versionsToRemove = $moduleVersions | Sort-Object Version | Select-Object -SkipLast 1

        foreach ($version in $versionsToRemove) {
            Write-Host "Removing older version: $($version.Name) : $($version.Version) → $($version.ModuleBase)" -ForegroundColor Yellow
            #Write-Host "Module Path: $($version.ModuleBase)" -ForegroundColor Yellow

            # Remove the folder of the older version
            try {
                Remove-Item -Recurse -Force -Path $version.ModuleBase
                Write-Host "Successfully removed $($version.Name) version $($version.Version)" -ForegroundColor Green
            } catch {
                Write-Host "Failed to remove $($version.Name) version $($version.Version)" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
        }
    } else {
        Write-Host "Only one version of $moduleName is installed. No action needed." -ForegroundColor Cyan
    }
}

#endRegion