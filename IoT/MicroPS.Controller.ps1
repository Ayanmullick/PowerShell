$script:MicroPSConnection = $null

function Disconnect-MicroPS {
    [CmdletBinding()]
    param()

    if (-not $script:MicroPSConnection) { return }
    if ($script:MicroPSConnection.Mode -eq 'Simulator') {
        $script:MicroPSConnection.Stream.Dispose()
        $script:MicroPSConnection.Client.Dispose()
    }
    else { $script:MicroPSConnection.SerialPort.Dispose() }
    $script:MicroPSConnection = $null
    Write-Output 'MicroPS disconnected.'
}

function Write-MicroPSTelnetData {
    param([Parameter(Mandatory)] [byte[]]$Bytes)
    $script:MicroPSConnection.Stream.Write($Bytes, 0, $Bytes.Length)
}

function Send-MicroPSTelnetReply {
    param([Parameter(Mandatory)] [int]$Command, [Parameter(Mandatory)] [int]$Option)
    $allowed = $Option -in 0, 3, 44
    $response = switch ($Command) {
        251 { $allowed ? 253 : 254 }
        252 { 254 }
        253 { $allowed ? 251 : 252 }
        254 { 252 }
    }
    if ($null -ne $response) { Write-MicroPSTelnetData -Bytes ([byte[]](255, $response, $Option)) }
}

function Read-MicroPSLine {
    param([Parameter(Mandatory)] [int]$TimeoutMilliseconds)
    $connection = $script:MicroPSConnection
    if ($connection.Mode -eq 'Physical') {
        $connection.SerialPort.ReadTimeout = [Math]::Max(1, $TimeoutMilliseconds)
        try { return $connection.SerialPort.ReadLine().Trim() }
        catch [TimeoutException] { return $null }
    }

    $timer = [Diagnostics.Stopwatch]::StartNew()
    while ($timer.ElapsedMilliseconds -lt $TimeoutMilliseconds) {
        while ($connection.Stream.DataAvailable) {
            $value = $connection.Stream.ReadByte()
            if ($value -lt 0) { throw 'The Wokwi RFC2217 connection was closed.' }
            switch ($connection.TelnetState) {
                0 {
                    if ($value -eq 255) { $connection.TelnetState = 1 }
                    elseif ($value -eq 10) {
                        $line = $connection.TextBuffer.Trim()
                        $connection.TextBuffer = ''
                        return $line
                    }
                    elseif ($value -ne 13) { $connection.TextBuffer += [char]$value }
                }
                1 {
                    if ($value -eq 255) { $connection.TextBuffer += [char]255; $connection.TelnetState = 0 }
                    elseif ($value -eq 250) { $connection.TelnetState = 3 }
                    elseif ($value -in 251, 252, 253, 254) {
                        $connection.TelnetCommand = $value
                        $connection.TelnetState = 2
                    }
                    else { $connection.TelnetState = 0 }
                }
                2 {
                    Send-MicroPSTelnetReply -Command $connection.TelnetCommand -Option $value
                    $connection.TelnetState = 0
                }
                3 { if ($value -eq 255) { $connection.TelnetState = 4 } }
                4 { $connection.TelnetState = $value -eq 240 ? 0 : 3 }
            }
        }
        Start-Sleep -Milliseconds 20
    }
    return $null
}

