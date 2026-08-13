param(
    [switch]$SkipIcon
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$source = Join-Path $root 'tray-manager.cs'
$output = Join-Path $root 'IP Guard Tray.exe'
$icon = Join-Path $root 'assets\ip-guard-ai.ico'
$pidFile = Join-Path $env:LOCALAPPDATA 'IPGuardService\tray-manager.pid'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) {
    $compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'
}
if (-not (Test-Path -LiteralPath $compiler)) { throw 'The .NET Framework C# compiler was not found.' }

# A running copy locks the executable on Windows. Stop only the process whose
# PID was written by this manager before replacing the current build.
if (Test-Path -LiteralPath $pidFile) {
    try {
        $runningPid = [int](Get-Content -LiteralPath $pidFile -Raw)
        $runningProcess = Get-Process -Id $runningPid -ErrorAction Stop
        if ($runningProcess.ProcessName -eq 'IP Guard Tray') {
            Stop-Process -Id $runningPid -Force -ErrorAction Stop
            Start-Sleep -Milliseconds 350
        }
    } catch { }
}

if (-not $SkipIcon) {
    # The icon generator uses the Windows .NET Framework drawing stack; invoke
    # Windows PowerShell explicitly so this also works when called from pwsh 7.
    $windowsPowerShell = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
    & $windowsPowerShell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\generate-tray-icon.ps1')
    if ($LASTEXITCODE -ne 0) { throw 'Tray icon generation failed.' }
}
& $compiler /nologo /target:winexe /optimize+ /win32icon:"$icon" /out:"$output" /r:System.dll /r:System.Drawing.dll /r:System.Windows.Forms.dll /r:System.ServiceProcess.dll "$source"
if ($LASTEXITCODE -ne 0) { throw 'Tray manager compilation failed.' }
Write-Host "Built: $output" -ForegroundColor Green
