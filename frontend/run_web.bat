@echo off
echo ===================================================
echo Starting FIXOPS Flutter Cross-Platform User App (Chrome)
echo ===================================================
cd /d "%~dp0frontend"
flutter run -d chrome
pause
