$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceImage = Join-Path $root "Arduino.jpg"
$outImage = Join-Path $root "Key.jpg"
$vaultPath = Join-Path $root ".vault_flag"
$zipPath = Join-Path $env:TEMP "key-vault.zip"

$vaultText = @"
# Zander's Portfolio Vault
# Copy the line below into the flag box on the main portfolio (Cybersecurity section).

CTF{zander_goh_vault_unlock}
"@

Set-Content -Path $vaultPath -Value $vaultText -Encoding UTF8 -NoNewline
Add-Content -Path $vaultPath -Value "`n"

if (-not (Test-Path $sourceImage)) {
    Write-Error "Source image Arduino.jpg not found."
    exit 1
}

if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path $vaultPath -DestinationPath $zipPath -Force

$comment = "check for hidden files"
$commentBytes = [System.Text.Encoding]::ASCII.GetBytes($comment)
$comLength = $commentBytes.Length + 2
$comSegment = [byte[]](0xFF, 0xFE, ($comLength -shr 8), ($comLength -band 0xFF)) + $commentBytes

$jpeg = [System.IO.File]::ReadAllBytes($sourceImage)
if ($jpeg[0] -ne 0xFF -or $jpeg[1] -ne 0xD8) {
    Write-Error "Arduino.jpg is not a valid JPEG."
    exit 1
}

$jpegWithCom = New-Object byte[] ($jpeg.Length + $comSegment.Length)
[Array]::Copy($jpeg, 0, $jpegWithCom, 0, 2)
[Array]::Copy($comSegment, 0, $jpegWithCom, 2, $comSegment.Length)
[Array]::Copy($jpeg, 2, $jpegWithCom, (2 + $comSegment.Length), ($jpeg.Length - 2))

$zip = [System.IO.File]::ReadAllBytes($zipPath)
$combined = New-Object byte[] ($jpegWithCom.Length + $zip.Length)
[Array]::Copy($jpegWithCom, 0, $combined, 0, $jpegWithCom.Length)
[Array]::Copy($zip, 0, $combined, $jpegWithCom.Length, $zip.Length)
[System.IO.File]::WriteAllBytes($outImage, $combined)

Remove-Item $vaultPath -Force
Remove-Item $zipPath -Force

Write-Host "Created $outImage ($($combined.Length) bytes)"
