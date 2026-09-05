[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-SizedFile([string]$Path, [int64]$Length) {
    $stream = [IO.File]::Open($Path, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $stream.SetLength($Length) } finally { $stream.Dispose() }
}

$generator = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\New-JT600AndroidToolConfig.ps1'))

$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('JT600-v12-preflight-test-' + [guid]::NewGuid().ToString('N'))
$firmware = Join-Path $testRoot 'firmware'
$tool = Join-Path $testRoot 'tool'

try {
    New-Item -ItemType Directory -Force -Path $firmware, (Join-Path $tool 'bin'), (Join-Path $tool 'Language') | Out-Null
    foreach ($file in @('AndroidTool.exe', 'config.cfg', 'config.ini', 'rk3128.cfg')) {
        [IO.File]::WriteAllBytes((Join-Path $tool $file), [byte[]]@())
    }
    [IO.File]::WriteAllBytes((Join-Path $tool 'bin\adb.exe'), [byte[]]@())

    New-SizedFile (Join-Path $firmware 'K71M147.img') 12582912
    New-SizedFile (Join-Path $firmware 'S71M57.img') 2147483648
    New-SizedFile (Join-Path $firmware 'B71M29.img') 12582912
    New-SizedFile (Join-Path $firmware 'parameter-expanded-storage.txt') 755
    New-SizedFile (Join-Path $firmware 'userdata-superblock-guard-4m.img') 4194304

    $manifestLines = @(
        'RELEASE_VERSION=1.2'
        'INTERNAL_TUPLE=K71M147/B71M29/S71M57/R71M0'
        'EXPECTED_DISPLAY_ID=JT600 V1.2 (2026-09-05)'
        'EXPECTED_KERNEL_BUILD=#161'
        'EXPECTED_SYSTEM_IMAGE=S71M57.img'
        'EXPECTED_PRELOAD_FILES=JT600-SensorTest.apk,AIDA64.apk,Chrome.apk,LocalSend.apk,Fcitx5.apk'
        'EXPECTED_PRELOAD_PACKAGES=com.jt600.sensortest,com.finalwire.aida64,com.android.chrome,org.localsend.localsend_app,org.fcitx.fcitx5.android'
        'KERNEL=K71M147.img'
        'KERNEL_BYTES=12582912'
        'BOOT=B71M29.img'
        'BOOT_BYTES=12582912'
        'SYSTEM=S71M57.img'
        'SYSTEM_BYTES=2147483648'
        'PARAMETER=parameter-expanded-storage.txt'
        'PARAMETER_BYTES=755'
        'USERDATA_GUARD=userdata-superblock-guard-4m.img'
        'USERDATA_GUARD_BYTES=4194304'
        'TARGET_KERNEL_LBA=0x0000E000'
        'TARGET_BOOT_LBA=0x00014000'
        'TARGET_SYSTEM_LBA=0x0008A000'
        'TARGET_METADATA_LBA=0x0048A000'
        'TARGET_KPANIC_LBA=0x0048C000'
        'TARGET_USERDATA_LBA=0x0048E000'
        'TARGET_PARAMETER_LBA=0x00000000'
    )
    [IO.File]::WriteAllText((Join-Path $firmware 'RELEASE-MANIFEST.txt'), ($manifestLines -join [Environment]::NewLine), [Text.Encoding]::UTF8)

    $backup = Join-Path $testRoot 'device-backup'
    New-Item -ItemType Directory -Force -Path $backup | Out-Null
    New-SizedFile (Join-Path $backup 'metadata.img') 4194304
    New-SizedFile (Join-Path $backup 'kpanic.img') 4194304

    $updateOutput = Join-Path $testRoot 'update-output'
    & $generator -Mode Update -FirmwareDirectory $firmware -AndroidToolDirectory $tool -OutputDirectory $updateOutput | Out-Null
    $updateJob = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $updateOutput 'jt600-flash-job.json') | ConvertFrom-Json
    $updateNames = ($updateJob.manualSteps | ForEach-Object { $_.name }) -join ','
    if ($updateJob.internalTuple -ne 'K71M147/B71M29/S71M57/R71M0' -or $updateJob.manualSteps.Count -ne 2 -or $updateNames -ne 'Kernel,System') {
        throw 'Update task did not produce the final two-row tuple.'
    }

    $factoryOutput = Join-Path $testRoot 'factory-output'
    & $generator -Mode Factory -FirmwareDirectory $firmware -AndroidToolDirectory $tool -BackupDirectory $backup -OutputDirectory $factoryOutput | Out-Null
    $factoryJob = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $factoryOutput 'jt600-flash-job.json') | ConvertFrom-Json
    $factoryNames = ($factoryJob.manualSteps | ForEach-Object { $_.name }) -join ','
    if ($factoryJob.manualSteps.Count -ne 7 -or $factoryNames -ne 'Kernel,Boot,System,Metadata,Kpanic,Userdata,Parameter') {
        throw 'Factory task did not produce the final seven-row tuple.'
    }

    $badManifest = Join-Path $firmware 'RELEASE-MANIFEST.txt'
    [IO.File]::WriteAllText($badManifest, (($manifestLines -join [Environment]::NewLine).Replace('K71M147/B71M29/S71M57/R71M0', 'K71M123/B71M29/S71M57/R71M0')), [Text.Encoding]::UTF8)
    $rejected = $false
    try {
        & $generator -Mode Update -FirmwareDirectory $firmware -AndroidToolDirectory $tool -OutputDirectory (Join-Path $testRoot 'bad-output') | Out-Null
    } catch {
        $rejected = $_.Exception.Message -match 'INTERNAL_TUPLE'
    }
    if (-not $rejected) { throw 'Mismatched tuple was not rejected.' }

    Write-Output 'PASS: final manifest, Factory/Update row contracts and mismatch rejection.'
} finally {
    if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
}
