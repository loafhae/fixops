@echo off
echo ===================================================
echo Starting FIXOPS FastAPI Backend Server
echo Course: BSIT 4B - System Administration
echo ===================================================
cd /d "%~dp0"
call backend\venv\Scripts\activate.bat
set "PYTHONPATH=%CD%"
echo Listening on 0.0.0.0:8000 (LAN and Localhost)...
uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload
pause
