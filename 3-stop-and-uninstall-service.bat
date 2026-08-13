@echo off
title IP Guard - Stop and Uninstall Service
echo ============================================
echo   IP Guard Service - Stop / Uninstall
echo ============================================
cd /d "%~dp0"

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script must be run as Administrator.
    echo Right-click this file and choose "Run as administrator".
    pause
    exit /b 1
)

echo Stopping service (if running)...
sc stop ipguardservice.exe >nul 2>nul
timeout /t 2 /nobreak >nul

echo Uninstalling service...
sc delete ipguardservice.exe >nul
if errorlevel 1 (
    echo [ERROR] Service could not be removed. Check the messages above.
    pause
    exit /b 1
)

echo.
echo [OK] Service stopped and uninstalled.
pause
