[CmdletBinding()]
param(
    [ValidateSet('Factory', 'Update')]
    [string]$Mode = 'Factory',
    [string]$FirmwareDirectory,
    [string]$AndroidToolDirectory,
    [string]$BackupDirectory,
    [switch]$InitializeData
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$prepare = Join-Path $PSScriptRoot '01-prepare-jt600-flash.ps1'
$run = Join-Path $PSScriptRoot '02-run-androidtool.ps1'
$verify = Join-Path $PSScriptRoot '03-verify-jt600.ps1'
$workspace = Join-Path $env:TEMP ("JT600-flash-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
& $prepare -Mode $Mode -FirmwareDirectory $FirmwareDirectory -AndroidToolDirectory $AndroidToolDirectory -BackupDirectory $BackupDirectory -Workspace $workspace
$job = Join-Path $workspace 'jt600-flash-job.json'
& $run -JobFile $job
& $verify -JobFile $job -InitializeData:$InitializeData
