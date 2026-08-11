@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0%~n0.ps1" %*
if errorlevel 1 pause
