param(
    [switch]$SkipIcon
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$source = Join-Path $root 'tray-manager.cs'
$output = Join-Path $root 'IP Guard Tray.exe'
$icon = Join-Path $root 'assets\ip-guard-ai.ico'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) {
    $compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'
}
if (-not (Test-Path -LiteralPath $compiler)) { throw 'The .NET Framework C# compiler was not found.' }

# A running copy locks the executable on Windows. Identify the exact executable
# path instead of trusting a possibly stale PID file, then wait for it to exit.
$runningCopies = @(Get-Process -Name 'IP Guard Tray' -ErrorAction SilentlyContinue | Where-Object {
    try { $_.Path -eq $output } catch { $false }
})
foreach ($runningCopy in $runningCopies) {
    Stop-Process -Id $runningCopy.Id -Force -ErrorAction Stop
    Wait-Process -Id $runningCopy.Id -Timeout 5 -ErrorAction SilentlyContinue
}
if (Get-Process -Name 'IP Guard Tray' -ErrorAction SilentlyContinue | Where-Object {
    try { $_.Path -eq $output } catch { $false }
}) {
    throw 'The running IP Guard Tray.exe could not be stopped for rebuilding.'
}

if (-not $SkipIcon) {
    # The icon generator uses the Windows .NET Framework drawing stack; invoke
    # Windows PowerShell explicitly so this also works when called from pwsh 7.
    $windowsPowerShell = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $userIcon = Join-Path $root 'assets\ip-guard-user.png'
    if (Test-Path -LiteralPath $userIcon) {
        & $windowsPowerShell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\convert-user-tray-icon.ps1') -InputPath $userIcon -OutputPath $icon
    } else {
        & $windowsPowerShell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\generate-tray-icon.ps1')
    }
    if ($LASTEXITCODE -ne 0) { throw 'Tray icon generation failed.' }
}
& $compiler /nologo /target:winexe /optimize+ /win32icon:"$icon" /out:"$output" /r:System.dll /r:System.Drawing.dll /r:System.Windows.Forms.dll /r:System.ServiceProcess.dll "$source"
if ($LASTEXITCODE -ne 0) { throw 'Tray manager compilation failed.' }
Write-Host "Built: $output" -ForegroundColor Green
