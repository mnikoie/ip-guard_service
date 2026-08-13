@echo off
title IP Guard - Remove Project Dependencies
cd /d "%~dp0"

echo ============================================
echo   IP Guard - Remove Project Dependencies
echo ============================================
echo This removes only this project's node_modules folder.
echo Node.js installed on Windows will not be removed.
echo.

if not exist "node_modules" (
    echo [INFO] Project dependencies are already absent.
    pause
    exit /b 0
)

echo Removing node_modules...
rmdir /s /q "node_modules"
if errorlevel 1 (
    echo [ERROR] Could not remove node_modules. Close any program using it and try again.
    pause
    exit /b 1
)

echo [OK] Project dependencies removed.
pause
