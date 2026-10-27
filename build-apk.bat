@echo off
title Telugu Tiffin Khata - Build Android APK
set "PATH=C:\src\flutter\bin;%PATH%"
cd /d "%~dp0mobile-app"
echo ========================================================
echo Building Release APK for Android...
echo ========================================================
echo.
echo 1. Checking Flutter environment...
call flutter doctor
echo.
echo 2. Running Flutter Build APK (Release)...
call flutter build apk --release
if %ERRORLEVEL% EQU 0 (
    copy /Y "%~dp0mobile-app\build\app\outputs\flutter-apk\app-release.apk" "%~dp0Mahima-Tiffin-Centre.apk"
    echo.
    echo ========================================================
    echo SUCCESS! New APK created and updated at:
    echo %~dp0Mahima-Tiffin-Centre.apk
    echo ========================================================
) else (
    echo.
    echo [ERROR] Build failed. Please check errors above.
)
pause
