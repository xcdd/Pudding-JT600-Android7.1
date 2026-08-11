@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Run-JT600Flash.ps1" -Mode Factory -InitializeData %*
if errorlevel 1 pause
