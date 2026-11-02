@echo off
echo ===================================================
echo Starting FIXOPS Flutter App (Chrome Web Dashboard)
echo ===================================================
cd /d "%~dp0frontend"
flutter run -d chrome
pause