function Connect-MicroPS {
    [CmdletBinding(DefaultParameterSetName = 'Device')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Simulator')] [switch]$UseSimulator,
        [Parameter(ParameterSetName = 'Device')] [switch]$UseDevice,
        [Parameter(Mandatory, ParameterSetName = 'Device')] [Alias('ComPort')] [string]$ApplicationPort,
        [Parameter(ParameterSetName = 'Simulator')] [string]$SimulatorHost = '127.0.0.1',
        [Parameter(ParameterSetName = 'Simulator')] [ValidateRange(1, 65535)] [int]$SimulatorPort = 4000,
        [ValidateRange(1, 4000000)] [int]$BaudRate = 115200, [ValidateRange(100, 30000)] [int]$TimeoutMilliseconds = 3000
    )

    if ($script:MicroPSConnection) { Disconnect-MicroPS | Out-Null }
    if ($UseDevice -or -not $UseSimulator) {
        $serial = [IO.Ports.SerialPort]::new($ApplicationPort, $BaudRate, [IO.Ports.Parity]::None, 8, [IO.Ports.StopBits]::One)
        $serial.Handshake, $serial.NewLine = [IO.Ports.Handshake]::None, "`n"
        $serial.ReadTimeout = $serial.WriteTimeout = $TimeoutMilliseconds
        try { $serial.Open() }
        catch { $serial.Dispose(); throw }
        $script:MicroPSConnection = [pscustomobject]@{Mode = 'Physical'; SerialPort = $serial }
        Write-Output "MicroPS connected to $ApplicationPort at $BaudRate baud."
        return
    }

    $client = [Net.Sockets.TcpClient]::new()
    $pending = $client.BeginConnect($SimulatorHost, $SimulatorPort, $null, $null)
    try {
        if (-not $pending.AsyncWaitHandle.WaitOne($TimeoutMilliseconds)) {
            throw "Timed out connecting to Wokwi at ${SimulatorHost}:$SimulatorPort."
        }
        $client.EndConnect($pending)
    }
    catch { $client.Dispose(); throw }
    finally { $pending.AsyncWaitHandle.Dispose() }

    $client.NoDelay = $true
    $stream = $client.GetStream()
    $stream.ReadTimeout = $stream.WriteTimeout = $TimeoutMilliseconds
    $script:MicroPSConnection = [pscustomobject]@{
        Mode = 'Simulator'; Client = $client; Stream = $stream
        TextBuffer = ''; TelnetState = 0; TelnetCommand = 0
    }

    Write-MicroPSTelnetData -Bytes ([byte[]](255, 251, 0, 255, 253, 0, 255, 251, 3, 255, 253, 3, 255, 251, 44, 255, 253, 44))
    $baudBytes = [BitConverter]::GetBytes([uint32]$BaudRate)
    if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($baudBytes) }
    Write-MicroPSTelnetData -Bytes ([byte[]](([byte[]](255, 250, 44, 1)) + $baudBytes + ([byte[]](255, 240))))
    $portSettings = [byte[]](255, 250, 44, 2, 8, 255, 240, 255, 250, 44, 3, 1, 255, 240, 255, 250, 44, 4, 1, 255, 240)
    Write-MicroPSTelnetData -Bytes $portSettings
    Write-Output "MicroPS connected to Wokwi at ${SimulatorHost}:$SimulatorPort."
}

function Set-MicroPSLed {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [ValidateSet('On', 'Off', 'Blink')] [string]$State,
        [ValidateRange(100, 30000)] [int]$TimeoutMilliseconds = 3000
    )

    $command = $State.ToUpperInvariant()
    if (-not $PSCmdlet.ShouldProcess('MicroPS LED', "Set state to $command")) { return }
    if (-not $script:MicroPSConnection) { throw 'MicroPS is not connected. Run Connect-MicroPS first.' }
    if ($script:MicroPSConnection.Mode -eq 'Simulator') {
        Write-MicroPSTelnetData -Bytes ([Text.Encoding]::ASCII.GetBytes("$command`n"))
    }
    else { $script:MicroPSConnection.SerialPort.WriteLine($command) }

    $timer = [Diagnostics.Stopwatch]::StartNew()
    while ($timer.ElapsedMilliseconds -lt $TimeoutMilliseconds) {
        $remaining = $TimeoutMilliseconds - [int]$timer.ElapsedMilliseconds
        $line = Read-MicroPSLine -TimeoutMilliseconds ([Math]::Max(1, $remaining))
        if ($line -match '^(OK|ERR)\b') { return $line }
        if ($line) { Write-Verbose "Device: $line" }
    }
    throw "MicroPS did not acknowledge '$command' within $TimeoutMilliseconds ms."
}

function Turn-On { [CmdletBinding()] param() Set-MicroPSLed -State On }
function Turn-Off { [CmdletBinding()] param() Set-MicroPSLed -State Off }
function Continue-Blink { [CmdletBinding()] param() Set-MicroPSLed -State Blink }
