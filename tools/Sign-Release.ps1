param(
    [Parameter(Mandatory)] [string]$InstallerPath,
    [Parameter(Mandatory)] [string]$CertificateThumbprint
)

$ErrorActionPreference = 'Stop'
$installer = [System.IO.Path]::GetFullPath($InstallerPath)
if (-not (Test-Path -LiteralPath $installer -PathType Leaf)) { throw "Installer not found: $installer" }

$certificate = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert |
    Where-Object Thumbprint -EQ $CertificateThumbprint | Select-Object -First 1
if (-not $certificate) { throw 'The requested code-signing certificate is not installed for the current Windows user.' }
if (-not $certificate.HasPrivateKey) { throw 'The installed certificate does not contain its private signing key.' }
if ($certificate.NotAfter -le (Get-Date)) { throw 'The code-signing certificate has expired.' }

$signTool = Get-ChildItem 'C:\Program Files (x86)\Windows Kits\10\bin\*\x64\signtool.exe' -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending | Select-Object -First 1
if (-not $signTool) { throw 'Microsoft SignTool was not found. Install the Windows SDK signing tools.' }

& $signTool.FullName sign /sha1 $certificate.Thumbprint /fd SHA256 /td SHA256 /tr 'http://timestamp.digicert.com' $installer
if ($LASTEXITCODE -ne 0) { throw "SignTool failed with exit code $LASTEXITCODE." }
& $signTool.FullName verify /pa /all /v $installer
if ($LASTEXITCODE -ne 0) { throw "Signature verification failed with exit code $LASTEXITCODE." }

Get-AuthenticodeSignature -FilePath $installer | Select-Object Status, StatusMessage, SignerCertificate, TimeStamperCertificate

