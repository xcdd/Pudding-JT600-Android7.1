[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$JobFile,
    [switch]$InitializeData
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$job = Get-Content -Raw -Encoding UTF8 -LiteralPath $JobFile | ConvertFrom-Json
$adb = [string]$job.adb
if (-not (Test-Path -LiteralPath $adb -PathType Leaf)) { throw "USB ADB not found in staged AndroidTool: $adb" }
$hostAdb = Join-Path $PSScriptRoot '..\host\jt600-host.ps1'

function ADB([string[]]$Arguments) {
    $output = & $hostAdb -AdbPath $adb @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw "ADB failed ($LASTEXITCODE): $($output -join "`n")" }
    return @($output)
}

$deadline = [DateTime]::UtcNow.AddMinutes(3)
$serial = $null
do {
    $lines = ADB @('devices')
    $serial = $lines | Where-Object { $_ -match '^\S+\s+device$' } | Select-Object -First 1
    if ($null -eq $serial) { Start-Sleep -Seconds 3 }
} while ($null -eq $serial -and [DateTime]::UtcNow -lt $deadline)
if ($null -eq $serial) { throw 'No USB ADB device appeared after flashing. Check the driver, cable and device state before retrying.' }
$serial = ([regex]::Match($serial, '^\S+')).Value

$display = (ADB @('-s', $serial, 'shell', 'getprop', 'ro.build.display.id')) -join ''
$boot = (ADB @('-s', $serial, 'shell', 'getprop', 'sys.boot_completed')) -join ''
$selinux = (ADB @('-s', $serial, 'shell', 'getenforce')) -join ''
Write-Host "Device=$serial`nDisplay=$display`nBootCompleted=$boot`nSELinux=$selinux"

$dataMount = (ADB @('-s', $serial, 'shell', 'mount')) -join "`n"
if ($dataMount -notmatch '\s/data\s') {
    Write-Warning '/data is not mounted. This is expected after the factory-system flash and before userdata initialization.'
    if ($InitializeData) {
        $size = ((ADB @('-s', $serial, 'shell', 'blockdev', '--getsize64', '/dev/block/platform/1021c000.rksdmmc/by-name/userdata')) -join '').Trim()
        if ($size -ne '5368709120') { throw "Refusing data initialization: userdata is $size bytes, expected 5368709120" }
        ADB @('-s', $serial, 'shell', '/system/bin/make_ext4fs', '-l', '5368709120', '-a', 'data', '-L', 'data', '/dev/block/platform/1021c000.rksdmmc/by-name/userdata') | Out-Null
        ADB @('-s', $serial, 'reboot') | Out-Null
        Start-Sleep -Seconds 5
        $rebootDeadline = [DateTime]::UtcNow.AddMinutes(5)
        do {
            $ready = $false
            try {
                $state = (ADB @('-s', $serial, 'get-state')) -join ''
                if ($state.Trim() -eq 'device') {
                    $completed = (ADB @('-s', $serial, 'shell', 'getprop', 'sys.boot_completed')) -join ''
                    $ready = $completed.Trim() -eq '1'
                }
            } catch { }
            if (-not $ready) { Start-Sleep -Seconds 3 }
        } while (-not $ready -and [DateTime]::UtcNow -lt $rebootDeadline)
        if (-not $ready) { throw 'The device did not complete startup after userdata initialization.' }
        $finalMounts = (ADB @('-s', $serial, 'shell', 'mount')) -join "`n"
        if ($finalMounts -notmatch '\s/data\s') { throw 'The device started but /data is still not mounted.' }
        Write-Host 'Data initialization completed; the device restarted and /data is mounted.' -ForegroundColor Green
    }
}
