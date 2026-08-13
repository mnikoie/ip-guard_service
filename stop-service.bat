@echo off
title IP Guard - Stop Service
cd /d "%~dp0"

echo ============================================
echo   IP Guard Service - Stop
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

net stop IPGuardService
if %errorlevel% neq 0 (
    echo [ERROR] The service could not be stopped. Check the message above.
    pause
    exit /b 1
)

echo [OK] IPGuardService is stopped.
pause
