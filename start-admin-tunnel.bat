@echo off
title Telugu Tiffin Khata - Admin Portal Internet Tunnel
echo ========================================================
echo Starting Public Cloudflare Tunnel for Admin Portal (Port 5173)...
echo ========================================================
echo Connecting your Admin Portal to the global internet...
echo Look for the https://*.trycloudflare.com URL below!
echo.
echo You can open that URL in any browser on any phone or laptop anywhere in the world!
echo ========================================================
"%~dp0tools\cloudflared.exe" tunnel --url http://localhost:5173
pause
