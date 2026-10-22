@echo off
title Telugu Tiffin Khata - Flutter App
set "PATH=C:\src\flutter\bin;C:\Program Files\nodejs;%PATH%"
cd /d "%~dp0mobile-app"
echo ========================================================
echo Starting Telugu Tiffin Khata Mobile App...
echo ========================================================
echo Checking connected devices...
flutter devices
echo.
echo To run on Chrome (browser preview): flutter run -d chrome
echo To run on Android device: flutter run
echo ========================================================
flutter run
pause
