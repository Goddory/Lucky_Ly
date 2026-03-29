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
echo [4] Start Fullstack Debug Web (Backend Local + Frontend Web)
echo.
set /p choice="Select an option (1-4): "

if "%choice%"=="1" goto backend_local
if "%choice%"=="2" goto app_local
if "%choice%"=="3" goto app_cloud
if "%choice%"=="4" goto fullstack_debug_web

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
set PORT_PID=
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /R /C:":4000 .*LISTENING"') do (
	set PORT_PID=%%p
	goto :port_checked
)

:port_checked
if defined PORT_PID (
	echo [WARN] Port 4000 is already in use by PID %PORT_PID%.
	choice /C YN /M "Stop this process and restart backend"
	if errorlevel 2 (
		echo [INFO] Keeping existing process. Backend start canceled.
		pause
		exit /b 0
	)
	taskkill /PID %PORT_PID% /F >NUL 2>&1
	if errorlevel 1 (
		echo [ERROR] Failed to stop PID %PORT_PID%. Please close it manually.
		pause
		exit /b 1
	)
	echo [INFO] Stopped PID %PORT_PID%. Starting backend...
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

:fullstack_debug_web
cd /d "%~dp0"
echo.
echo Starting fullstack debug mode...
echo - Backend local: http://localhost:4000
echo - Flutter web-server:  http://localhost:8080
echo.
start "LuckyLy Backend Local 4000" cmd /k "cd /d "%~dp0" && call npm run dev"
start "LuckyLy Flutter Web-Server" cmd /k "cd /d "%~dp0lucky_ly_mobile" && call flutter run -d web-server --dart-define=API_BASE_URL=http://localhost:4000"
echo [OK] Launched backend and Flutter web-server in separate windows.
pause
exit /b 0

