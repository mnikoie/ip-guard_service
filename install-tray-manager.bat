@echo off
setlocal
title IP Guard - Install Tray Manager
cd /d "%~dp0"

set "IPGUARD_TRAY=%~dp0IP Guard Tray.exe"
set "IPGUARD_STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

echo ============================================
echo   IP Guard - Install Tray Manager
echo ============================================

if not exist "%IPGUARD_TRAY%" (
    echo [ERROR] IP Guard Tray.exe was not found beside this script.
    echo Run build-tray-manager.ps1 first.
    pause
    exit /b 1
)

echo Stopping a previous tray manager, if it is running...
call "%~dp0uninstall-tray-manager.bat" /quiet

echo Creating the startup shortcut...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $shell=New-Object -ComObject WScript.Shell; $shortcut=$shell.CreateShortcut((Join-Path $env:IPGUARD_STARTUP 'IPGuardTrayManager.lnk')); $shortcut.TargetPath=$env:IPGUARD_TRAY; $shortcut.WorkingDirectory=Split-Path -Parent $env:IPGUARD_TRAY; $shortcut.WindowStyle=7; $shortcut.Description='IP Guard service control menu'; $shortcut.Save()"
if errorlevel 1 (
    echo [ERROR] Could not create the startup shortcut.
    pause
    exit /b 1
)

echo Launching the tray manager...
start "" "%IPGUARD_TRAY%"
echo.
echo [OK] Look for the IP Guard AI-protection icon beside the Windows clock.
echo      Right-click the icon to manage the service and desktop alert.
pause
