@echo off
setlocal
title IP Guard - Install Tray Manager
cd /d "%~dp0"

set "IPGUARD_TRAY=%~dp0tray-manager.ps1"
set "IPGUARD_STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

echo ============================================
echo   IP Guard - Install Tray Manager
echo ============================================

if not exist "%IPGUARD_TRAY%" (
    echo [ERROR] tray-manager.ps1 was not found beside this script.
    pause
    exit /b 1
)

echo Stopping a previous tray manager, if it is running...
call "%~dp0uninstall-tray-manager.bat" /quiet

echo Creating the startup shortcut...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $shell=New-Object -ComObject WScript.Shell; $shortcut=$shell.CreateShortcut((Join-Path $env:IPGUARD_STARTUP 'IPGuardTrayManager.lnk')); $shortcut.TargetPath=Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'; $shortcut.Arguments='-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ' + [char]34 + $env:IPGUARD_TRAY + [char]34; $shortcut.WorkingDirectory=Split-Path -Parent $env:IPGUARD_TRAY; $shortcut.WindowStyle=7; $shortcut.Description='IP Guard service control menu'; $shortcut.Save()"
if errorlevel 1 (
    echo [ERROR] Could not create the startup shortcut.
    pause
    exit /b 1
)

echo Launching the tray manager...
start "" "%WINDIR%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%IPGUARD_TRAY%"
echo.
echo [OK] Look for the IP Guard AI-protection icon beside the Windows clock.
echo      Right-click the icon to manage the service and desktop alert.
pause
