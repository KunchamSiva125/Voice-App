@echo off
title Telugu Tiffin Khata - Permanent Ngrok Tunnel
echo ========================================================
echo Starting Permanent Ngrok Tunnel for Backend (Port 8080)...
echo Domain: https://cautious-designer-favorably.ngrok-free.dev
echo ========================================================
echo.
echo Forwarding internet traffic directly to port 8080...
echo.
"%~dp0tools\ngrok.exe" http 8080 --url https://cautious-designer-favorably.ngrok-free.dev
pause
