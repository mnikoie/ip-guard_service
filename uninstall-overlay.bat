@echo off
setlocal

set "IPGUARD_STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "IPGUARD_PID_FILE=C:\ProgramData\IPGuardService\overlay.pid"

if not "%~1"=="/quiet" (
    title IP Guard - Remove Desktop Alert
    echo ============================================
    echo   IP Guard - Remove Desktop Alert Overlay
    echo ============================================
)

if exist "%IPGUARD_PID_FILE%" (
    for /f "usebackq delims=" %%P in ("%IPGUARD_PID_FILE%") do powershell -NoProfile -Command "$p=Get-CimInstance Win32_Process -Filter ('ProcessId=%%P') -ErrorAction SilentlyContinue; if($p -and $p.CommandLine -and $p.CommandLine -match 'alert\.ps1'){ Stop-Process -Id %%P -Force -ErrorAction SilentlyContinue }"
    del "%IPGUARD_PID_FILE%" >nul 2>nul
)

if exist "%IPGUARD_STARTUP%\IPGuardAlert.lnk" (
    del "%IPGUARD_STARTUP%\IPGuardAlert.lnk"
    if not "%~1"=="/quiet" echo [OK] Startup shortcut removed.
) else (
    if not "%~1"=="/quiet" echo [INFO] No startup shortcut found.
)

if not "%~1"=="/quiet" pause
