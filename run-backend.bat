@echo off
title Telugu Tiffin Khata - Backend Server
cd /d "%~dp0backend"
echo ========================================================
echo Starting Telugu Tiffin Khata Backend (Spring Boot)...
echo ========================================================
"D:\Intellij Ide\IntelliJ IDEA 2026.2.3\plugins\maven-plugin\lib\maven3\bin\mvn.cmd" spring-boot:run
pause
