@echo off
title Lucky Ly - Backend API
color 0A
setlocal

echo ========================================
echo    Lucky Ly - Starting Backend API
echo ========================================
echo.

cd /d "%~dp0"

echo [1/3] Installing dependencies...
call npm install
if errorlevel 1 (
	echo.
	echo [ERROR] npm install failed.
	pause
	exit /b 1
)
echo.

echo [2/3] Checking cloud services and databases...
call node src/check_connections.js
if errorlevel 1 (
	echo.
	echo [STOP] Connectivity check failed. Please fix errors above and retry.
	pause
	exit /b 1
)
echo.

echo [3/3] Starting server...
call npm run dev
set EXIT_CODE=%ERRORLEVEL%

if not "%EXIT_CODE%"=="0" (
	echo.
	echo [ERROR] Server exited with code %EXIT_CODE%.
)

pause
exit /b %EXIT_CODE%
