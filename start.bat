@echo off
REM Alfresco API Uploader - Startup Script (Windows)

cd /d "%~dp0"

echo.
echo === Alfresco API Uploader ===
echo.
echo How would you like to run the app?
echo   1) Local (Python)
echo   2) Docker
echo.
set /p CHOICE="Enter choice [1-2]: "

if "%CHOICE%"=="2" goto :docker
if "%CHOICE%"=="1" goto :local
if "%CHOICE%"=="" goto :local
echo Invalid choice. Exiting.
exit /b 1

:docker
docker --version >nul 2>&1
if errorlevel 1 (
    echo Error: Docker is not installed. Please install Docker and try again.
    exit /b 1
)

echo Building Docker image...
docker build -t alfresco-uploader .
if errorlevel 1 (
    echo Docker build failed.
    exit /b 1
)

echo Starting container on http://localhost:5001
docker run -d --name alfresco-uploader -p 5001:5001 alfresco-uploader
if errorlevel 1 (
    echo Failed to start container.
    exit /b 1
)

echo.
echo Alfresco API Uploader is running in Docker!
echo Press Ctrl+C to stop the container.
echo.

start http://localhost:5001

REM Keep window open and tail logs
docker logs -f alfresco-uploader
goto :eof

:local
REM Check if virtual environment exists, if not create it
if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
)

REM Activate virtual environment
call venv\Scripts\activate.bat

REM Install/update dependencies
echo Installing dependencies...
pip install -r requirements.txt >nul 2>&1

REM Check for python3 or python
if exist "python3.exe" (
    set PYCMD=python3
) else (
    set PYCMD=python
)

REM Start the Flask app in background
echo Starting backend server on http://localhost:5001
start /B %PYCMD% backend.py

echo.
echo Alfresco API Uploader is running!
echo Press Ctrl+C to stop the server
echo.

REM Keep window open
pause
