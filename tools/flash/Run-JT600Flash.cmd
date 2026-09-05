@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Run-JT600Flash.ps1" %*
if not errorlevel 1 exit /b 0
echo.
echo ERROR: Flash workflow did not complete. Review the PowerShell output above.
pause
exit /b 1
