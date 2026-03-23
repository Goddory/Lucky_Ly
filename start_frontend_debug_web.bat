@echo off
setlocal

echo [Lucky_Ly] Starting frontend web debug mode...
cd /d "%~dp0web"

if not exist node_modules (
  echo [Lucky_Ly] Installing frontend dependencies...
  call npm install
  if errorlevel 1 (
    echo [Lucky_Ly] npm install failed.
    exit /b 1
  )
)

echo [Lucky_Ly] Debugger: ws://localhost:9229
echo [Lucky_Ly] Web app: http://localhost:3000
set "NODE_OPTIONS=--inspect"
call npm run dev -- --hostname 0.0.0.0 --port 3000

endlocal
