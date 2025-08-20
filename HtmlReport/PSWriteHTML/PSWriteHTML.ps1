#region Bar chart  | Install-PSResource PSWriteHTML -Scope CurrentUser -Verbose
$data = Get-Process | Sort-Object WS -Descending -Top 10
$values = $data | ForEach-Object { [int]($_.WS / 1MB) }  # Process each element for conversion from bytes to megabytes
$names = $data.ProcessName  # Names of the processes to use as labels

New-HTML -Online -FilePath 'ProcessReport.html' { # Creating the HTML report with a bar chart
    New-HTMLChart {
        foreach ($index in 0..($names.Count - 1)) {New-ChartBarOptions -Vertical
            New-ChartBar -Name $names[$index] -Value $values[$index]
        }
    }
} -Show
#endregion

