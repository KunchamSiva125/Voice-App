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
    set "MONGODB_URI=mongodb+srv://shivakuncham125_db_user:DKOQyeK3skKpfASl@cluster1.66u9c2g.mongodb.net/tiffin_ledger_db?retryWrites=true&w=majority"
)

echo [INFO] MongoDB URI configured for Atlas Cloud.
echo ========================================================

"D:\Intellij Ide\IntelliJ IDEA 2026.2.3\plugins\maven-plugin\lib\maven3\bin\mvn.cmd" spring-boot:run
pause
