@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Run-JT600Flash.ps1" -Mode Factory -InitializeData %*
if errorlevel 1 (
  echo.
  echo 刷写流程未完成，请根据上面的错误处理。
  pause
  exit /b 1
)
echo.
echo 刷写完成，设备验收成功。按任意键退出。
pause >nul
