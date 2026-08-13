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
net stop IPGuardService >nul 2>nul

echo Uninstalling service...
node uninstall-service.js

echo.
echo [OK] Service stopped and uninstalled (if it existed).
pause
