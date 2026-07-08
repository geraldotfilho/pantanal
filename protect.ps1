# protect.ps1 - Criptografa index_original.html com AES-256-CBC + HMAC-SHA256
# Uso: powershell -ExecutionPolicy Bypass -File protect.ps1
# A senha e lida automaticamente do arquivo .password

param(
    [string]$Password
)

$srcPath  = Join-Path $PSScriptRoot "index_original.html"
$outPath  = Join-Path $PSScriptRoot "index.html"
$tmplPath = Join-Path $PSScriptRoot "login_template.html"
$pwdFile  = Join-Path $PSScriptRoot ".password"

if (-not (Test-Path $srcPath)) {
    Write-Error "ERRO: Arquivo $srcPath nao encontrado."
    exit 1
}

# Resolve password: parameter > .password file > interactive prompt
if (-not $Password) {
    if (Test-Path $pwdFile) {
        $Password = (Get-Content $pwdFile -Raw -Encoding UTF8).Trim()
        Write-Host "Senha lida do arquivo .password" -ForegroundColor DarkGray
    } else {
        $Password = Read-Host "Digite a senha para proteger o site"
    }
}
if (-not $Password) { Write-Error "Senha nao pode ser vazia."; exit 1 }

Write-Host "`nCriptografando..." -ForegroundColor Cyan

$plaintext = [System.IO.File]::ReadAllBytes($srcPath)

$rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
$salt = New-Object byte[] 32; $iv = New-Object byte[] 16
$rng.GetBytes($salt); $rng.GetBytes($iv)

$deriveBytes = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $salt, 600000)
$derived = $deriveBytes.GetBytes(64)
$aesKey = $derived[0..31]; $hmacKey = $derived[32..63]

$aes = New-Object System.Security.Cryptography.AesCryptoServiceProvider
$aes.Mode    = [System.Security.Cryptography.CipherMode]::CBC
$aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
$aes.KeySize = 256; $aes.Key = $aesKey; $aes.IV = $iv

$enc = $aes.CreateEncryptor()
$ct = $enc.TransformFinalBlock($plaintext, 0, $plaintext.Length)
$enc.Dispose(); $aes.Dispose()

$hmac = New-Object System.Security.Cryptography.HMACSHA256(,$hmacKey)
$toMac = New-Object byte[] ($salt.Length + $iv.Length + $ct.Length)
[Array]::Copy($salt, 0, $toMac, 0, $salt.Length)
[Array]::Copy($iv, 0, $toMac, $salt.Length, $iv.Length)
[Array]::Copy($ct, 0, $toMac, $salt.Length + $iv.Length, $ct.Length)
$mac = $hmac.ComputeHash($toMac); $hmac.Dispose()

$saltHex = ([BitConverter]::ToString($salt) -replace '-','').ToLower()
$ivHex   = ([BitConverter]::ToString($iv)   -replace '-','').ToLower()
$macHex  = ([BitConverter]::ToString($mac)  -replace '-','').ToLower()
$ctB64   = [Convert]::ToBase64String($ct)

$payload = '{"salt":"' + $saltHex + '","iv":"' + $ivHex + '","ct":"' + $ctB64 + '","mac":"' + $macHex + '"}'

$template = [System.IO.File]::ReadAllText($tmplPath, [System.Text.Encoding]::UTF8)
$finalHtml = $template -replace '___PAYLOAD___', $payload
[System.IO.File]::WriteAllText($outPath, $finalHtml, (New-Object System.Text.UTF8Encoding($false)))

$sizeKB = [Math]::Round((Get-Item $outPath).Length / 1024)
Write-Host "OK index.html protegido gerado com sucesso! ($sizeKB KB)" -ForegroundColor Green
