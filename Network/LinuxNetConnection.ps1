#region  Test-NetConnection function for Linux since NetTCPIP module can't be installed
function Test-NetConnection {param ([string]$ComputerName,[int]$Port = 80)

    $result = & nc -zv $ComputerName $Port
    if ($LASTEXITCODE -eq 0) {"Connection to $ComputerName on port $Port succeeded."}
    else                     {"Connection to $ComputerName on port $Port failed."}
}


#endregion




