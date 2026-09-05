[CmdletBinding()]
param(
    [string]$AndroidToolDirectory,
    [string]$OutputDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Pick-Folder([string]$Description) {
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = $Description
    $dialog.ShowNewFolderButton = $true
    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { throw "Cancelled: $Description" }
    return $dialog.SelectedPath
}

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
if ([string]::IsNullOrWhiteSpace($AndroidToolDirectory)) {
    $localTool = Join-Path $repoRoot 'firmware-package\tools\AndroidTool-v2.38'
    if (Test-Path -LiteralPath (Join-Path $localTool 'AndroidTool.exe') -PathType Leaf) { $AndroidToolDirectory = $localTool }
    else { $AndroidToolDirectory = Pick-Folder '选择 AndroidTool v2.38 文件夹（里面应有 AndroidTool.exe）' }
}
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) { $OutputDirectory = Join-Path $repoRoot 'firmware-package\device-backup' }
$tool = [IO.Path]::GetFullPath($AndroidToolDirectory)
if (-not (Test-Path -LiteralPath (Join-Path $tool 'AndroidTool.exe') -PathType Leaf)) { throw 'AndroidTool.exe not found' }
& (Join-Path $PSScriptRoot 'Set-AndroidToolSafeDefault.ps1') -AndroidToolDirectory $tool
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$output = [IO.Path]::GetFullPath($OutputDirectory)
$jobs = @(
    [pscustomobject]@{ Name = 'metadata.img'; Start = '0x0058A000'; Count = '0x00002000'; Bytes = 4194304 },
    [pscustomobject]@{ Name = 'kpanic.img'; Start = '0x0058C000'; Count = '0x00002000'; Bytes = 4194304 },
    [pscustomobject]@{ Name = 'parameter-original.bin'; Start = '0x00002000'; Count = '0x00000200'; Bytes = 262144 }
)

$exported = Join-Path $tool 'Output\ExportImage.img'
$process = Start-Process -FilePath (Join-Path $tool 'AndroidTool.exe') -WorkingDirectory $tool -Verb RunAs -PassThru
Write-Host 'AndroidTool 已打开。保持窗口打开；现在插入 USB，让 JT600 进入 Loader。' -ForegroundColor Cyan
Write-Host '脚本会监视每次导出完成，自动整理文件并提示下一项，不需要在控制台按 Enter。' -ForegroundColor Cyan

foreach ($job in $jobs) {
    if ($process.HasExited) { throw 'AndroidTool 已提前关闭，导出流程中止。' }
    if (Test-Path -LiteralPath $exported) { Remove-Item -LiteralPath $exported -Force }
    Write-Host "当前导出：$($job.Name)；在 AndroidTool 高级功能填写起始扇区 $($job.Start)、扇区数 $($job.Count)，确认 Loader 后点击“导出镜像”。" -ForegroundColor Cyan
    Write-Host '只做导出，不点击执行、擦除、低格或任何写入按钮。完成后不要关闭 AndroidTool。' -ForegroundColor Yellow

    $deadline = [DateTime]::UtcNow.AddMinutes(10)
    $stable = $false
    do {
        if ($process.HasExited) { throw 'AndroidTool 已提前关闭，导出流程中止。' }
        $exists = Test-Path -LiteralPath $exported -PathType Leaf
        if (-not $exists) { Start-Sleep -Seconds 1; continue }
        $item = Get-Item -LiteralPath $exported
        if ($item.Length -ne $job.Bytes) {
            if ([DateTime]::UtcNow -ge $deadline) { throw "$($job.Name) 导出大小为 $($item.Length)，应为 $($job.Bytes)" }
            Start-Sleep -Seconds 1
            continue
        }
        Start-Sleep -Seconds 2
        $stable = (Get-Item -LiteralPath $exported).Length -eq $job.Bytes
    } while ((-not $stable) -and [DateTime]::UtcNow -lt $deadline)
    if (-not $stable) { throw "等待 $($job.Name) 导出完成超时。" }

    $destination = Join-Path $output $job.Name
    Copy-Item -LiteralPath $exported -Destination $destination -Force
    $sourceStream = [IO.File]::OpenRead($exported)
    $destinationStream = [IO.File]::OpenRead($destination)
    try {
        if ($sourceStream.Length -ne $destinationStream.Length) { throw "复制后的 $($job.Name) 大小不一致。" }
        $sourceBuffer = New-Object byte[] 1048576
        $destinationBuffer = New-Object byte[] 1048576
        while (($sourceCount = $sourceStream.Read($sourceBuffer, 0, $sourceBuffer.Length)) -gt 0) {
            $destinationCount = $destinationStream.Read($destinationBuffer, 0, $sourceCount)
            if ($destinationCount -ne $sourceCount) { throw "复制后的 $($job.Name) 读取长度不一致。" }
            for ($index = 0; $index -lt $sourceCount; $index++) {
                if ($sourceBuffer[$index] -ne $destinationBuffer[$index]) {
                    throw "复制后的 $($job.Name) 内容不一致。"
                }
            }
        }
    } finally {
        $sourceStream.Dispose()
        $destinationStream.Dispose()
    }
    "FILE=$($job.Name)`nBYTES=$($job.Bytes)`nSTART=$($job.Start)`nSECTORS=$($job.Count)" |
        Set-Content -LiteralPath "$destination.manifest.txt" -Encoding UTF8
    Write-Host "已保存并逐字节核对 $destination" -ForegroundColor Green
}

Write-Host '三个镜像均已导出并整理完成。现在关闭 AndroidTool，脚本将结束。' -ForegroundColor Green
$process.WaitForExit()
Write-Host "原厂备份完成。将 metadata.img 和 kpanic.img 所在目录交给下一步刷写脚本；parameter-original.bin 只用于回滚证据。" -ForegroundColor Green
