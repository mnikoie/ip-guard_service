@echo off
title IP Guard - Start Service
cd /d "%~dp0"

echo ============================================
echo   IP Guard Service - Start
echo ============================================

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This operation requires Administrator permission.
    pause
    exit /b 1
)

sc query IPGuardService >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] IPGuardService is not installed yet.
    pause
    exit /b 1
)

net start IPGuardService
if %errorlevel% neq 0 (
    echo [ERROR] The service could not be started. Check the message above.
    pause
    exit /b 1
)

echo [OK] IPGuardService is running.
pause
