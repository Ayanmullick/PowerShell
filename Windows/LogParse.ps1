Get-ChildItem -Path C:\ -Filter *.log -Recurse|? LastWriteTime -gt 3/10/2023  #Get all the logs that were modified after a certain date
Get-ChildItem -Path C:\ -Filter *.log -Recurse|? LastWriteTime -gt 3/10/2023|FT DirectoryName,Name,PSProvider,LastWriteTime,Length 





Get-Content $env:windir\windowsupdate.log |Select-String -AllMatches 'successfully installed.*?update:.*'|Select-Object -ExpandProperty Matches|Select-Object -ExpandProperty Value
Get-Content -Path \\BP1XEUIS469\c$\winnt\cluster\cluster.log|Select-String ERR,WARN -CaseSensitive
Get-Content $env:windir\windowsupdate.log |Select-String 2014-03-27.*210.*uploa

#region 
Get-WinEvent -Path C:\Windows\Logs\WindowsUpdate\WindowsUpdate.20230312.124058.368.1.etl -Oldest| ? LevelDisplayName -NE 'Information'|FT -Property  TimeCreated,UserId,LevelDisplayName, Message,ProcessId  #Works fine

#looping thru all the update logs for errors for a specific time. Works only with one time filter; not both
Get-ChildItem -Path C:\Windows\Logs\WindowsUpdate |? LastWriteTime -gt 3/10/2023|
     %{Get-WinEvent -Path $PSItem.FullName -Oldest|   #use the Oldest parameter in the command. to view etl or evt files
             ? {$_.LevelDisplayName -NE 'Information' -and $_.timecreated -gt "3/10/2023 18:16:00"}  }


Get-ChildItem -Path C:\Windows\Logs\WindowsUpdate |? LastWriteTime -gt 3/10/2023|
    %{Get-WinEvent -Path $PSItem.FullName -Oldest|
             ? {$_.LevelDisplayName -NE 'Information' -and $_.timecreated -lt "3/10/2023 20:14:00"}  }|
                    FT -Property  TimeCreated,UserId,LevelDisplayName, Message,ProcessId
#endregion


#region :Reading Windows update log.   Didn't work. Some pipeline error
$Log = Get-WindowsUpdateLog -LogPath C:\WindowsUpdate.log
$Start = '2023/03/10 22:34:22'
$End = '2023/03/10 22:34:27'
$Log | Get-Content | Select-String -Pattern $Start,$End -Context 0,1000000
#endregion

#region Works to retrieve raw data and convert timestamp
get-WindowsUpdateLog
tracerpt.exe "C:\Windows\Logs\WindowsUpdate\WindowsUpdate.20230312.124058.368.1.etl" -of xml  # Convert ETL file to XML file

# Read XML file with PowerShell
[xml]$xml = Get-Content "C:\temp\dumpfile.xml"

$xml.Events.Event
($xml.Events.Event)[0].EventData.Data

$xml.MyEvent.EventData.Data | Format-Table -AutoSize

[DateTime]::FromFileTimeUtc(133231164688869817)
#endregion


#region : Didn't work: use Microsoft.Diagnostics.Tracing.TraceEvent library to parse ETL files directly with PowerShell without converting them to XML3

# Install Microsoft.Diagnostics.Tracing.TraceEvent library
Install-Package -Name Microsoft.Diagnostics.Tracing.TraceEvent

# Load Microsoft.Diagnostics.Tracing.TraceEvent library
Add-Type -Path "$env:ProgramFiles\PackageManagement\NuGet\Packages\Microsoft.Diagnostics.Tracing.TraceEvent.3.0.8\lib\net462\Microsoft.Diagnostics.Tracing.TraceEvent.dll"  #Worked fine

# Parse ETL file with PowerShell
$traceLog = [TraceLog]::OpenOrConvert("C:\Windows\Logs\WindowsUpdate\WindowsUpdate.20230312.124058.368.1.etl")  #Error:  InvalidOperation: Unable to find type [TraceLog]
$traceLog.Events | Format-Table -AutoSize   
#endregion


#region : Query the list of last modified logs and query entries between start and end timestamps.

$FilteredFiles = Get-ChildItem -Path C:\ -Filter *.log -Recurse|? LastWriteTime -gt 3/10/2023

$StartTime, $EndTime = "3/10/2023 18:16:00", "3/10/2023 20:14:00"  # Define your start and end timestamps

# Loop through each file in $FilteredFiles
foreach ($File in $FilteredFiles) {$FileContent = Get-Content -Path $File.FullName  # Get the content of the file

    # Filter the content by the timestamp
    $FilteredContent = $FileContent | Where-Object {# Try to convert each line to a datetime object using a custom format|  Parse($_.Substring(0,19), $null)
        try {$LineTime = [datetime]::Parse($_.Substring(0,19))}  catch {$LineTime = $null}  # Catch any exceptions and set the line time to null
        $LineTime -ge $StartTime -and $LineTime -le $EndTime    # Check if the line time is within your desired range  #-or $LineTime -eq $null
                                                   }

    # Display or save the filtered content
    Write-Output "Log entries for file $($File.Name):"
    Write-Output $FilteredContent
                                    }

#endregion

#Gets the encoding and mode of the log file. However, it didn't help identifying which files won't open in Notepad other than that 
# 'C:\Windows\Logs\MeasuredBoot\0000000034-0000000020.log' and 'C:\Windows\SoftwareDistribution\DataStore\Logs\edb.log' are 'US-ASCII' encoded

Install-Module PSTemplatizer -Scope AllUsers
Get-ChildItem -Path C:\ -Filter *.log -Recurse|? LastWriteTime -gt 3/10/2023|
    select FullName, @{n='Encoding'; e= {(Get-FileEncoding -Path $_.FullName).EncodingName}}, @{n='Mode'; e={(Get-Item -Path $_.FullName).Mode}}|
            sort Encoding| FT -Wrap


