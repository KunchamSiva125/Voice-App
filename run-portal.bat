@echo off
title Telugu Tiffin Khata - Flutter Admin App
set "PATH=C:\src\flutter\bin;C:\Program Files\nodejs;%PATH%"
echo ========================================================
echo Starting Mahima Tiffin Centre Flutter Admin Portal...
echo ========================================================
echo The entire Admin Portal is 100%% Flutter!
echo Opening: http://localhost:5173
echo ========================================================
start http://localhost:5173
cd /d "%~dp0mobile-app"
flutter run -d chrome --web-port 5173
pause

