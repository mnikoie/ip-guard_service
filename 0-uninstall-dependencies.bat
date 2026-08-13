@echo off
title IP Guard - Remove Project Dependencies
cd /d "%~dp0"
set "IPGUARD_SERVICE=ipguardservice.exe"
set "IPGUARD_REMOVE_SERVICE=0"

if /i "%~1"=="/remove-service" set "IPGUARD_REMOVE_SERVICE=1"

echo ============================================
echo   IP Guard - Remove Project Dependencies
echo ============================================
echo This removes only this project's node_modules folder.
echo Node.js installed on Windows will not be removed.
echo.

sc query "%IPGUARD_SERVICE%" >nul 2>&1
if %errorlevel% equ 0 if "%IPGUARD_REMOVE_SERVICE%"=="0" (
    echo [WARNING] IPGuardService is still installed.
    echo To avoid leaving a broken service behind, remove dependencies from
    echo the IP Guard Tray menu and confirm removal of the service too.
    pause
    exit /b 1
)

if "%IPGUARD_REMOVE_SERVICE%"=="1" (
    net session >nul 2>&1
    if %errorlevel% neq 0 (
        echo [ERROR] Administrator permission is required to remove the Windows service.
        pause
        exit /b 1
    )

    sc query "%IPGUARD_SERVICE%" >nul 2>&1
    if %errorlevel% equ 0 (
        echo Stopping IPGuardService...
        sc stop "%IPGUARD_SERVICE%" >nul 2>nul
        timeout /t 2 /nobreak >nul
        echo Removing the Windows service...
        sc delete "%IPGUARD_SERVICE%" >nul
        if errorlevel 1 (
            echo [ERROR] The Windows service could not be removed.
            pause
            exit /b 1
        )
        echo [OK] Windows service removed.
    )
)

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
