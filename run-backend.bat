@echo off
title Telugu Tiffin Khata - Backend Server
cd /d "%~dp0backend"
echo ========================================================
echo Starting Telugu Tiffin Khata Backend (Spring Boot)...
echo ========================================================

REM Load variables from .env if present
if exist ".env" (
    for /F "usebackq tokens=1,* delims==" %%A in (".env") do (
        if not "%%A"=="" if not "%%B"=="" (
            set "%%A=%%B"
        )
    )
)

if "%MONGODB_URI%"=="" (
    set "MONGODB_URI=mongodb://localhost:27017/tiffin_ledger_db"
)

echo [INFO] MongoDB URI: %MONGODB_URI%
echo ========================================================

if exist "mvn.cmd" (
    call "mvn.cmd" spring-boot:run
) else (
    "D:\Intellij Ide\IntelliJ IDEA 2026.2.3\plugins\maven-plugin\lib\maven3\bin\mvn.cmd" spring-boot:run
)
pause
