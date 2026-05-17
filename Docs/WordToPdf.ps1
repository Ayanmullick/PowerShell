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