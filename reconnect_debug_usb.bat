@echo off
chcp 65001 >nul
title Reconnect Flutter Debug - USB

echo.
echo ╔═══════════════════════════════════════════════════════════╗
echo ║         Đang kết nối lại với app trên thiết bị USB       ║
echo ╚═══════════════════════════════════════════════════════════╝
echo.

cd /d C:\Users\super\source\repos\Lucky_Ly\backend\lucky_ly_mobile

echo [1/3] Kiểm tra thiết bị...
flutter devices
echo.

echo [2/3] Đang attach vào app...
flutter attach
echo.

pause
