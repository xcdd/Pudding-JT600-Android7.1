[CmdletBinding()]
param(
    [ValidateSet('Factory', 'Update')]
    [string]$Mode = 'Factory',
    [string]$FirmwareDirectory,
    [string]$AndroidToolDirectory,
    [string]$BackupDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$prepare = Join-Path $PSScriptRoot '01-prepare-jt600-flash.ps1'
$run = Join-Path $PSScriptRoot '02-run-androidtool.ps1'
$verify = Join-Path $PSScriptRoot '03-verify-jt600.ps1'
$workspace = Join-Path $env:TEMP ("JT600-flash-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
Write-Host 'JT600 刷写助手已启动。' -ForegroundColor Green
Write-Host ("刷写模式：{0}" -f $Mode) -ForegroundColor Cyan
Write-Host '[1/4] 正在检查固件、必要文件、文件名和大小，请稍候...' -ForegroundColor Cyan
& $prepare -Mode $Mode -FirmwareDirectory $FirmwareDirectory -AndroidToolDirectory $AndroidToolDirectory -BackupDirectory $BackupDirectory -Workspace $workspace
$job = Join-Path $workspace 'jt600-flash-job.json'
Write-Host '[2/4] 文件检查完成，正在启动 AndroidTool。' -ForegroundColor Green
& $run -JobFile $job
Write-Host '[3/4] AndroidTool 已关闭。正在整理本次操作状态；脚本不会把“关闭窗口”当成成功。' -ForegroundColor Cyan
Write-Host '[4/4] 正在等待设备重新启动并进行验收，请不要拔 USB。' -ForegroundColor Cyan
& $verify -JobFile $job
Write-Host '刷写完成，设备验收成功。' -ForegroundColor Green
