@echo off
title Telugu Tiffin Khata - Admin Web Portal
set "PATH=C:\Users\DELL\AppData\Local\Programs\NodeJS;%PATH%"
cd /d "%~dp0admin-portal"
echo ========================================================
echo Starting Admin Web Portal (React + Vite)...
echo ========================================================
call npm run dev
pause
