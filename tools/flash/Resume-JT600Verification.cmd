@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Resume-JT600Verification.ps1"
if errorlevel 1 (
  echo.
  echo 验收流程未完成，请根据上面的错误处理。
  pause
  exit /b 1
)
echo.
echo 刷写完成，设备验收成功。按任意键退出。
pause >nul
