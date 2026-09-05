@echo off
setlocal
set "DRIVER=%~dp0..\..\firmware-package\tools\DriverAssistant-v5.14\DriverInstall.exe"
if exist "%DRIVER%" goto :driver_found
echo ERROR: DriverInstall.exe not found under firmware-package\tools\DriverAssistant-v5.14.
pause
exit /b 1
:driver_found
powershell.exe -NoProfile -Command "Start-Process -FilePath '%DRIVER%' -Verb RunAs -Wait"
if errorlevel 1 goto :failure
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Set-AndroidToolSafeDefault.ps1"
if errorlevel 1 goto :failure
exit /b 0
:failure
echo ERROR: Driver setup did not complete. Review the PowerShell output above.
pause
exit /b 1
