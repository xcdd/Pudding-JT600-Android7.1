@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Run-JT600Flash.ps1" -Mode Update %*
if errorlevel 1 goto :failure
echo.
echo Flash workflow completed. Device verification passed. Press any key to exit.
pause >nul
exit /b 0
:failure
echo.
echo ERROR: Flash workflow did not complete. Review the PowerShell output above.
pause
exit /b 1
