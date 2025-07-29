#region Format vss writers in tabular format


$cVssOutput = vssadmin list writers

# Creating an empty collection.
$cVssWriters = @()

foreach ($line in $cVssOutput) {
    $cNameValue = $line.Trim() -split ': '

    if ($cNameValue[1] -ne $null) {
        if ($cNameValue[0] -eq 'Writer name') {
            # New writer. Initializing a new object.
            $oVssVriter = New-Object PSObject
        }

        # Formatting and adding properties.
        $sName = $cNameValue[0] -replace " ", ""
        $sValue = $cNameValue[1] -replace "'", ""
        $oVssVriter | Add-Member -Type NoteProperty -Name $sName -Value $sValue

        if ($cNameValue[0] -eq 'Last error') {
            # All properties in place.
            # Adding the object to the collection.
            $cVssWriters += $oVssVriter
        }
    }
}

$cVssWriters|select writername,*error*,state|ft -AutoSize
#endregion