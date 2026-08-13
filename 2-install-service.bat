@echo off
title IP Guard - Install Windows Service
echo ============================================
echo   IP Guard Service - Install as Windows Service
echo ============================================
cd /d "%~dp0"

:: Check for Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script must be run as Administrator.
    echo Right-click this file and choose "Run as administrator".
    pause
    exit /b 1
)

if not exist "node_modules" (
    echo [ERROR] Dependencies not installed yet.
    echo Please run 1-install-dependencies.bat first.
    pause
    exit /b 1
)

echo Installing IPGuardService...
node install-service.js

if errorlevel 1 (
    echo.
    echo [ERROR] Service installation failed. Review the error above.
    pause
    exit /b 1
)

echo Updating service description with author contact information...
sc description ipguardservice.exe "IP Guard Service - fail-closed public-IP guard. Author: Seyed Mohammad Ali Nikoei; Mobile: +98 913 267 5400; Email: m.nikoie2005@gmail.com" >nul

echo.
echo [OK] If no errors were shown above, the service "IPGuardService"
echo      has been installed and started. Check services.msc to confirm.
pause
