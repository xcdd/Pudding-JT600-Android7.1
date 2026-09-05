@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0%~n0.ps1" %*
if not errorlevel 1 exit /b 0
echo.
echo ERROR: Original-device export did not complete. Review the PowerShell output above.
pause
exit /b 1
