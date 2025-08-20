Ctrl+K+U   #makes comments in markdown file in Visual studio code

psedit filename  #running on the terminal  opens up the file in VSC



#https://ephos.github.io/posts/2018-8-1-PowerShell-Markdown
ConvertFrom-Markdown -Path '.\temp\gps.md' -AsVT100EncodedString | Show-Markdown


ConvertFrom-Markdown -Path '.\temp\gps.md'  | Show-Markdown -UseBrowser

Invoke-WebRequest -Uri https://raw.githubusercontent.com/Azure/azure-powershell/master/src/Websites/Websites/help/Enter-AzWebAppContainerPSSession.md | Select-Object -ExpandProperty Content | ConvertFrom-Markdown | Show-Markdown -UseBrowser

(Invoke-WebRequest -Uri https://raw.githubusercontent.com/Azure/azure-powershell/master/src/Websites/Websites/help/Enter-AzWebAppContainerPSSession.md).Content | ConvertFrom-Markdown | Show-Markdown -UseBrowser

#Each has an associated ANSI/VT100 escape code.
#Set-MarkdownOption changes don’t persist
Get-MarkdownOption
Set-MarkdownOption -Header2Color '[4;32m'


#Region PSMarkdown
Install-Module PSMarkdown -Scope CurrentUser -AllowClobber -Verbose  #Ansillary modules in current user scope. Clobbered  ConvertFrom-Markdown from Microsoft.PowerShell.Utility
Import-Module PSMarkdown -Prefix PS

$Rules= Get-Content -Path 'C:\Users\ayanm\OneDrive - Mullick\PowerShell\ATT\WinAdminCenterRules.md'|ConvertFrom-PSMarkdown |select -ExcludeProperty H1  #The conversion adds an extra H1 property
$Rules|ft  
#endregion


Install-Module PSScriptTools -Scope CurrentUser  #Az.OperationalInsights had a dependency on it
[PSCustomObject]$PSVersionTable|ConvertTo-Markdown -AsTable




Install-Module FormatMarkdownTable -Scope AllUsers
[PSCustomObject]$PSVersionTable|Format-MarkdownTableListStyle -ShowMarkdown  #As list. Automatically copies to the clipboard

$PSVersionTable|Format-MarkdownTableListStyle  #As Table


Get-ComputerInfo -Property @(
        'OsName',
        'OsOperatingSystemSKU',
        'OSArchitecture',
        'WindowsVersion',
        'WindowsBuildLabEx',
        'OsLanguage',
        'OsMuiLanguages')|Format-MarkdownTableListStyle -ShowMarkdown




#region Create PDF report PSWriteHTML| #Didn't work ConvertTo-Pdf not there any more
#Try ExportToPDF module

$htmlContent = @"
<html>
<head>
<title>My PDF</title>
</head>
<body>
<h1>Hello, World!</h1>
<p>This is my PDF content.</p>
</body>
</html>
"@

$pdfPath = "C:\path\to\output.pdf"

$htmlContent | ConvertTo-Pdf -Path $pdfPath
#endregion




#region basic markdown report generation

Invoke-Expression (new-object System.Net.WebClient).DownloadString('https://raw.github.com/ishu3101/PSMarkdown/master/Install.ps1')

(gps)[0..5]|select ProcessName,Company,Description,Path,Id,WorkingSet,HandleCount,CPU|ConvertTo-Markdown|Out-File gps.md

Get-Content .\gps.md|ConvertFrom-Markdown|ft -Property ProcessName,Company,Description,Path,Id,WorkingSet,HandleCount,CPU



#region V2:MS built-in
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 20 ProcessName,Id,CPU,@{n='WS(MB)';e={[math]::Round($_.WorkingSet64/1MB,2)}} |
     Format-MarkdownTableTableStyle -ShowMarkdown:$false *> $null   #Formats the table in markdown and copies to clipboard
#Removes the command that the Microsoft puts in the beginning of the markdown content and leaves just the table.
     (Get-Clipboard) -replace '(?s)^\*\*.*?\*\*\s*','' | Set-Content 'process.md' -Encoding UTF8
Show-Markdown -Path 'process.md' -UseBrowser

#endregion



#With timestamp in filename
$stamp = '{0:MMdd.HHmm}{1}' -f ($ct=[TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTimeOffset]::UtcNow,'America/Chicago')), ( ($ct.Offset.TotalHours -eq -5) ? 'CDT' : 'CST' )
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 20 ProcessName,Id,CPU,@{n='WS(MB)';e={[math]::Round($_.WorkingSet64/1MB,2)}} |
     Format-MarkdownTableTableStyle -ShowMarkdown:$false *> $null

(Get-Clipboard) -replace '(?s)^\*\*.*?\*\*\s*','' | Set-Content "Process$stamp.md" -Encoding UTF8
Show-Markdown -Path "Process$stamp.md" -UseBrowser



#endregion



#region Convert a markdown table from a file to a PowerShell custom object

function Convert-MdTableToPSObject {param([Parameter(Mandatory=$true)][string]$MarkdownFilePath)
    $lines = (Get-Content -Path $MarkdownFilePath -Raw) -replace "`r`n", "`n" -split "`n"           # Read the markdown file content and normalize line endings and split lines
    $headers = (($lines[0] -split '\|').Where({ $_.Trim() -ne '' })).Trim()                         # Extract and clean headers
    ($lines[2..$lines.Length]).Where({ $_ -ne '' }) | ForEach-Object {
        $properties = [ordered]@{}                                                                  # Initialize ordered hashtable to preserve property order
        $cells = (($_ -split '\|').Where({ $_.Trim() -ne '' })).Trim()                              # Split line into cells and clean them
        for ($i = 0; $i -lt $headers.Count; $i++) { $properties[$headers[$i]] = $cells[$i] }        # Map each cell to its corresponding header
        [PSCustomObject]$properties                                                                 # Output a custom object with ordered properties
    }
}

$rules = Convert-MdTableToPSObject -MarkdownFilePath .\NsgRules.md
$rules | Format-Table



#region For herestring

$markdownTable = @"
| Name       | Direction | SourceAddressPrefix | DestAddressPrefix  | DestPortRange | Description                                               |
|------------|-----------|---------------------|--------------------|---------------|-----------------------------------------------------------|
| WACService | Outbound  | VirtualNetwork      | WindowsAdminCenter | 443           | Open outbound port rule for WAC service                   |
| WAC        | Inbound   | *                   | *                  | 6516          | Open inbound port rule on VM to be able to connect to WAC |
"@

$lines = $MarkdownTable -replace "`r`n", "`n" -split "`n" 


$rules = Convert-MdTableToPSObject  -MarkdownTable $markdownTable  #Execution
$rules | Format-Table

#endregion

#endregion