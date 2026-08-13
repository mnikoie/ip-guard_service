# IP Guard desktop alert. This process runs in the signed-in user's session.
# It only reads the service status and never controls applications itself.

param(
    [string]$StatusFile = 'C:\ProgramData\IPGuardService\status.json'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# A non-activating, click-through window prevents the alert from stealing focus
# or blocking title bars/buttons in other applications.
Add-Type -ReferencedAssemblies 'System.Windows.Forms' -TypeDefinition @'
using System;
using System.Windows.Forms;

public class IPGuardOverlayForm : Form
{
    private const int WS_EX_TRANSPARENT = 0x00000020;
    private const int WS_EX_NOACTIVATE = 0x08000000;

    protected override bool ShowWithoutActivation { get { return true; } }

    protected override CreateParams CreateParams
    {
        get
        {
            CreateParams parameters = base.CreateParams;
            parameters.ExStyle |= WS_EX_TRANSPARENT | WS_EX_NOACTIVATE;
            return parameters;
        }
    }
}
'@

$appDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = 'C:\ProgramData\IPGuardService\overlay.pid'
$fontCollection = New-Object System.Drawing.Text.PrivateFontCollection
$regularFontPath = Join-Path $appDirectory 'Vazirmatn-Regular.ttf'
$boldFontPath = Join-Path $appDirectory 'Vazirmatn-Bold.ttf'

try {
    if (Test-Path -LiteralPath $regularFontPath) { [void]$fontCollection.AddFontFile($regularFontPath) }
    if (Test-Path -LiteralPath $boldFontPath) { [void]$fontCollection.AddFontFile($boldFontPath) }
} catch {
    # Tahoma is used only if local font files are unavailable or invalid.
}

if ($fontCollection.Families.Count -gt 0) {
    $fontFamily = $fontCollection.Families[0]
} else {
    $fontFamily = New-Object System.Drawing.FontFamily('Tahoma')
}

$fontTitle = New-Object System.Drawing.Font($fontFamily, 13.5, [System.Drawing.FontStyle]::Bold)
$fontBody = New-Object System.Drawing.Font($fontFamily, 9.5, [System.Drawing.FontStyle]::Regular)
$fontMeta = New-Object System.Drawing.Font('Consolas', 9.5, [System.Drawing.FontStyle]::Bold)

$form = New-Object IPGuardOverlayForm
$form.Text = 'IP Guard Alert'
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.ShowInTaskbar = $false
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(32, 18, 22)
$form.RightToLeft = [System.Windows.Forms.RightToLeft]::Yes
$form.RightToLeftLayout = $true
$form.Opacity = 0
$form.Location = New-Object System.Drawing.Point(-32000, -32000)

$root = New-Object System.Windows.Forms.Panel
$root.Dock = [System.Windows.Forms.DockStyle]::Fill
$root.BackColor = [System.Drawing.Color]::FromArgb(146, 30, 43)
$root.Padding = New-Object System.Windows.Forms.Padding(15, 12, 15, 12)
$form.Controls.Add($root)

$accent = New-Object System.Windows.Forms.Panel
$accent.Dock = [System.Windows.Forms.DockStyle]::Right
$accent.Width = 5
$accent.BackColor = [System.Drawing.Color]::FromArgb(248, 199, 79)
$root.Controls.Add($accent)

$icon = New-Object System.Windows.Forms.Label
$icon.Text = '!'
$icon.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$icon.Font = New-Object System.Drawing.Font('Tahoma', 19, [System.Drawing.FontStyle]::Bold)
$icon.ForeColor = [System.Drawing.Color]::FromArgb(115, 20, 31)
$icon.BackColor = [System.Drawing.Color]::FromArgb(255, 216, 108)
$icon.AutoSize = $false
$root.Controls.Add($icon)

$title = New-Object System.Windows.Forms.Label
$title.Text = 'دسترسی برنامه‌های محافظت‌شده مسدود شد'
$title.Font = $fontTitle
$title.ForeColor = [System.Drawing.Color]::White
$title.AutoSize = $false
$title.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$title.RightToLeft = [System.Windows.Forms.RightToLeft]::Yes
$root.Controls.Add($title)

$reason = New-Object System.Windows.Forms.Label
$reason.Text = 'آی‌پی عمومی در فهرست امن تأیید نشده است.'
$reason.Font = $fontBody
$reason.ForeColor = [System.Drawing.Color]::FromArgb(255, 231, 187)
$reason.AutoSize = $false
$reason.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$reason.RightToLeft = [System.Windows.Forms.RightToLeft]::Yes
$root.Controls.Add($reason)

$metadata = New-Object System.Windows.Forms.Label
$metadata.Text = 'IP: UNKNOWN   |   COUNTRY: UNKNOWN'
$metadata.Font = $fontMeta
$metadata.ForeColor = [System.Drawing.Color]::FromArgb(255, 246, 224)
$metadata.AutoSize = $false
$metadata.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$metadata.RightToLeft = [System.Windows.Forms.RightToLeft]::No
$root.Controls.Add($metadata)

function Set-Layout {
    $workArea = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $width = [Math]::Min(590, $workArea.Width - 32)
    $height = 92
    $form.Size = New-Object System.Drawing.Size($width, $height)
    $form.Location = New-Object System.Drawing.Point(($workArea.Right - $width - 16), ($workArea.Bottom - $height - 16))

    $icon.SetBounds($width - 63, 22, 34, 34)
    $title.SetBounds(175, 14, $width - 252, 30)
    $reason.SetBounds(175, 46, $width - 252, 24)
    $metadata.SetBounds(18, 23, 145, 39)
}

function Get-Status {
    try {
        if (-not (Test-Path -LiteralPath $StatusFile)) { return $null }
        return Get-Content -LiteralPath $StatusFile -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Get-PersianReason([object]$status) {
    $rawReason = [string]$status.reason
    if ($rawReason -match 'Country is not') {
        return 'کشور آی‌پی در فهرست کشورهای امن نیست.'
    }
    if ($rawReason -match 'lookup failed') {
        return 'امکان تأیید آی‌پی عمومی وجود ندارد؛ محافظت فعال است.'
    }
    return 'آی‌پی عمومی در فهرست امن تأیید نشده است.'
}

function Show-Alert([object]$status) {
    $ip = if ($status.ip) { [string]$status.ip } else { 'UNKNOWN' }
    $country = if ($status.countryCode) { [string]$status.countryCode } else { 'UNKNOWN' }
    $metadata.Text = "IP: $ip`r`nCOUNTRY: $country"
    $reason.Text = Get-PersianReason $status
    Set-Layout
    $form.Opacity = 1
    if (-not $form.Visible) { $form.Show() }
}

function Hide-Alert {
    if ($form.Visible) { $form.Hide() }
    $form.Opacity = 0
}

try {
    $statusDirectory = Split-Path -Parent $pidFile
    if (-not (Test-Path -LiteralPath $statusDirectory)) { New-Item -ItemType Directory -Path $statusDirectory -Force | Out-Null }
    Set-Content -LiteralPath $pidFile -Value $PID -Encoding ASCII -Force
} catch { }

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 300
$timer.Add_Tick({
    $status = Get-Status
    if ($null -ne $status -and $status.state -eq 'UNSAFE') { Show-Alert $status } else { Hide-Alert }
})
$form.Add_Shown({ $form.Hide(); $timer.Start() })
$form.Add_FormClosed({
    $timer.Stop()
    try { Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue } catch { }
    $fontTitle.Dispose(); $fontBody.Dispose(); $fontMeta.Dispose(); $fontCollection.Dispose()
})

Set-Layout
[System.Windows.Forms.Application]::Run($form)
