[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Factory', 'Update')]
    [string]$Mode,

    [Parameter(Mandatory = $true)]
    [string]$FirmwareDirectory,

    [Parameter(Mandatory = $true)]
    [string]$AndroidToolDirectory,

    [string]$BackupDirectory,

    [string]$OutputDirectory = (Join-Path $env:TEMP ("JT600-AndroidTool-" + (Get-Date -Format 'yyyyMMdd-HHmmss')))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-FullPath([string]$Path) {
    if ([IO.Path]::IsPathRooted($Path)) { return [IO.Path]::GetFullPath($Path) }
    return [IO.Path]::GetFullPath((Join-Path (Get-Location) $Path))
}

function Require-File([string]$Path, [string]$Description) {
    $full = Resolve-FullPath $Path
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        throw "$Description not found: $full"
    }
    return $full
}

function Set-Utf16Field([byte[]]$Row, [int]$Offset, [int]$Size, [string]$Value) {
    $encoded = [Text.Encoding]::Unicode.GetBytes($Value)
    if ($encoded.Length + 2 -gt $Size) {
        throw "AndroidTool path is too long for its config field: $Value"
    }
    [Array]::Clear($Row, $Offset, $Size)
    [Array]::Copy($encoded, 0, $Row, $Offset, $encoded.Length)
}

function Get-Utf16Field([byte[]]$Row, [int]$Offset, [int]$Size) {
    $raw = $Row[$Offset..($Offset + $Size - 1)]
    $end = $Size
    for ($i = 0; $i -lt $Size; $i += 2) {
        if ($raw[$i] -eq 0 -and $raw[$i + 1] -eq 0) { $end = $i; break }
    }
    return [Text.Encoding]::Unicode.GetString($raw, 0, $end)
}

function Set-UInt32([byte[]]$Row, [int]$Offset, [uint32]$Value) {
    [Array]::Copy([BitConverter]::GetBytes($Value), 0, $Row, $Offset, 4)
}

function Get-UInt32([byte[]]$Row, [int]$Offset) {
    return [BitConverter]::ToUInt32($Row, $Offset)
}

function New-Row([byte[]]$Template, [string]$Name, [string]$Path, [uint32]$Address, [bool]$Selected) {
    $row = [byte[]]$Template.Clone()
    Set-Utf16Field $row 2 32 $Name
    Set-Utf16Field $row 82 520 $Path
    Set-UInt32 $row 602 $Address
    Set-UInt32 $row 606 ([uint32]([int]$Selected))
    return $row
}

function Get-Image([string]$Directory, [string]$Name, [long]$ExpectedBytes) {
    $path = Require-File (Join-Path $Directory $Name) "Required firmware file $Name"
    $length = (Get-Item -LiteralPath $path).Length
    if ($length -ne $ExpectedBytes) {
        throw "$Name has $length bytes; expected $ExpectedBytes bytes"
    }
    return $path
}

function Assert-ManifestHash([string]$ManifestPath, [string]$FilePath) {
    $leaf = [IO.Path]::GetFileName($FilePath)
    $line = Get-Content -LiteralPath $ManifestPath -Encoding UTF8 |
        Where-Object { $_ -match ('^([0-9a-fA-F]{64})\s+\*?' + [regex]::Escape($leaf) + '$') } |
        Select-Object -First 1
    if ($null -eq $line) { throw "SHA256SUMS.txt has no entry for $leaf" }
    $expected = ([regex]::Match($line, '^[0-9a-fA-F]{64}')).Value.ToUpperInvariant()
    $actual = (Get-FileHash -LiteralPath $FilePath -Algorithm SHA256).Hash.ToUpperInvariant()
    if ($actual -ne $expected) { throw "$leaf SHA-256 mismatch: $actual (expected $expected)" }
}

function Assert-ExpectedHash([string]$FilePath, [string]$Expected) {
    $actual = (Get-FileHash -LiteralPath $FilePath -Algorithm SHA256).Hash.ToUpperInvariant()
    if ($actual -ne $Expected.ToUpperInvariant()) { throw "$([IO.Path]::GetFileName($FilePath)) SHA-256 does not match RELEASE-MANIFEST.txt" }
}

