# AES File Decryption Script — Uses aes.key file for Key/IV

# Ensure Admin Privileges
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Please run this script as Administrator."
    exit
}

Write-Host "Running as Administrator.`n" -ForegroundColor Green

# AES Setup
$AES = New-Object System.Security.Cryptography.AesManaged
$AES.KeySize = 256
$AES.BlockSize = 128
$AES.Mode = [System.Security.Cryptography.CipherMode]::CBC
$AES.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

# Key file setup
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$KeyFile = Join-Path $ScriptDir "aes.key"

if (-Not (Test-Path $KeyFile)) {
    Write-Error "Missing aes.key file. Cannot proceed with decryption."
    exit
}

# Load AES Key and IV
$KeyLines = Get-Content $KeyFile
if ($KeyLines.Count -lt 2) {
    Write-Error "aes.key file is invalid or corrupted."
    exit
}
$AES.Key = [Convert]::FromBase64String($KeyLines[0])
$AES.IV  = [Convert]::FromBase64String($KeyLines[1])
Write-Host "Loaded AES key and IV from $KeyFile" -ForegroundColor Yellow

# Decryption Function
function Decrypt-File {
    param([string]$EncPath)

    try {
        $EncryptedBytes = [System.IO.File]::ReadAllBytes($EncPath)
        $Decryptor = $AES.CreateDecryptor()
        $Decrypted = $Decryptor.TransformFinalBlock($EncryptedBytes, 0, $EncryptedBytes.Length)

        $OriginalPath = $EncPath -replace "\.enc$",""
        [System.IO.File]::WriteAllBytes($OriginalPath, $Decrypted)
        Remove-Item $EncPath -Force

        Write-Host "Decrypted: $EncPath" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to decrypt ${EncPath}: $_"
    }
}

# Get all fixed drives except C:
$Drives = [System.IO.DriveInfo]::GetDrives() | Where-Object {
    $_.IsReady -and
    $_.DriveType -eq 'Fixed' -and
    $_.Name -ne "C:\"
}

foreach ($Drive in $Drives) {
    Write-Host "`nScanning drive: $($Drive.Name)" -ForegroundColor Cyan

    try {
        $Files = Get-ChildItem -Path $Drive.Name -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
            $_.Extension -eq ".enc"
        }
    } catch {
        Write-Warning "Failed to access $($Drive.Name): $_"
        continue
    }

    foreach ($EncFile in $Files) {
        Decrypt-File -EncPath $EncFile.FullName
    }
}

Write-Host "`nDecryption completed." -ForegroundColor Green
