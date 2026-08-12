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
foreach ($key in @('RELEASE_VERSION', 'INTERNAL_TUPLE', 'EXPECTED_DISPLAY_ID', 'EXPECTED_KERNEL_BUILD', 'KERNEL', 'BOOT', 'SYSTEM', 'PARAMETER', 'USERDATA_GUARD', 'KERNEL_BYTES', 'BOOT_BYTES', 'SYSTEM_BYTES', 'PARAMETER_BYTES', 'USERDATA_GUARD_BYTES', 'TARGET_KERNEL_LBA', 'TARGET_BOOT_LBA', 'TARGET_SYSTEM_LBA', 'TARGET_METADATA_LBA', 'TARGET_KPANIC_LBA', 'TARGET_USERDATA_LBA', 'TARGET_PARAMETER_LBA')) {
    if (-not $releaseValues.ContainsKey($key)) { throw "RELEASE-MANIFEST.txt is missing $key" }
}
$toolExe = Require-File (Join-Path $tool 'AndroidTool.exe') 'AndroidTool.exe'
$baseConfig = Require-File (Join-Path $tool 'config.cfg') 'AndroidTool config.cfg'
$configIni = Require-File (Join-Path $tool 'config.ini') 'AndroidTool config.ini'
$adb = Require-File (Join-Path $tool 'bin\adb.exe') 'AndroidTool bundled USB ADB'

$system = Get-Image $firmware $releaseValues['SYSTEM'] ([int64]$releaseValues['SYSTEM_BYTES'])
Assert-ExpectedHash $system $releaseValues['SYSTEM_SHA256']
Assert-ManifestHash $manifest $system
$kernel = Get-Image $firmware $releaseValues['KERNEL'] ([int64]$releaseValues['KERNEL_BYTES'])
Assert-ExpectedHash $kernel $releaseValues['KERNEL_SHA256']
Assert-ManifestHash $manifest $kernel
$parameter = $null
$guard = $null
$boot = $null
$metadata = $null
$kpanic = $null
if ($Mode -eq 'Factory') {
    $boot = Get-Image $firmware $releaseValues['BOOT'] ([int64]$releaseValues['BOOT_BYTES'])
    $parameter = Get-Image $firmware $releaseValues['PARAMETER'] ([int64]$releaseValues['PARAMETER_BYTES'])
    $guard = Get-Image $firmware $releaseValues['USERDATA_GUARD'] ([int64]$releaseValues['USERDATA_GUARD_BYTES'])
    Assert-ExpectedHash $boot $releaseValues['BOOT_SHA256']
    Assert-ExpectedHash $parameter $releaseValues['PARAMETER_SHA256']
    Assert-ExpectedHash $guard $releaseValues['USERDATA_GUARD_SHA256']
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
foreach ($file in @('AndroidTool.exe', 'config.cfg', 'config.ini', 'rk3128.cfg')) {
    Copy-Item -Force (Join-Path $tool $file) (Join-Path $stagedTool $file)
}
foreach ($directory in @('bin', 'Language')) {
    Copy-Item -Recurse -Force (Join-Path $tool $directory) (Join-Path $stagedTool $directory)
}

$manualSteps = New-Object 'System.Collections.Generic.List[object]'
if ($Mode -eq 'Factory') {
    $manualSteps.Add([ordered]@{ order = 1; name = 'Kernel'; file = $kernel; address = $releaseValues['TARGET_KERNEL_LBA'] })
    $manualSteps.Add([ordered]@{ order = 2; name = 'Boot'; file = $boot; address = $releaseValues['TARGET_BOOT_LBA'] })
    $manualSteps.Add([ordered]@{ order = 3; name = 'System'; file = $system; address = $releaseValues['TARGET_SYSTEM_LBA'] })
    $manualSteps.Add([ordered]@{ order = 4; name = 'Metadata'; file = $metadata; address = $releaseValues['TARGET_METADATA_LBA'] })
    $manualSteps.Add([ordered]@{ order = 5; name = 'Kpanic'; file = $kpanic; address = $releaseValues['TARGET_KPANIC_LBA'] })
    $manualSteps.Add([ordered]@{ order = 6; name = 'Userdata'; file = $guard; address = $releaseValues['TARGET_USERDATA_LBA'] })
    $manualSteps.Add([ordered]@{ order = 7; name = 'Parameter'; file = $parameter; address = $releaseValues['TARGET_PARAMETER_LBA'] })
}
else {
    $manualSteps.Add([ordered]@{ order = 1; name = 'Kernel'; file = $kernel; address = $releaseValues['TARGET_KERNEL_LBA'] })
    $manualSteps.Add([ordered]@{ order = 2; name = 'System'; file = $system; address = $releaseValues['TARGET_SYSTEM_LBA'] })
}

$job = [ordered]@{
    mode = $Mode
    releaseVersion = $releaseValues['RELEASE_VERSION']
    internalTuple = $releaseValues['INTERNAL_TUPLE']
    expectedDisplayId = $releaseValues['EXPECTED_DISPLAY_ID']
    expectedKernelBuild = $releaseValues['EXPECTED_KERNEL_BUILD']
    firmwareDirectory = $firmware
    androidToolDirectory = $stagedTool
    androidToolExe = $toolExe
    adb = (Join-Path $stagedTool 'bin\adb.exe')
    config = (Join-Path $stagedTool 'config.cfg')
    createdUtc = [DateTime]::UtcNow.ToString('o')
    manualSteps = $manualSteps
}
$jobPath = Join-Path $output 'jt600-flash-job.json'
$job | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $jobPath -Encoding UTF8
Write-Output "CONFIG=$(Join-Path $stagedTool 'config.cfg')"
Write-Output "JOB=$jobPath"
