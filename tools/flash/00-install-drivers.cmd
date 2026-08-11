@echo off
setlocal
set "DRIVER=%~dp0..\..\firmware-package\tools\DriverAssistant-v5.14\DriverInstall.exe"
if not exist "%DRIVER%" (
  echo DriverInstall.exe not found under firmware-package\tools\DriverAssistant-v5.14
  pause
  exit /b 1
)
powershell.exe -NoProfile -Command "Start-Process -FilePath '%DRIVER%' -Verb RunAs -Wait"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Set-AndroidToolSafeDefault.ps1"
if errorlevel 1 pause
