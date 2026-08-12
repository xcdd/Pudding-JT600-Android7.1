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

# Windows PowerShell 5.1 wraps native stderr as ErrorRecord objects. ADB and
# Android tools also use stderr for normal progress, so preserve it as text and
# decide success only from the native process exit code.
$ErrorActionPreference = 'Continue'
$output = & $AdbPath @AdbArguments 2>&1
$exitCode = $LASTEXITCODE
foreach ($item in @($output)) {
    if ($item -is [Management.Automation.ErrorRecord]) {
        Write-Output $item.Exception.Message
    }
    else {
        Write-Output ([string]$item)
    }
}
exit $exitCode
