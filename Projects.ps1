#region LeetCode
(1..15)|%{$a = ""; if($_%3 -eq 0){$a +='Fizz'};if($_%5 -eq 0){$a+='Buzz'};if($a -eq ""){$a =$_}; $a} #412| FizBuzz|https://leetcode.com/problems/fizz-buzz/

1..15|%{@("Fizz")[$_%3]+{Buzz}[$_%5]??$_} #v2: https://youtu.be/j3iuoxmZ6sY?list=PLfeA8kIs7Cof3Ev-KGonHLdFh8joxDFdW&t=3450

#endregion


#region Generate-TextImage | Could be used to generate images for the Desktop Wallpaper with needed information
<#
.SYNOPSIS
   Generates a JPG image with specified text. Works.
.DESCRIPTION
   Creates a JPG image with the given text centered on a black background.
.EXAMPLE
   New-TextImage -text "Ayan Mullick" -outputPath "C:\temp\output.jpg"
#>
function New-TextImage { [CmdletBinding()]
    Param ([Parameter(Mandatory=$true, Position=0)] [string]$text,[Parameter(Mandatory=$true, Position=1)] [string]$outputPath )

    Add-Type -AssemblyName System.Drawing
    $bmp = New-Object Drawing.Bitmap 800, 600
    $gfx = [Drawing.Graphics]::FromImage($bmp)
    $gfx.Clear([Drawing.Color]::Black)
    $font = New-Object Drawing.Font "Arial", 48
    $size = $gfx.MeasureString($text, $font)
    $x = (800 - $size.Width) / 2
    $y = (600 - $size.Height) / 2
    $gfx.DrawString($text, $font, [Drawing.Brushes]::White, $x, $y)
    $bmp.Save($outputPath, [Drawing.Imaging.ImageFormat]::Jpeg)
    $gfx.Dispose()
    $bmp.Dispose()
}

#endregion