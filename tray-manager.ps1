# IP Guard tray manager. Runs in the signed-in user's session and dispatches
# the existing maintenance scripts; it never changes service policy itself.

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$appDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$runtimeDirectory = Join-Path $env:LOCALAPPDATA 'IPGuardService'
$pidFile = Join-Path $runtimeDirectory 'tray-manager.pid'
$mutexCreated = $false
$mutex = New-Object System.Threading.Mutex($true, 'Local\IPGuardTrayManager', [ref]$mutexCreated)
if (-not $mutexCreated) { exit 0 }

try {
    if (-not (Test-Path -LiteralPath $runtimeDirectory)) {
        New-Item -ItemType Directory -Path $runtimeDirectory -Force | Out-Null
    }
    Set-Content -LiteralPath $pidFile -Value $PID -Encoding ASCII -Force
} catch { }

$fontCollection = New-Object System.Drawing.Text.PrivateFontCollection
try {
    $fontPath = Join-Path $appDirectory 'Vazirmatn-Regular.ttf'
    if (Test-Path -LiteralPath $fontPath) { [void]$fontCollection.AddFontFile($fontPath) }
} catch { }
$menuFont = if ($fontCollection.Families.Count -gt 0) {
    New-Object System.Drawing.Font($fontCollection.Families[0], 9.5, [System.Drawing.FontStyle]::Regular)
} else {
    New-Object System.Drawing.Font('Tahoma', 9.5, [System.Drawing.FontStyle]::Regular)
}

function Start-Maintenance([string]$fileName, [bool]$requiresAdministrator) {
    $scriptPath = Join-Path $appDirectory $fileName
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        [System.Windows.Forms.MessageBox]::Show("Missing file:`n$scriptPath", 'IP Guard', 'OK', 'Error') | Out-Null
        return
    }

    $startInfo = @{
        FilePath = $env:ComSpec
        ArgumentList = ('/k ""{0}""' -f $scriptPath)
        WorkingDirectory = $appDirectory
    }
    if ($requiresAdministrator) { $startInfo.Verb = 'RunAs' }
    try {
        Start-Process @startInfo | Out-Null
    } catch [System.ComponentModel.Win32Exception] {
        # User cancelling the UAC prompt is expected; do not show a second error.
    } catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'IP Guard', 'OK', 'Error') | Out-Null
    }
}

function Open-Config {
    $configPath = Join-Path $appDirectory 'config.json'
    if (Test-Path -LiteralPath $configPath) {
        Start-Process -FilePath 'notepad.exe' -ArgumentList ('"{0}"' -f $configPath) | Out-Null
    }
}

function Open-ProjectFolder {
    Start-Process -FilePath 'explorer.exe' -ArgumentList ('"{0}"' -f $appDirectory) | Out-Null
}

function Get-GuardState {
    $statusPath = 'C:\ProgramData\IPGuardService\status.json'
    try {
        if (-not (Test-Path -LiteralPath $statusPath)) { return @{ State = 'WAITING'; Detail = 'سرویس هنوز وضعیت نداده است' } }
        $status = Get-Content -LiteralPath $statusPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($status.state -eq 'TRUSTED') {
            return @{ State = 'TRUSTED'; Detail = "امن — $($status.countryCode) | $($status.ip)" }
        }
        return @{ State = 'UNSAFE'; Detail = "محافظت فعال — $($status.countryCode) | $($status.ip)" }
    } catch {
        return @{ State = 'WAITING'; Detail = 'در حال خواندن وضعیت سرویس' }
    }
}

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$menu.Font = $menuFont
$menu.RightToLeft = [System.Windows.Forms.RightToLeft]::Yes
$menu.RenderMode = [System.Windows.Forms.ToolStripRenderMode]::System

$statusItem = New-Object System.Windows.Forms.ToolStripMenuItem('وضعیت: در حال بررسی…')
$statusItem.Enabled = $false
$statusItem.ForeColor = [System.Drawing.Color]::DimGray
[void]$menu.Items.Add($statusItem)
[void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

function Add-Action([string]$text, [scriptblock]$action) {
    $item = New-Object System.Windows.Forms.ToolStripMenuItem($text)
    $item.Add_Click($action)
    [void]$menu.Items.Add($item)
}

Add-Action 'نصب وابستگی‌ها (npm install)' { Start-Maintenance '1-install-dependencies.bat' $false }
Add-Action 'نصب سرویس ویندوز  [Administrator]' { Start-Maintenance '2-install-service.bat' $true }
Add-Action 'توقف و حذف سرویس  [Administrator]' { Start-Maintenance '3-stop-and-uninstall-service.bat' $true }
Add-Action 'راه‌اندازی مجدد سرویس  [Administrator]' { Start-Maintenance '4-restart-service.bat' $true }
[void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
Add-Action 'نمایش وضعیت و لاگ' { Start-Maintenance '5-view-log.bat' $false }
Add-Action 'نصب هشدار روی دسکتاپ' { Start-Maintenance 'install-overlay.bat' $false }
Add-Action 'حذف هشدار دسکتاپ' { Start-Maintenance 'uninstall-overlay.bat' $false }
[void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
Add-Action 'ویرایش تنظیمات' { Open-Config }
Add-Action 'باز کردن پوشهٔ پروژه' { Open-ProjectFolder }
[void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

$exitItem = New-Object System.Windows.Forms.ToolStripMenuItem('خروج از مدیر IP Guard')
$exitItem.Add_Click({ $applicationContext.ExitThread() })
[void]$menu.Items.Add($exitItem)

$trayIcon = New-Object System.Windows.Forms.NotifyIcon
$iconPath = Join-Path $appDirectory 'assets\ip-guard-ai.ico'
try {
    $trayIcon.Icon = New-Object System.Drawing.Icon($iconPath)
} catch {
    # Keep the manager usable if a user removes the project icon file.
    $trayIcon.Icon = [System.Drawing.SystemIcons]::Shield
}
$trayIcon.Text = 'IP Guard — در حال بررسی وضعیت'
$trayIcon.ContextMenuStrip = $menu
$trayIcon.Visible = $true
$trayIcon.Add_DoubleClick({ Start-Maintenance '5-view-log.bat' $false })

function Refresh-TrayState {
    $guardState = Get-GuardState
    $statusItem.Text = "وضعیت: $($guardState.Detail)"
    switch ($guardState.State) {
        'TRUSTED' {
            $statusItem.ForeColor = [System.Drawing.Color]::ForestGreen
            $trayIcon.Text = 'IP Guard — شبکه امن است'
        }
        'UNSAFE' {
            $statusItem.ForeColor = [System.Drawing.Color]::Firebrick
            $trayIcon.Text = 'IP Guard — محافظت فعال است'
        }
        default {
            $statusItem.ForeColor = [System.Drawing.Color]::DarkGoldenrod
            $trayIcon.Text = 'IP Guard — در انتظار وضعیت سرویس'
        }
    }
}

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({ Refresh-TrayState })
$timer.Start()
Refresh-TrayState

$applicationContext = New-Object System.Windows.Forms.ApplicationContext
try {
    [System.Windows.Forms.Application]::Run($applicationContext)
} finally {
    $timer.Stop()
    $trayIcon.Visible = $false
    $trayIcon.Dispose()
    $menuFont.Dispose()
    $fontCollection.Dispose()
    try { Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue } catch { }
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
