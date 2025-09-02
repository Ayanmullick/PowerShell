# Matrix rain in the console (PowerShell 5.1+ / 7+)
# Faster and a bit shorter, while keeping readability.

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::UTF8
$ErrorActionPreference = 'Stop'

# Tunables
$density      = 0.12      # fraction of columns that are active
$minLen       = 8
$maxLenScale  = 0.6       # max tail length as a fraction of rows
$frameDelayMs = 33        # ~30 FPS
$brightTail   = 2         # first N tail cells are bright green

# ANSI
$Esc         = [char]27
$ClrReset    = "$Esc[0m"
$GreenDim    = "$Esc[32m"
$GreenBright = "$Esc[92m"
$WhiteBright = "$Esc[97m"
$HideCursor  = "$Esc[?25l"
$ShowCursor  = "$Esc[?25h"
$Clear       = "$Esc[2J$Esc[H]"

# Glyph set (fast build, no pipelines)
$glyphsList = New-Object System.Collections.Generic.List[char]
for ($c=0x30A1; $c -le 0x30FA; $c++) { $glyphsList.Add([char]$c) } # Katakana
for ($c=[byte][char]'0'; $c -le [byte][char]'9'; $c++) { $glyphsList.Add([char]$c) }
for ($c=[byte][char]'A'; $c -le [byte][char]'Z'; $c++) { $glyphsList.Add([char]$c) }
$GLYPHS = $glyphsList.ToArray()
$GLEN   = $GLYPHS.Length
$RNG    = [System.Random]::new()

# Helpers
function Get-ScreenSize {
  [PSCustomObject]@{
    Columns = [Math]::Max(1, [Console]::BufferWidth)
    Rows    = [Math]::Max(1, [Console]::BufferHeight)
  }
}

# State init
$size   = Get-ScreenSize
$cols   = $size.Columns
$rows   = $size.Rows
$maxLen = [Math]::Max([int]($rows * $maxLenScale), $minLen + 5)

# Pick active columns
$activeCount = [int]([Math]::Round($cols * $density))
$activeCols  = if ($activeCount -gt 0) { 0..($cols-1) | Get-Random -Count $activeCount | Sort-Object } else { @() }
$N = $activeCols.Count

# Drops as parallel arrays (faster than hashtables)
$dropX     = [int[]]::new($N)
$dropY     = [int[]]::new($N)
$dropLen   = [int[]]::new($N)
$dropSpeed = [int[]]::new($N)

for ($i=0; $i -lt $N; $i++) {
  $x = $activeCols[$i]
  $dropX[$i] = $x
  $dropLen[$i] = $RNG.Next($minLen, $maxLen)
  $dropSpeed[$i] = $RNG.Next(1, 3) # 1..2
  $dropY[$i] = - $RNG.Next(0, [Math]::Max(1, $rows))
}

# Draw helpers (inline bounds checks)
function DrawChar([int]$x, [int]$y, [string]$s) {
  $bw = [Console]::BufferWidth; $bh = [Console]::BufferHeight
  if ($x -lt 0 -or $y -lt 0 -or $x -ge $bw -or $y -ge $bh) { return }
  [Console]::SetCursorPosition($x, $y)
  [Console]::Write($s)
}
function EraseAt([int]$x, [int]$y) {
  $bw = [Console]::BufferWidth; $bh = [Console]::BufferHeight
  if ($x -lt 0 -or $y -lt 0 -or $x -ge $bw -or $y -ge $bh) { return }
  [Console]::SetCursorPosition($x, $y)
  [Console]::Write(" ")
}

# Init screen
[Console]::Write($HideCursor)
[Console]::Write($Clear)

$stopping = $false
$null = Register-EngineEvent PowerShell.Exiting -Action { $global:stopping = $true } | Out-Null

try {
  while (-not $stopping) {
    $t0 = Get-Date

    # Handle resize
    $new = Get-ScreenSize
    if ($new.Columns -ne $cols -or $new.Rows -ne $rows) {
      $cols = $new.Columns; $rows = $new.Rows
      $maxLen = [Math]::Max([int]($rows * $maxLenScale), $minLen + 5)

      $activeCount = [int]([Math]::Round($cols * $density))
      $activeCols  = if ($activeCount -gt 0) { 0..($cols-1) | Get-Random -Count $activeCount | Sort-Object } else { @() }
      $N = $activeCols.Count

      $dropX     = [int[]]::new($N)
      $dropY     = [int[]]::new($N)
      $dropLen   = [int[]]::new($N)
      $dropSpeed = [int[]]::new($N)
      for ($i=0; $i -lt $N; $i++) {
        $x = $activeCols[$i]
        $dropX[$i]   = $x
        $dropLen[$i] = $RNG.Next($minLen, $maxLen)
        $dropSpeed[$i] = $RNG.Next(1, 3)
        $dropY[$i]   = - $RNG.Next(0, [Math]::Max(1, $rows))
      }

      [Console]::Write($Clear)
    }

    for ($i=0; $i -lt $N; $i++) {
      $x = $dropX[$i]
      $dropY[$i] += $dropSpeed[$i]
      $headY = $dropY[$i]
      $len   = $dropLen[$i]

      # Reset when fully off-screen
      if ($headY -gt ($rows + $len + 1)) {
        $dropY[$i]   = - $RNG.Next(0, [Math]::Max(1, $rows))
        $dropLen[$i] = $RNG.Next($minLen, $maxLen)
        $dropSpeed[$i] = $RNG.Next(1, 3)
        continue
      }

      # Head
      if ($headY -ge 0 -and $headY -lt $rows) {
        $g = $GLYPHS[$RNG.Next($GLEN)]
        DrawChar $x $headY ($WhiteBright + $g + $ClrReset)
      }

      # Tail (bright first, then dim) — derive index from positions to avoid dual init/increment
      $tStop = $headY - $len
      for ($ty = $headY - 1; $ty -ge 0 -and $ty -gt $tStop; $ty--) {
        $j = $headY - $ty
        $g = $GLYPHS[$RNG.Next($GLEN)]
        $c = if ($j -le $brightTail) { $GreenBright } else { $GreenDim }
        DrawChar $x $ty ($c + $g + $ClrReset)
      }

      # Erase just beyond tail end
      $eraseY = $headY - $len - 1
      if ($eraseY -ge 0 -and $eraseY -lt $rows) { EraseAt $x $eraseY }
    }

    # Frame pacing
    $elapsed = (Get-Date) - $t0
    $sleep = $frameDelayMs - [int]$elapsed.TotalMilliseconds
    if ($sleep -gt 0) { Start-Sleep -Milliseconds $sleep }
  }
}
finally {
  [Console]::Write($ShowCursor)
  [Console]::WriteLine()
}