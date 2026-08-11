[CmdletBinding()]
param(
    [ValidateSet('Factory', 'Update')]
    [string]$Mode = 'Factory',
    [string]$FirmwareDirectory,
    [string]$AndroidToolDirectory,
    [string]$BackupDirectory,
    [string]$Workspace = (Join-Path $env:TEMP ("JT600-flash-" + (Get-Date -Format 'yyyyMMdd-HHmmss')))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Pick-Folder([string]$Description) {
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = $Description
    $dialog.ShowNewFolderButton = $false
    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { throw "Cancelled: $Description" }
    return $dialog.SelectedPath
}

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
if ([string]::IsNullOrWhiteSpace($FirmwareDirectory)) {
    $localFirmware = Join-Path $repoRoot 'firmware-package\jt600-1.0-universal-20260811'
    if (Test-Path -LiteralPath (Join-Path $localFirmware 'SHA256SUMS.txt') -PathType Leaf) { $FirmwareDirectory = $localFirmware }
    else { $FirmwareDirectory = Pick-Folder '选择你已经拥有的 JT600 固件包目录' }
}
if ([string]::IsNullOrWhiteSpace($AndroidToolDirectory)) {
    $localTool = Join-Path $repoRoot 'firmware-package\tools\AndroidTool-v2.38'
    if (Test-Path -LiteralPath (Join-Path $localTool 'AndroidTool.exe') -PathType Leaf) { $AndroidToolDirectory = $localTool }
    else { $AndroidToolDirectory = Pick-Folder '选择 AndroidTool v2.38 文件夹（里面应有 AndroidTool.exe）' }
}
if ($Mode -eq 'Factory' -and [string]::IsNullOrWhiteSpace($BackupDirectory)) {
    $localBackup = Join-Path $repoRoot 'firmware-package\device-backup'
    if (Test-Path -LiteralPath (Join-Path $localBackup 'metadata.img') -PathType Leaf) { $BackupDirectory = $localBackup }
    else { $BackupDirectory = Pick-Folder '选择本台设备导出的 metadata.img 和 kpanic.img 所在目录' }
}

$script = Join-Path $PSScriptRoot 'New-JT600AndroidToolConfig.ps1'
& $script -Mode $Mode -FirmwareDirectory $FirmwareDirectory -AndroidToolDirectory $AndroidToolDirectory -BackupDirectory $BackupDirectory -OutputDirectory $Workspace
