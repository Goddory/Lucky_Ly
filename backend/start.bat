@echo off
title Lucky Ly - Development Menu
color 0A
setlocal

echo ========================================
echo    LUCKY LY - START MENU (BACKEND ^& APP)
echo ========================================
echo.
echo [1] Start Backend Server Locally (Port 4000)
echo [2] Run Flutter App (Connect to LOCAL Backend API)
echo [3] Run Flutter App (Connect to CLOUD Render API)
echo.
set /p choice="Select an option (1-3): "

if "%choice%"=="1" goto backend_local
if "%choice%"=="2" goto app_local
if "%choice%"=="3" goto app_cloud

echo Invalid choice.
pause
exit /b 1

:backend_local
cd /d "%~dp0"
echo [1/3] Installing dependencies...
call npm install
if errorlevel 1 (
	echo [ERROR] npm install failed.
	pause
	exit /b 1
)
echo [2/3] Checking cloud services and databases...
call node src/check_connections.js
if errorlevel 1 (
	echo [STOP] Connectivity check failed. Please fix errors above and retry.
	pause
	exit /b 1
)
echo [3/3] Starting server...
call npm run dev
set EXIT_CODE=%ERRORLEVEL%
if not "%EXIT_CODE%"=="0" echo [ERROR] Server exited with code %EXIT_CODE%.
pause
exit /b %EXIT_CODE%

:app_local
cd /d "%~dp0lucky_ly_mobile"
echo.
echo Starting Flutter App (Local Connection)...
echo Detecting Local Network IP for real USB devices...
for /f "delims=[] tokens=2" %%a in ('ping -4 -n 1 %COMPUTERNAME% ^| findstr "["') do set LOCAL_IP=%%a
if "%LOCAL_IP%"=="" set LOCAL_IP=10.0.2.2
echo Detected Machine IP: %LOCAL_IP%
echo.
call flutter run --dart-define=API_BASE_URL=http://%LOCAL_IP%:4000
pause
exit /b 0

:app_cloud
cd /d "%~dp0lucky_ly_mobile"
echo.
echo [WAKE UP] Sending ping to Render Cloud to wake up the server (Spin-up)...
start /b curl -s https://lucky-ly-api.onrender.com/api/health > NUL 2>&1
echo.
echo Starting Flutter App (Cloud Connection: https://lucky-ly-api.onrender.com)...
echo (By the time the app finishes compiling, the server should be awake!)
echo.
call flutter run --dart-define=API_BASE_URL=https://lucky-ly-api.onrender.com
pause
exit /b 0

