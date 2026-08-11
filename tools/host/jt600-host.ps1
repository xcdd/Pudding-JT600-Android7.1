[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AdbPath,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$AdbArguments
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $AdbPath -PathType Leaf)) { throw "Pinned USB ADB was not found: $AdbPath" }
& $AdbPath @AdbArguments
exit $LASTEXITCODE
