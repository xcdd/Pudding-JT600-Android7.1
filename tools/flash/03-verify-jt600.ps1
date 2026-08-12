[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$JobFile,
    [switch]$InitializeData
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$job = Get-Content -Raw -Encoding UTF8 -LiteralPath $JobFile | ConvertFrom-Json
Write-Host '验收程序已启动，正在等待设备通过 USB ADB 重新出现...' -ForegroundColor Cyan
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$currentAdb = Join-Path $repoRoot 'firmware-package\tools\AndroidTool-v2.38\bin\adb.exe'
$adb = if (Test-Path -LiteralPath $currentAdb -PathType Leaf) { $currentAdb } else { [string]$job.adb }
if (-not (Test-Path -LiteralPath $adb -PathType Leaf)) { throw "USB ADB not found in staged AndroidTool: $adb" }
$hostAdb = Join-Path $PSScriptRoot '..\host\jt600-host.ps1'

function ADB([string[]]$Arguments) {
    $output = & $hostAdb -AdbPath $adb @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw "ADB failed ($LASTEXITCODE): $($output -join "`n")" }
    return @($output)
}

function Get-AdbDriverState {
    $pnp = Get-Command Get-PnpDevice -ErrorAction SilentlyContinue
    if ($null -eq $pnp) { return 'unknown' }
    $devices = @(Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object {
        $_.FriendlyName -match '(?i)ADB|Android|JT600' -or
        $_.InstanceId -match '(?i)\\Class_Android|VID_2207&PID_0006'
    })
    if ($devices.Count -gt 0) { return 'installed' }
    return 'missing'
}

Write-Host '正在启动项目自带 ADB，并预检 Windows ADB 驱动...' -ForegroundColor Cyan
$adbVersion = @(ADB @('version'))
Write-Host ("当前 ADB：{0}" -f (($adbVersion | Select-Object -First 2) -join '；')) -ForegroundColor Cyan
$null = ADB @('start-server')
$driverState = Get-AdbDriverState
$initialDevices = @(ADB @('devices') | ForEach-Object { ([string]$_).Trim() } | Where-Object { $_ -ne '' })
$initialReady = $initialDevices | Where-Object { $_ -match '^\S+\s+device\s*$' } | Select-Object -First 1
if ($null -ne $initialReady) {
    Write-Host 'ADB 预检已发现可用设备；无需重复等待，直接进入验收。' -ForegroundColor Green
}
elseif ($driverState -eq 'missing') {
    Write-Host '未检测到正在工作的 Windows ADB 驱动。请先运行 tools\flash\00-install-drivers.cmd，完成驱动安装后再重新验收。' -ForegroundColor Red
    throw 'ADB driver preflight failed.'
}
elseif ($driverState -eq 'installed') {
    Write-Host '已检测到 Windows ADB 驱动，正在等待设备启动并连接。' -ForegroundColor Green
}
else {
    Write-Host '无法从当前 Windows 设备列表确认 ADB 驱动，将以 adb devices 实际结果继续检查。' -ForegroundColor Yellow
}

$deadline = [DateTime]::UtcNow.AddMinutes(3)
$waitStarted = [DateTime]::UtcNow
$serial = $initialReady
do {
    try {
        $lines = @(ADB @('devices') | ForEach-Object { ([string]$_).Trim() } | Where-Object { $_ -ne '' })
        $entries = @($lines | Where-Object { $_ -match '^\S+\s+(device|offline|unauthorized)\s*$' })
        $serial = $entries | Where-Object { $_ -match '^\S+\s+device\s*$' } | Select-Object -First 1
        if ($null -eq $serial -and $entries.Count -gt 0) {
            $stateText = ($entries -join '; ')
            Write-Host "检测到 ADB 设备但当前不可验收：$stateText" -ForegroundColor Yellow
        }
    } catch {
        $serial = $null
        $entries = @()
    }
    if ($null -eq $serial) {
        $elapsed = [int](([DateTime]::UtcNow - $waitStarted).TotalSeconds)
        $remaining = [Math]::Max(0, [int](([DateTime]::UtcNow - $deadline).TotalSeconds * -1))
        Write-Host ("等待 USB ADB 设备：已等待 {0} 秒，剩余 {1} 秒。" -f $elapsed, $remaining) -ForegroundColor Gray
        Start-Sleep -Seconds 3
    }
} while ($null -eq $serial -and [DateTime]::UtcNow -lt $deadline)
if ($null -eq $serial) { throw '在等待期限内没有发现可用的 USB ADB 设备。请检查设备是否已启动、USB 线是否连接，以及 ADB 驱动是否正常。' }
Write-Host '设备已通过 USB ADB 连接，正在读取系统版本、启动状态和 SELinux 状态...' -ForegroundColor Cyan
$serial = ([regex]::Match($serial, '^\S+')).Value

$display = (ADB @('-s', $serial, 'shell', 'getprop', 'ro.build.display.id')) -join ''
$boot = (ADB @('-s', $serial, 'shell', 'getprop', 'sys.boot_completed')) -join ''
$selinux = (ADB @('-s', $serial, 'shell', 'getenforce')) -join ''
$kernelVersion = (ADB @('-s', $serial, 'shell', 'uname', '-a')) -join ''
Write-Host "Device=$serial`nDisplay=$display`nKernel=$kernelVersion`nBootCompleted=$boot`nSELinux=$selinux"
$expectedDisplay = [string]$job.expectedDisplayId
if ([string]::IsNullOrWhiteSpace($expectedDisplay)) { throw '刷写任务没有记录目标系统显示版本，无法验收。' }
if ($display.Trim() -ne $expectedDisplay) {
    throw "系统版本不匹配：设备报告 '$($display.Trim())'，本次固件要求 '$expectedDisplay'。"
}
Write-Host "系统版本与 V$($job.releaseVersion) 发布清单一致。" -ForegroundColor Green
$expectedKernel = [string]$job.expectedKernelBuild
if ([string]::IsNullOrWhiteSpace($expectedKernel)) { throw '刷写任务没有记录目标 Kernel 构建号，无法验收。' }
if ($kernelVersion -notmatch ('(?<!\d)' + [regex]::Escape($expectedKernel) + '(?!\d)')) {
    throw "Kernel 版本不匹配：设备未报告 '$expectedKernel'，可能没有写入本次发布的 Kernel。"
}
Write-Host "Kernel 构建号与 V$($job.releaseVersion) 发布清单一致。" -ForegroundColor Green

$dataMount = (ADB @('-s', $serial, 'shell', 'mount')) -join "`n"
if ($dataMount -notmatch '\s/data\s') {
    Write-Warning '/data is not mounted. This is expected after the factory-system flash and before userdata initialization.'
    if ($InitializeData) {
        Write-Host '检测到 /data 尚未挂载，正在确认 userdata 为 5 GiB，然后初始化 /data。' -ForegroundColor Yellow
        $size = ((ADB @('-s', $serial, 'shell', 'blockdev', '--getsize64', '/dev/block/platform/1021c000.rksdmmc/by-name/userdata')) -join '').Trim()
        if ($size -ne '5368709120') { throw "Refusing data initialization: userdata is $size bytes, expected 5368709120" }
        Write-Host '正在创建 5 GiB ext4 数据分区；该操作可能需要一些时间，请不要关闭窗口或拔掉 USB。' -ForegroundColor Cyan
        $formatOutput = ADB @('-s', $serial, 'shell', '/system/bin/make_ext4fs', '-l', '5368709120', '-a', 'data', '-L', 'data', '/dev/block/platform/1021c000.rksdmmc/by-name/userdata')
        foreach ($line in $formatOutput) {
            if (-not [string]::IsNullOrWhiteSpace([string]$line)) { Write-Host ("格式化状态：{0}" -f ([string]$line).Trim()) -ForegroundColor Gray }
        }
        Write-Host 'ext4 数据分区创建命令已成功完成，正在重启设备。' -ForegroundColor Green
        ADB @('-s', $serial, 'reboot') | Out-Null
        Write-Host '/data 初始化完成，设备正在重启；继续等待系统完成启动...' -ForegroundColor Cyan
        Start-Sleep -Seconds 5
        $rebootDeadline = [DateTime]::UtcNow.AddMinutes(5)
        $rebootStarted = [DateTime]::UtcNow
        do {
            $ready = $false
            try {
                $state = (ADB @('-s', $serial, 'get-state')) -join ''
                if ($state.Trim() -eq 'device') {
                    $completed = (ADB @('-s', $serial, 'shell', 'getprop', 'sys.boot_completed')) -join ''
                    $ready = $completed.Trim() -eq '1'
                }
            } catch { }
            if (-not $ready) {
                $elapsed = [int](([DateTime]::UtcNow - $rebootStarted).TotalSeconds)
                Write-Host ("等待初始化后重启完成：已等待 {0} 秒。" -f $elapsed) -ForegroundColor Gray
                Start-Sleep -Seconds 3
            }
        } while (-not $ready -and [DateTime]::UtcNow -lt $rebootDeadline)
        if (-not $ready) { throw 'The device did not complete startup after userdata initialization.' }
        $finalMounts = (ADB @('-s', $serial, 'shell', 'mount')) -join "`n"
        if ($finalMounts -notmatch '\s/data\s') { throw 'The device started but /data is still not mounted.' }
        Write-Host 'Data initialization completed; the device restarted and /data is mounted.' -ForegroundColor Green
    }
}

$bootDeadline = [DateTime]::UtcNow.AddMinutes(5)
do {
    $boot = ((ADB @('-s', $serial, 'shell', 'getprop', 'sys.boot_completed')) -join '').Trim()
    if ($boot -ne '1') {
        Write-Host '系统仍在完成首次启动，继续等待...' -ForegroundColor Gray
        Start-Sleep -Seconds 3
    }
} while ($boot -ne '1' -and [DateTime]::UtcNow -lt $bootDeadline)
if ($boot -ne '1') { throw '设备已连接 ADB，但系统没有在等待期限内完成启动。' }

$releaseId = (ADB @('-s', $serial, 'shell', 'cat', '/system/etc/jt600-release-id')) -join "`n"
$expectedSystemImage = [string]$job.expectedSystemImage
if ([string]::IsNullOrWhiteSpace($expectedSystemImage)) { throw '刷写任务没有记录目标 System 镜像名，无法验收。' }
if ($releaseId -notmatch ('(?m)^SYSTEM_IMAGE=' + [regex]::Escape($expectedSystemImage) + '$')) {
    throw "System 内容不匹配：设备没有报告 SYSTEM_IMAGE=$expectedSystemImage。"
}
Write-Host "System 发布标识与 $expectedSystemImage 一致。" -ForegroundColor Green

$expectedPreloadFiles = @(([string]$job.expectedPreloadFiles).Split(',') | Where-Object { $_ -ne '' })
$missingPreloadFiles = @($expectedPreloadFiles | Where-Object {
    $path = "/system/etc/jt600-preload/$_"
    $output = & $hostAdb -AdbPath $adb -s $serial shell stat -c '%s' $path 2>&1
    $size = if ($LASTEXITCODE -eq 0) { (($output | Select-Object -First 1) -as [string]).Trim() } else { '' }
    $size -notmatch '^\d+$' -or [int64]$size -le 0
})
if ($missingPreloadFiles.Count -gt 0) { throw "System 中缺少用户应用投放源：$($missingPreloadFiles -join ', ')" }
Write-Host 'System 中的五个用户应用投放源均存在。' -ForegroundColor Green

if ([string]$job.mode -eq 'Factory') {
    $expectedPackages = @(([string]$job.expectedPreloadPackages).Split(',') | Where-Object { $_ -ne '' })
    $packageDeadline = [DateTime]::UtcNow.AddMinutes(2)
    do {
        $packageLines = @((ADB @('-s', $serial, 'shell', 'pm', 'list', 'packages', '-f')) | ForEach-Object { [string]$_ })
        $missingPackages = @($expectedPackages | Where-Object {
            $packageName = $_
            -not ($packageLines | Where-Object { $_ -match ('^package:/data/app/.+=' + [regex]::Escape($packageName) + '$') })
        })
        if ($missingPackages.Count -gt 0) {
            Write-Host ("等待用户可卸载应用完成首次投放：{0}" -f ($missingPackages -join ', ')) -ForegroundColor Gray
            Start-Sleep -Seconds 3
        }
    } while ($missingPackages.Count -gt 0 -and [DateTime]::UtcNow -lt $packageDeadline)
    if ($missingPackages.Count -gt 0) { throw "用户可卸载预装应用缺失：$($missingPackages -join ', ')" }
    Write-Host '五个用户可卸载预装应用均已位于 /data/app。' -ForegroundColor Green
}

$suffix = if ($serial.Length -gt 4) { $serial.Substring($serial.Length - 4).ToUpperInvariant() } else { $serial.ToUpperInvariant() }
$expectedDeviceName = "JT600_$suffix"
$deviceName = ((ADB @('-s', $serial, 'shell', 'settings', 'get', 'global', 'device_name')) -join '').Trim()
$bluetoothName = ((ADB @('-s', $serial, 'shell', 'settings', 'get', 'secure', 'bluetooth_name')) -join '').Trim()
if ($deviceName -ne $expectedDeviceName -or $bluetoothName -ne $expectedDeviceName) {
    throw "设备名称不匹配：系统名称='$deviceName'，蓝牙名称='$bluetoothName'，要求='$expectedDeviceName'。"
}
$bluetoothState = (ADB @('-s', $serial, 'shell', 'dumpsys', 'bluetooth_manager')) -join "`n"
if ($bluetoothState -notmatch ('(?m)^\s*name:\s*' + [regex]::Escape($expectedDeviceName) + '\s*$')) {
    throw "蓝牙适配器实际名称不是 $expectedDeviceName；Settings 值正确但蓝牙协议栈尚未应用该名称。"
}
Write-Host "系统名称、蓝牙设置和蓝牙适配器实际名称均为 $expectedDeviceName。" -ForegroundColor Green
