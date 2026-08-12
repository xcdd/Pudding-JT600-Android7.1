[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host 'JT600 写后验收恢复程序已启动。不会打开 AndroidTool，也不会重新刷写。' -ForegroundColor Green
$latest = Get-ChildItem -LiteralPath $env:TEMP -Directory -Filter 'JT600-flash-*' -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'jt600-flash-job.json') -PathType Leaf } |
    Select-Object -First 1
if ($null -eq $latest) { throw '没有找到之前的 JT600 刷写任务记录。请先运行对应的刷写脚本。' }

$jobFile = Join-Path $latest.FullName 'jt600-flash-job.json'
$job = Get-Content -Raw -Encoding UTF8 -LiteralPath $jobFile | ConvertFrom-Json
Write-Host ("找到最近任务：{0}，模式：{1}" -f $latest.FullName, $job.mode) -ForegroundColor Cyan
$verify = Join-Path $PSScriptRoot '03-verify-jt600.ps1'
& $verify -JobFile $jobFile -InitializeData:([string]$job.mode -eq 'Factory')
Write-Host '刷写完成，设备验收成功。' -ForegroundColor Green
