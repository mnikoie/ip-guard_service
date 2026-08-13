@echo off
title IP Guard - Restart Service
echo ============================================
echo   IP Guard Service - Restart
echo ============================================
cd /d "%~dp0"

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script must be run as Administrator.
    echo Right-click this file and choose "Run as administrator".
    pause
    exit /b 1
)

echo Stopping IPGuardService...
sc stop ipguardservice.exe >nul 2>nul

echo Starting IPGuardService...
sc start ipguardservice.exe

echo.
echo [OK] Restart command sent. Check services.msc for status.
pause
