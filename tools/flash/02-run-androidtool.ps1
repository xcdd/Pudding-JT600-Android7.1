[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$JobFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$job = Get-Content -Raw -Encoding UTF8 -LiteralPath $JobFile | ConvertFrom-Json
$toolDirectory = [string]$job.androidToolDirectory
$exe = Join-Path $toolDirectory 'AndroidTool.exe'
if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw "AndroidTool not found: $exe" }

Write-Host 'AndroidTool 将以全部未选中的配置启动；请按下面清单在界面中填写。' -ForegroundColor Green
Write-Host '脚本不会替你生成或加载分区配置。AndroidTool 窗口打开后，再让设备进入 Loader，按清单逐项添加并执行。' -ForegroundColor Cyan
Write-Host ''
foreach ($item in @($job.manualSteps)) {
    Write-Host ("{0}. 名称={1}  文件={2}  起始地址={3}" -f $item.order, $item.name, $item.file, $item.address) -ForegroundColor Yellow
}
Write-Host ''
Write-Host '只点击“执行”写入上面列出的项目；不要选择 Loader、Resource、擦除、低格、校准/NVRAM 或其他未知项目。' -ForegroundColor Red
$logPath = Join-Path $toolDirectory ('Log\Log' + (Get-Date -Format 'yyyy-MM-dd') + '.txt')
$logStart = if (Test-Path -LiteralPath $logPath) { (Get-Item -LiteralPath $logPath).Length } else { 0 }
$process = Start-Process -FilePath $exe -WorkingDirectory $toolDirectory -Verb RunAs -PassThru
Write-Host 'AndroidTool 已启动。保持窗口打开；现在让设备进入 Loader，按上面清单填写并完成刷写。确认 100% 后关闭 AndroidTool，脚本会继续验收。' -ForegroundColor Cyan
Write-Host '当前状态：正在等待你操作 AndroidTool；每 10 秒显示一次状态。此窗口不会自动推进，也不是卡死。' -ForegroundColor Yellow

$seenLogBytes = $logStart
$success = $false
$failure = $false
while (-not $process.HasExited) {
    if (Test-Path -LiteralPath $logPath) {
        $length = (Get-Item -LiteralPath $logPath).Length
        if ($length -gt $seenLogBytes) {
            $stream = [IO.File]::Open($logPath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
            try {
                $stream.Position = $seenLogBytes
                $reader = New-Object IO.StreamReader($stream, [Text.Encoding]::Default)
                $delta = $reader.ReadToEnd()
                $reader.Dispose()
            } finally { $stream.Dispose() }
            $seenLogBytes = $length
            foreach ($line in ($delta -split "`r?`n" | Where-Object { $_ -match 'Download|校验|测试设备|Error|RunProc|成功|失败' })) {
                if (-not [string]::IsNullOrWhiteSpace($line)) { Write-Host ("AndroidTool 状态：{0}" -f $line.Trim()) -ForegroundColor DarkCyan }
                if ($line -match 'RunProc is ending, ret=1') { $success = $true }
                if ($line -match 'RunProc is ending, ret=0|Error:') { $failure = $true }
            }
        }
    }
    Write-Host ("当前状态：AndroidTool 仍在运行，等待人工完成刷写（{0}）。" -f (Get-Date -Format 'HH:mm:ss')) -ForegroundColor Gray
    Start-Sleep -Seconds 10
}

Write-Host 'AndroidTool 窗口已关闭，正在读取本次新增日志并判断结果...' -ForegroundColor Green
if (Test-Path -LiteralPath $logPath) {
    $length = (Get-Item -LiteralPath $logPath).Length
    if ($length -gt $seenLogBytes) {
        $bytes = [IO.File]::ReadAllBytes($logPath)
        $tail = [Text.Encoding]::Default.GetString($bytes[$seenLogBytes..($length - 1)])
        foreach ($line in ($tail -split "`r?`n" | Where-Object { $_ -match 'Download|校验|测试设备|Error|RunProc|成功|失败' })) {
            if (-not [string]::IsNullOrWhiteSpace($line)) { Write-Host ("AndroidTool 状态：{0}" -f $line.Trim()) -ForegroundColor DarkCyan }
            if ($line -match 'RunProc is ending, ret=1') { $success = $true }
            if ($line -match 'RunProc is ending, ret=0|Error:') { $failure = $true }
        }
    }
}
if ($success) {
    Write-Host '已检测到本次刷写成功记录（RunProc ret=1），现在进入设备验收。' -ForegroundColor Green
}
elseif ($failure) {
    throw '已检测到 AndroidTool 本次操作失败或报错；不会进入设备验收。请保留现场并检查 AndroidTool 窗口中的错误。'
}
else {
    Write-Host 'AndroidTool 没有留下本次成功或失败记录，将改用设备实际状态判断。' -ForegroundColor Yellow
    Write-Host '下面会自动核对 System、Kernel 和分区大小；任何一项不匹配都会停止。Factory 模式核对通过后会初始化 /data 并重启。' -ForegroundColor Yellow
}
