@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

title Reconnect Flutter Debug - USB (Advanced)
color 0A

set PROJECT_DIR=C:\Users\super\source\repos\Lucky_Ly\backend\lucky_ly_mobile

:menu
cls
echo.
echo ╔═══════════════════════════════════════════════════════════╗
echo ║     FLUTTER DEBUG RECONNECT - USB                        ║
echo ╚═══════════════════════════════════════════════════════════╝
echo.
echo [1] Attach nhanh (Recommend)
echo [2] Clean + Run (Nếu bị stuck)
echo [3] Kiểm tra thiết bị
echo [4] Kill ADB + Reconnect
echo [5] Thoát
echo.
set /p choice="Chọn tùy chọn (1-5): "

if "%choice%"=="1" (
    cls
    echo.
    echo ⏳ Đang attach vào app...
    echo.
    cd /d %PROJECT_DIR%
    flutter attach
    echo.
    echo ✓ Attach xong! Ấn phím bất kì để quay lại menu...
    pause >nul
    goto menu
)

if "%choice%"=="2" (
    cls
    echo.
    echo ⏳ Đang clean + run... (Chờ một chút)
    echo.
    cd /d %PROJECT_DIR%
    flutter clean
    flutter pub get
    flutter run -v
    echo.
    echo ✓ Xong! Ấn phím bất kì để quay lại menu...
    pause >nul
    goto menu
)

if "%choice%"=="3" (
    cls
    echo.
    echo 📱 Kiểm tra thiết bị...
    echo.
    flutter devices
    echo.
    echo ✓ Xong! Ấn phím bất kì để quay lại menu...
    pause >nul
    goto menu
)

if "%choice%"=="4" (
    cls
    echo.
    echo 🔄 Đang kill ADB + reconnect...
    echo.
    adb kill-server
    timeout /t 1 >nul
    adb start-server
    timeout /t 2 >nul
    flutter devices
    echo.
    echo ✓ Done! Ấn phím bất kì để quay lại menu...
    pause >nul
    goto menu
)

if "%choice%"=="5" (
    exit /b 0
)

echo ❌ Lựa chọn không hợp lệ! Ấn phím bất kì để tiếp tục...
pause >nul
goto menu
