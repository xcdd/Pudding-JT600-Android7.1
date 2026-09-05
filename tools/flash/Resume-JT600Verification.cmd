@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Resume-JT600Verification.ps1"
if errorlevel 1 goto :failure
echo.
echo Verification completed successfully. Press any key to exit.
pause >nul
exit /b 0
:failure
echo.
echo ERROR: Verification did not complete. Review the PowerShell output above.
pause
exit /b 1
