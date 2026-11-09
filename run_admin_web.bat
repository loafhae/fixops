@echo off
echo ===================================================
echo Starting FIXOPS React Admin and Technician Portal
echo ===================================================
cd /d "%~dp0frontend\admin-web"
if not exist node_modules (
  call npm install
  if errorlevel 1 exit /b 1
)
call npm run dev -- --open
pause
