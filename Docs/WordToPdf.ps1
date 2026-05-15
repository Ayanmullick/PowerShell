# This script converts all Word documents in a specified directory to PDF format.
$documents_path = 'C:\Temp'

$word_app = New-Object -ComObject Word.Application

# This filter will find .doc as well as .docx documents
Get-ChildItem -Path $documents_path -Filter *.doc? | ForEach-Object {

    $document = $word_app.Documents.Open($_.FullName)
    $pdf_filename = "$($_.DirectoryName)\$($_.BaseName).pdf"
    $document.SaveAs([ref] $pdf_filename, [ref] 17)
    $document.Close()
}

$word_app.Quit()

#region :v2
$w=New-Object -ComObject Word.Application
Get-ChildItem C:\Temp -Filter *.doc? | ForEach-Object{
    $d=$w.Documents.Open($_.FullName)
    $d.SaveAs([ref]("$($_.DirectoryName)\$($_.BaseName).pdf"),[ref]17)
    $d.Close()
}
$w.Quit()
#endregion





#region  Adobe to edit PDF
Install-WinGetPackage -Id Adobe.Acrobat.Pro -Verbose

<# Warning if you have Adobe reader installed
Adobe Acrobat
Are you sure you want to uninstall? Keep Acrobat Reader to:
. View, print, comment, and share with ease
. Fill and sign forms anytime
. Access PDFs on the go with 2GB free cloud storage
The app is free to use. No billing or subscription required.

Keep using Acrobat for free   |   Continue
#>
#endregion