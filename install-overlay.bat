@echo off
setlocal
title IP Guard - Install Desktop Alert
cd /d "%~dp0"

set "IPGUARD_OVERLAY=%~dp0alert.ps1"
set "IPGUARD_FONT_REGULAR=%~dp0Vazirmatn-Regular.ttf"
set "IPGUARD_FONT_BOLD=%~dp0Vazirmatn-Bold.ttf"
set "IPGUARD_STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

echo ============================================
echo   IP Guard - Install Desktop Alert Overlay
echo ============================================

if not exist "%IPGUARD_OVERLAY%" (
    echo [ERROR] alert.ps1 was not found beside this script.
    pause
    exit /b 1
)

echo Checking Vazirmatn font files...
if not exist "%IPGUARD_FONT_REGULAR%" (
    echo Downloading Vazirmatn Regular...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/rastikerdar/vazirmatn/v33.003/fonts/ttf/Vazirmatn-Regular.ttf' -OutFile $env:IPGUARD_FONT_REGULAR"
    if errorlevel 1 goto :font_error
)
if not exist "%IPGUARD_FONT_BOLD%" (
    echo Downloading Vazirmatn Bold...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/rastikerdar/vazirmatn/v33.003/fonts/ttf/Vazirmatn-Bold.ttf' -OutFile $env:IPGUARD_FONT_BOLD"
    if errorlevel 1 goto :font_error
)

echo Stopping any earlier IP Guard overlay...
call "%~dp0uninstall-overlay.bat" /quiet

echo Creating the startup shortcut...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $shell=New-Object -ComObject WScript.Shell; $shortcut=$shell.CreateShortcut((Join-Path $env:IPGUARD_STARTUP 'IPGuardAlert.lnk')); $shortcut.TargetPath=Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'; $shortcut.Arguments='-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ' + [char]34 + $env:IPGUARD_OVERLAY + [char]34; $shortcut.WorkingDirectory=Split-Path -Parent $env:IPGUARD_OVERLAY; $shortcut.WindowStyle=7; $shortcut.Description='IP Guard desktop security alert'; $shortcut.Save()"
if errorlevel 1 (
    echo [ERROR] Could not create the startup shortcut.
    pause
    exit /b 1
)

echo Launching the overlay...
start "" "%WINDIR%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%IPGUARD_OVERLAY%"
echo.
echo [OK] Overlay installed. It will start automatically at each Windows login.
pause
exit /b 0

:font_error
echo [ERROR] Vazirmatn could not be downloaded. Check your Internet connection and run this script again.
pause
exit /b 1
