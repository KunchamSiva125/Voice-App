@echo off
title Telugu Tiffin Khata - Public Internet Tunnel
echo ========================================================
echo Starting Public Cloudflare Tunnel for Backend (Port 8080)...
echo ========================================================
echo Connecting your backend to the global internet...
echo Look for the https://*.trycloudflare.com URL below!
echo.
echo Use this URL on your phone's mobile app:
echo Tap "Server Settings" -> Paste the https://*.trycloudflare.com URL!
echo ========================================================
"%~dp0tools\cloudflared.exe" tunnel --url http://localhost:8080
pause
