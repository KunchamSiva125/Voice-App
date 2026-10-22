# setup-tools.ps1: Verify and configure development environment for Telugu Voice App
$ErrorActionPreference = "Continue"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Checking & Configuring Development Environment" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Ensure C:\src\flutter\bin, C:\Program Files\nodejs, Maven, and Java are in User PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($null -eq $userPath) { $userPath = "" }
$pathsToAdd = @(
    "C:\src\flutter\bin",
    "C:\Program Files\nodejs",
    "D:\Intellij Ide\IntelliJ IDEA 2026.2.3\plugins\maven-plugin\lib\maven3\bin",
    "C:\Program Files\Java\jdk-27\bin"
)

$currentList = $userPath.Split(';') | Where-Object { $_ -ne "" }
$updated = $false
foreach ($p in $pathsToAdd) {
    if (Test-Path $p) {
        if (-not ($currentList -contains $p)) {
            $currentList += $p
            $updated = $true
            Write-Host "[+] Added to PATH: $p" -ForegroundColor Green
        } else {
            Write-Host "[OK] Already in PATH: $p" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "[-] Path not found on disk: $p" -ForegroundColor Yellow
    }
}

if ($updated) {
    $newPath = $currentList -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "[OK] User environment PATH updated successfully." -ForegroundColor Green
}

# Update current session PATH so commands immediately work
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")

Write-Host "`n--- Tool Verification ---" -ForegroundColor Cyan

# Node.js
try {
    $nodeVer = & node -v
    Write-Host "[OK] Node.js version: $nodeVer" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Node.js not detected in session." -ForegroundColor Red
}

# NPM
try {
    $npmVer = & npm -v
    Write-Host "[OK] NPM version: $npmVer" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] NPM not detected in session." -ForegroundColor Red
}

# Java
try {
    $javaVer = & java -version 2>&1 | Select-Object -First 1
    Write-Host "[OK] Java: $javaVer" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Java not detected." -ForegroundColor Red
}

# Maven
try {
    $mvnVer = & mvn -version 2>&1 | Select-Object -First 1
    Write-Host "[OK] Maven: $mvnVer" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Maven not detected in session." -ForegroundColor Red
}

# Flutter
try {
    $flutterVer = & flutter --version 2>&1 | Select-Object -First 1
    Write-Host "[OK] Flutter: $flutterVer" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Flutter not detected in session." -ForegroundColor Red
}

Write-Host "==========================================================" -ForegroundColor Cyan