$firmware = Resolve-FullPath $FirmwareDirectory
$tool = Resolve-FullPath $AndroidToolDirectory
$manifest = Require-File (Join-Path $firmware 'SHA256SUMS.txt') 'Firmware SHA256SUMS.txt'
$releaseManifest = Require-File (Join-Path $firmware 'RELEASE-MANIFEST.txt') 'Firmware RELEASE-MANIFEST.txt'
$releaseValues = @{}
foreach ($line in Get-Content -LiteralPath $releaseManifest -Encoding UTF8) {
    if ($line -match '^([^=]+)=(.*)$') { $releaseValues[$matches[1]] = $matches[2] }
}
foreach ($key in @('KERNEL', 'BOOT', 'SYSTEM', 'PARAMETER', 'USERDATA_GUARD', 'KERNEL_BYTES', 'BOOT_BYTES', 'SYSTEM_BYTES', 'PARAMETER_BYTES', 'USERDATA_GUARD_BYTES')) {
    if (-not $releaseValues.ContainsKey($key)) { throw "RELEASE-MANIFEST.txt is missing $key" }
}
$toolExe = Require-File (Join-Path $tool 'AndroidTool.exe') 'AndroidTool.exe'
$baseConfig = Require-File (Join-Path $tool 'config.cfg') 'AndroidTool config.cfg'
$configIni = Require-File (Join-Path $tool 'config.ini') 'AndroidTool config.ini'
$adb = Require-File (Join-Path $tool 'bin\adb.exe') 'AndroidTool bundled USB ADB'

