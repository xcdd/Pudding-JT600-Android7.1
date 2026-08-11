[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$JobFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$job = Get-Content -Raw -Encoding UTF8 -LiteralPath $JobFile | ConvertFrom-Json
$exe = [string]$job.androidToolDirectory + '\AndroidTool.exe'
if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw "Staged AndroidTool not found: $exe" }

Write-Host 'AndroidTool 已准备好配置；Loader 行保持未选中。' -ForegroundColor Green
Write-Host '请只核对脚本列出的已选分区，然后由人类点击“执行”。不要点击擦除、低格或 Loader。' -ForegroundColor Yellow
$process = Start-Process -FilePath $exe -WorkingDirectory ([IO.Path]::GetDirectoryName($exe)) -Verb RunAs -PassThru
Write-Host 'AndroidTool 已打开。现在插入 USB，让 JT600 进入 Loader；确认 Loader 行未选中后执行操作，完成后关闭 AndroidTool。脚本会在窗口关闭后自动继续。' -ForegroundColor Cyan
$process.WaitForExit()
Write-Host 'AndroidTool 已关闭。若下载/校验没有都达到 100%，不要继续下一步。' -ForegroundColor Yellow
