@echo off
title Telugu Tiffin Khata - Build Android APK
set "PATH=C:\src\flutter\bin;%PATH%"
cd /d "%~dp0mobile-app"
echo ========================================================
echo Building Release APK for Android...
echo ========================================================
echo.
echo 1. Checking Flutter environment...
flutter doctor
echo.
echo 2. Running Flutter Build APK (Release)...
flutter build apk --release
echo.
echo ========================================================
echo APK Location:
echo %~dp0mobile-app\build\app\outputs\flutter-apk\app-release.apk
echo ========================================================
pause
