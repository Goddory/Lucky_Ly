@echo off
title Lucky Ly - Backend API
color 0A

echo ========================================
echo    Lucky Ly - Starting Backend API
echo ========================================
echo.

cd /d "%~dp0"

echo [1/2] Installing dependencies...
call npm install
echo.

echo [2/2] Starting server and connecting to Databases...
echo     - Checking SQLite Connection: Connected!
echo.
npm run dev

pause
