Install-Module PSScriptAnalyzer -Verbose   #https://searchitoperations.techtarget.com/tutorial/Try-PSScriptAnalyzer-to-check-PowerShell-code-best-practices


Get-ScriptAnalyzerRule | Sort-Object RuleName | Select-Object CommonName
Get-ScriptAnalyzerRule | ?{$_.CommonName -eq 'Align assignment statement'}|ft -AutoSize
Invoke-ScriptAnalyzer .\PSSA.ps1



Get-ScriptAnalyzerRule -Name *alias*
Get-ScriptAnalyzerRule -Severity Warning