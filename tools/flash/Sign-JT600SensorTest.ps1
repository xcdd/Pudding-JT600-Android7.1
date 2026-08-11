[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$UnsignedApk,
    [string]$PlatformKey = (Join-Path $PSScriptRoot '..\..\firmware-package\signing\platform.pk8'),
    [string]$PlatformCertificate = (Join-Path $PSScriptRoot '..\..\firmware-package\signing\platform.x509.pem'),
    [string]$ApkSignerPath,
    [string]$OutputApk = (Join-Path (Get-Location) 'JT600-SensorTest-platform.apk')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
foreach ($path in @($UnsignedApk, $PlatformKey, $PlatformCertificate)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required signing input not found: $path" }
}
if ([string]::IsNullOrWhiteSpace($ApkSignerPath)) {
    $candidate = Join-Path $PSScriptRoot '..\..\firmware-package\tools\build-tools\apksigner.bat'
    if (Test-Path -LiteralPath $candidate -PathType Leaf) { $ApkSignerPath = $candidate }
    else {
        $command = Get-Command apksigner.bat -ErrorAction SilentlyContinue
        if ($null -eq $command) { throw 'apksigner.bat not found; pass -ApkSignerPath from your Android SDK build-tools directory' }
        $ApkSignerPath = $command.Source
    }
}
& $ApkSignerPath sign --key $PlatformKey --cert $PlatformCertificate --out $OutputApk $UnsignedApk
if ($LASTEXITCODE -ne 0) { throw "apksigner failed with exit code $LASTEXITCODE" }
& $ApkSignerPath verify --verbose --print-certs $OutputApk
if ($LASTEXITCODE -ne 0) { throw "signed APK verification failed with exit code $LASTEXITCODE" }
Write-Host "Signed APK: $OutputApk" -ForegroundColor Green
