<#
.SYNOPSIS
Finds Major System words for a number using a pronunciation dictionary.

.DESCRIPTION
Lists dictionary matches at each digit position, with the longest matching digit sequences shown first.

.PARAMETER Number
The number to search. Nondigit characters are ignored.

.PARAMETER DictionaryPath
The path to the comma-delimited pronunciation dictionary.

.PARAMETER MaxWordsPerCode
The maximum words shown for each digit code. Use 0 to show every match.

.EXAMPLE
PS> .\Memorizer.ps1 -Number 8675309124 -MaxWordsPerCode 3
Major System matches for 8675309124

Position 1: 8675309124
  867 (1 match)
    fugue
  86 (16 matches)
    aphasia, effigy, fetch ... (+13 more)

The remaining matches and digit positions are omitted from this excerpt.
#>
[CmdletBinding()]
param([Parameter(Position=0)][string]$Number='3141592653',
    [string]$DictionaryPath=(Join-Path (Split-Path $PSScriptRoot -Parent) '.WorkDir\Words.dat'),
    [ValidateRange(0,10000)][int]$MaxWordsPerCode=20)
function ConvertTo-MajorCode {
    param([Parameter(Mandatory)][string]$Pronunciation)
    $Code = [Text.StringBuilder]::new()
    for ($Index = 0; $Index -lt $Pronunciation.Length; $Index++) {
        $Current = [int]$Pronunciation[$Index]
        $Next = if ($Index + 1 -lt $Pronunciation.Length) { [int]$Pronunciation[$Index + 1] } else { -1 }
        if (($Current -eq 100 -and $Next -eq 191) -or ($Current -eq 116 -and $Next -eq 159)) {
            [void]$Code.Append('6')
            $Index++
            continue
        }
        if ($Current -lt $MajorMap.Length -and $null -ne $MajorMap[$Current]) { [void]$Code.Append($MajorMap[$Current]) }
    }
    $Code.ToString()
}
function Import-MajorDictionary {
    param([Parameter(Mandatory)][string]$Path)
    $Dictionary = @{}
    foreach ($Line in [IO.File]::ReadLines($Path, [Text.Encoding]::Latin1)) {
        if (-not $Line) { continue }
        $Parts = $Line.Split(',', 2)
        if ($Parts.Count -ne 2) { continue }
        $Code = ConvertTo-MajorCode -Pronunciation $Parts[1]
        if (-not $Code) { continue }
        if (-not $Dictionary.ContainsKey($Code)) { $Dictionary[$Code] = [Collections.Generic.List[string]]::new() }
        [void]$Dictionary[$Code].Add($Parts[0])
    }
    $Dictionary
}
$Digits = $Number -replace '\D'
if (-not $Digits) { throw 'Number must contain at least one digit.' }
if (-not (Test-Path -LiteralPath $DictionaryPath -PathType Leaf)) { throw "Pronunciation dictionary not found: $DictionaryPath" }
$MajorMap = [string[]]::new(256)
$SoundGroups = 'sz', 'td', 'n', 'm', 'r', 'l', 'j', 'kgcq', 'fv', 'pb'
for ($Digit = 0; $Digit -lt $SoundGroups.Count; $Digit++) {
    foreach ($Character in $SoundGroups[$Digit].ToCharArray()) { $MajorMap[[int]$Character] = [string]$Digit }
}
$MajorMap[51], $MajorMap[229] = '4', '4'
$MajorMap[90], $MajorMap[159], $MajorMap[191], $MajorMap[244] = '6', '6', '6', '6'
$MajorMap[233], $MajorMap[235], $MajorMap[252] = '1', '1', '2'
$DictionaryPath = (Resolve-Path -LiteralPath $DictionaryPath).Path
$Dictionary = Import-MajorDictionary -Path $DictionaryPath
"Major System matches for $Digits"
for ($Start = 0; $Start -lt $Digits.Length; $Start++) {
    "`nPosition $($Start + 1): $($Digits.Substring($Start))"
    for ($Length = $Digits.Length - $Start; $Length -ge 1; $Length--) {
        $Code = $Digits.Substring($Start, $Length)
        if (-not $Dictionary.ContainsKey($Code)) { continue }
        $Words = $Dictionary[$Code]
        $Limit = if ($MaxWordsPerCode -eq 0) { $Words.Count } else { [Math]::Min($MaxWordsPerCode, $Words.Count) }
        $Shown = $Words.GetRange(0, $Limit) -join ', '
        $More = if ($Limit -lt $Words.Count) { " ... (+$($Words.Count - $Limit) more)" } else { '' }
        $Label = if ($Words.Count -eq 1) { 'match' } else { 'matches' }
        "  $Code ($($Words.Count) $Label)"
        "    $Shown$More"
    }
}
