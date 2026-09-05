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
$adb = [string]$job.adb
$hostAdb = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\host\jt600-host.ps1'))
if (-not (Test-Path -LiteralPath $adb -PathType Leaf)) { throw "USB ADB not found: $adb" }

function Get-AdbDeviceLines {
    $output = & $hostAdb -AdbPath $adb devices 2>&1
    if ($LASTEXITCODE -ne 0) { return @() }
    return @($output | ForEach-Object { ([string]$_).Trim() } | Where-Object { $_ -match '^\S+\s+(device|offline|unauthorized)\s*$' })
}

function Get-LoaderDevices {
    if ($null -eq (Get-Command Get-PnpDevice -ErrorAction SilentlyContinue)) {
        throw '无法使用 Get-PnpDevice 确认 Rockusb Loader；请在 Windows 设备管理器确认驱动后重试。'
    }
    return @(Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object {
        $_.InstanceId -match '(?i)VID_2207&PID_310C' -or
        $_.FriendlyName -match '(?i)Rockusb|Rockchip Loader'
    })
}

function Wait-ForLoader([int]$TimeoutSeconds = 45) {
    $started = [DateTime]::UtcNow
    $deadline = $started.AddSeconds($TimeoutSeconds)
    do {
        $loaders = @(Get-LoaderDevices)
        if ($loaders.Count -gt 1) {
            $loaderIds = @($loaders | ForEach-Object { $_.InstanceId })
            throw "检测到多个 Rockusb Loader 设备：$($loaderIds -join '; ')。请只保留目标设备。"
        }
        if ($loaders.Count -eq 1) {
            Write-Host "已确认唯一 Rockusb Loader：$($loaders[0].InstanceId)" -ForegroundColor Green
            return
        }
        $elapsed = [int](([DateTime]::UtcNow - $started).TotalSeconds)
        $remaining = [Math]::Max(0, [int]($deadline - [DateTime]::UtcNow).TotalSeconds)
        Write-Host ("等待唯一 Rockusb Loader：已等待 {0} 秒，剩余 {1} 秒。" -f $elapsed, $remaining) -ForegroundColor Gray
        Start-Sleep -Seconds 2
    } while ([DateTime]::UtcNow -lt $deadline)
    throw '未在等待期限内确认唯一 Rockusb Loader 设备；不会启动 AndroidTool。'
}

if ([string]$job.mode -eq 'Update') {
    # An Update run commonly starts while Android is still running. Offer the
    # reversible ADB transition before opening AndroidTool so the operator does
    # not have to discover the Loader step separately.
    $adbEntries = @(Get-AdbDeviceLines)
    $androidEntries = @($adbEntries | Where-Object { $_ -match '^\S+\s+device\s*$' })
    if ($androidEntries.Count -gt 1) {
        throw "检测到多个 Android ADB 设备：$($androidEntries -join '; ')。请只保留目标设备。"
    }
    if ($androidEntries.Count -eq 1) {
        $serial = ([regex]::Match($androidEntries[0], '^\S+')).Value
        Write-Host "检测到 Android 设备 $serial。" -ForegroundColor Cyan
        do {
            $answer = (Read-Host '设备当前在 Android，是否自动进入 BL？输入 Y 自动进入，输入 N 由你手工进入').Trim().ToUpperInvariant()
        } while ($answer -notin @('Y', 'N'))

        if ($answer -eq 'Y') {
            $rebootOutput = & $hostAdb -AdbPath $adb -s $serial reboot bootloader 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "无法通过 USB ADB 进入 BL：$($rebootOutput -join "`n")"
            }
            Write-Host '已发送 reboot bootloader；现在确认 Rockusb Loader。' -ForegroundColor Green
            Wait-ForLoader
        }
        else {
            Write-Host '保持设备当前状态。请手工让它进入 BL；脚本会等待并确认 Loader。' -ForegroundColor Yellow
            Wait-ForLoader
        }
    }
    elseif ($adbEntries.Count -gt 0) {
        Write-Warning "检测到 ADB 设备但状态不可用：$($adbEntries -join '; ')。脚本不会对它发送重启命令，将等待 Loader。"
        Wait-ForLoader
    }
    else {
        Write-Host '未检测到 Android ADB；按已在 BL 处理，先确认唯一 Loader。' -ForegroundColor Cyan
        Wait-ForLoader
    }
}

Write-Host 'AndroidTool 将以全部未选中的配置启动；请按下面清单在界面中填写。' -ForegroundColor Green
Write-Host '脚本不会替你生成或加载分区配置。Update 模式会先确认唯一 Loader，并可从 Android 自动进入 BL。' -ForegroundColor Cyan
Write-Host ''
foreach ($item in @($job.manualSteps)) {
    Write-Host ("{0}. 名称={1}  文件={2}  起始地址={3}" -f $item.order, $item.name, $item.file, $item.address) -ForegroundColor Yellow
}
Write-Host ''
Write-Host '只点击“执行”写入上面列出的项目；不要选择 Loader、Resource、擦除、低格、校准/NVRAM 或其他未知项目。' -ForegroundColor Red
$logPath = Join-Path $toolDirectory ('Log\Log' + (Get-Date -Format 'yyyy-MM-dd') + '.txt')
$logStart = if (Test-Path -LiteralPath $logPath) { (Get-Item -LiteralPath $logPath).Length } else { 0 }
$process = Start-Process -FilePath $exe -WorkingDirectory $toolDirectory -Verb RunAs -PassThru
Write-Host 'AndroidTool 已启动。按上面清单填写并完成刷写。确认 100% 后关闭 AndroidTool，脚本会继续验收。' -ForegroundColor Cyan
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
