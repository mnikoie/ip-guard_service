@echo off
title IP Guard - Install Dependencies
echo ============================================
echo   IP Guard Service - Installing dependencies
echo ============================================
cd /d "%~dp0"

where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Node.js not found. Please install Node.js LTS from https://nodejs.org
    pause
    exit /b 1
)

echo Running npm install...
call npm install

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] npm install failed. Check the messages above.
    pause
    exit /b 1
)

echo.
echo [OK] Dependencies installed successfully.
pause
