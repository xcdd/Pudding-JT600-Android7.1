[CmdletBinding()]
param(
    [string]$AndroidToolDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
if ([string]::IsNullOrWhiteSpace($AndroidToolDirectory)) {
    $AndroidToolDirectory = Join-Path $repoRoot 'firmware-package\tools\AndroidTool-v2.38'
}
$tool = [IO.Path]::GetFullPath($AndroidToolDirectory)
$configPath = Join-Path $tool 'config.cfg'
$templatePath = Join-Path $tool 'config.vendor-template.cfg'
foreach ($path in @($configPath, (Join-Path $tool 'config.ini'))) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "AndroidTool file not found: $path" }
}
if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) {
    Copy-Item -LiteralPath $configPath -Destination $templatePath
}

$source = [IO.File]::ReadAllBytes($templatePath)
$headerSize = 29
$rowSize = 610
$rowCount = 12
if ($source.Length -ne $headerSize + $rowSize * $rowCount -or [Text.Encoding]::ASCII.GetString($source, 0, 3) -ne 'CFG') {
    throw 'AndroidTool config is not the expected v2.38 format.'
}

$rows = @()
for ($i = 0; $i -lt $rowCount; $i++) {
    $row = [byte[]]$source[($headerSize + $i * $rowSize)..($headerSize + ($i + 1) * $rowSize - 1)]
    # Keep every vendor row field and address intact. AndroidTool only needs
    # the selected flag cleared for a safe startup configuration.
    [Array]::Copy([BitConverter]::GetBytes([uint32]0), 0, $row, 606, 4)
    $rows += ,$row
}
$safe = [byte[]]($source[0..($headerSize - 1)] + ($rows | ForEach-Object { $_ }))
[IO.File]::WriteAllBytes($configPath, $safe)

"CONFIG=config.cfg`nSELECTED_ROWS=0`nLOADER_SELECTED=false" |
    Set-Content -LiteralPath (Join-Path $tool 'SAFE-DEFAULT.txt') -Encoding UTF8
Write-Host 'AndroidTool 默认配置已设为全部写入项未选中。' -ForegroundColor Green
