param(
    [Parameter(Mandatory)] [string]$InstallerPath,
    [Parameter(Mandatory)] [string]$Version,
    [Parameter(Mandatory)] [string]$GitHubOwner,
    [string]$Repository = 'SkyforgeWeather-Releases',
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\update.json')
)

$ErrorActionPreference = 'Stop'
$installer = Get-Item -LiteralPath ([System.IO.Path]::GetFullPath($InstallerPath))
$signature = Get-AuthenticodeSignature -FilePath $installer.FullName
$signatureRequired = $signature.Status -eq [System.Management.Automation.SignatureStatus]::Valid

$assetName = 'Skyforge.Weather.Setup.v' + $Version + '.exe'
$baseUrl = "https://github.com/$GitHubOwner/$Repository"
$manifest = [ordered]@{
    channel = 'alpha'
    version = $Version
    displayVersion = "v$Version"
    publishedUtc = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    installerUrl = "$baseUrl/releases/download/v$Version/$assetName"
    sha256 = (Get-FileHash -LiteralPath $installer.FullName -Algorithm SHA256).Hash
    sizeBytes = $installer.Length
    signatureRequired = $signatureRequired
    silentArguments = ''
    releaseNotesUrl = "$baseUrl/releases/tag/v$Version"
    minimumUpdaterVersion = '1.0'
}

$json = $manifest | ConvertTo-Json
[System.IO.File]::WriteAllText([System.IO.Path]::GetFullPath($OutputPath), $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
Get-Item -LiteralPath ([System.IO.Path]::GetFullPath($OutputPath))

