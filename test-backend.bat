@echo off
title Telugu Tiffin Khata - Run Automated Tests
cd /d "%~dp0backend"
echo ========================================================
echo Running Automated Backend & Voice Tests...
echo ========================================================
"D:\Intellij Ide\IntelliJ IDEA 2026.2.3\plugins\maven-plugin\lib\maven3\bin\mvn.cmd" test
pause