$system = Get-Image $firmware $releaseValues['SYSTEM'] ([int64]$releaseValues['SYSTEM_BYTES'])
Assert-ExpectedHash $system $releaseValues['SYSTEM_SHA256']
Assert-ManifestHash $manifest $system
$parameter = $null
$guard = $null
$kernel = $null
$boot = $null
$metadata = $null
$kpanic = $null
if ($Mode -eq 'Factory') {
    $kernel = Get-Image $firmware $releaseValues['KERNEL'] ([int64]$releaseValues['KERNEL_BYTES'])
    $boot = Get-Image $firmware $releaseValues['BOOT'] ([int64]$releaseValues['BOOT_BYTES'])
    $parameter = Get-Image $firmware $releaseValues['PARAMETER'] ([int64]$releaseValues['PARAMETER_BYTES'])
    $guard = Get-Image $firmware $releaseValues['USERDATA_GUARD'] ([int64]$releaseValues['USERDATA_GUARD_BYTES'])
    Assert-ExpectedHash $kernel $releaseValues['KERNEL_SHA256']
    Assert-ExpectedHash $boot $releaseValues['BOOT_SHA256']
    Assert-ExpectedHash $parameter $releaseValues['PARAMETER_SHA256']
    Assert-ExpectedHash $guard $releaseValues['USERDATA_GUARD_SHA256']
    Assert-ManifestHash $manifest $kernel
    Assert-ManifestHash $manifest $boot
    Assert-ManifestHash $manifest $parameter
    Assert-ManifestHash $manifest $guard
    if ([string]::IsNullOrWhiteSpace($BackupDirectory)) {
        throw 'Factory mode requires the target device backup directory containing metadata.img and kpanic.img'
    }
    $backup = Resolve-FullPath $BackupDirectory
    $metadata = Get-Image $backup 'metadata.img' 4194304
    $kpanic = Get-Image $backup 'kpanic.img' 4194304
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$output = Resolve-FullPath $OutputDirectory
$stagedTool = Join-Path $output 'AndroidTool-v2.38'
if (Test-Path -LiteralPath $stagedTool) { throw "Output directory already contains staged AndroidTool: $stagedTool" }
New-Item -ItemType Directory -Force -Path $stagedTool | Out-Null
foreach ($file in @('AndroidTool.exe', 'config.cfg', 'config.ini', 'rk3128.cfg', 'config.factory-template.cfg')) {
    Copy-Item -Force (Join-Path $tool $file) (Join-Path $stagedTool $file)
}
foreach ($directory in @('bin', 'Language')) {
    Copy-Item -Recurse -Force (Join-Path $tool $directory) (Join-Path $stagedTool $directory)
}

$templateName = if ($Mode -eq 'Factory') { 'config.factory-template.cfg' } else { 'config.cfg' }
$source = [IO.File]::ReadAllBytes((Join-Path $stagedTool $templateName))
$headerSize = 29
$rowSize = 610
$rowCount = 12
if ($source.Length -ne $headerSize + $rowSize * $rowCount -or $source[0] -ne 0x43 -or $source[1] -ne 0x46 -or $source[2] -ne 0x47) {
    throw 'The supplied AndroidTool config.cfg is not the expected v2.38 format'
}
$rows = @()
for ($i = 0; $i -lt $rowCount; $i++) {
    $rows += ,([byte[]]$source[($headerSize + $i * $rowSize)..($headerSize + ($i + 1) * $rowSize - 1)])
}
$desired = @()
if ($Mode -eq 'Factory') {
    $desired += ,(New-Row $rows[6] 'Kernel' $kernel 0x0000E000 $true)
    $desired += ,(New-Row $rows[7] 'Boot' $boot 0x00014000 $true)
}
$desired += ,(New-Row $rows[9] 'System' $system 0x0008A000 $true)
if ($Mode -eq 'Factory') {
    $desired += ,(New-Row $rows[1] 'Device-Metadata' $metadata 0x0048A000 $true)
    $desired += ,(New-Row $rows[2] 'Device-Kpanic' $kpanic 0x0048C000 $true)
    $desired += ,(New-Row $rows[3] 'Userdata-Guard' $guard 0x0048E000 $true)
    $desired += ,(New-Row $rows[4] 'Parameter' $parameter 0 $true)
}
$desired += ,(New-Row $rows[5] 'Loader' (Get-Utf16Field $rows[5] 82 520) 0 $false)
for ($i = $desired.Count; $i -lt $rowCount; $i++) {
    $sourceRow = $rows[[Math]::Min($i, $rows.Count - 1)]
    $desired += ,(New-Row $sourceRow ("Disabled-{0}" -f ($i + 1)) (Get-Utf16Field $sourceRow 82 520) 0 $false)
}
$config = [byte[]]($source[0..($headerSize - 1)] + ($desired | ForEach-Object { $_ }))
$selectedCount = if ($Mode -eq 'Factory') { 7 } else { 1 }
for ($i = 0; $i -lt $desired.Count; $i++) {
    $actualSelected = Get-UInt32 $desired[$i] 606
    $expectedSelected = if ($i -lt $selectedCount) { 1 } else { 0 }
    if ($actualSelected -ne $expectedSelected) { throw "Generated AndroidTool row $i has an unexpected selected state." }
    $rowName = Get-Utf16Field $desired[$i] 2 32
    if ($rowName -eq 'Loader' -and $actualSelected -ne 0) { throw 'Generated AndroidTool config selected Loader.' }
}
$generatedConfig = Join-Path $stagedTool 'config.cfg'
[IO.File]::WriteAllBytes($generatedConfig, $config)

$job = [ordered]@{
    mode = $Mode
    firmwareDirectory = $firmware
    androidToolDirectory = $stagedTool
    androidToolExe = $toolExe
    adb = (Join-Path $stagedTool 'bin\adb.exe')
    config = $generatedConfig
    createdUtc = [DateTime]::UtcNow.ToString('o')
    selectedRows = @($desired | Select-Object -First $(if ($Mode -eq 'Factory') { 7 } else { 1 }) | ForEach-Object {
        [ordered]@{ name = (Get-Utf16Field $_ 2 32); address = ('0x{0:X8}' -f (Get-UInt32 $_ 602)); path = (Get-Utf16Field $_ 82 520) }
    })
}
$jobPath = Join-Path $output 'jt600-flash-job.json'
$job | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $jobPath -Encoding UTF8
Write-Output "CONFIG=$generatedConfig"
Write-Output "JOB=$jobPath"
