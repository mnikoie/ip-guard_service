# IP Guard desktop alert. Runs only in the signed-in user's session.
# It reads the service's shared status file and never controls processes itself.

param(
    [string]$StatusFile = 'C:\ProgramData\IPGuardService\status.json'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$appDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = 'C:\ProgramData\IPGuardService\overlay.pid'
$fontCollection = New-Object System.Drawing.Text.PrivateFontCollection
$regularFontPath = Join-Path $appDirectory 'Vazirmatn-Regular.ttf'
$boldFontPath = Join-Path $appDirectory 'Vazirmatn-Bold.ttf'

try {
    if (Test-Path -LiteralPath $regularFontPath) { [void]$fontCollection.AddFontFile($regularFontPath) }
    if (Test-Path -LiteralPath $boldFontPath) { [void]$fontCollection.AddFontFile($boldFontPath) }
} catch {
    # The UI remains usable with Tahoma if a font file was damaged.
}

if ($fontCollection.Families.Count -gt 0) {
    $fontFamily = $fontCollection.Families[0]
} else {
    $fontFamily = New-Object System.Drawing.FontFamily('Tahoma')
}

$fontTitle = New-Object System.Drawing.Font($fontFamily, 18, [System.Drawing.FontStyle]::Bold)
$fontBody = New-Object System.Drawing.Font($fontFamily, 11, [System.Drawing.FontStyle]::Regular)
$fontMeta = New-Object System.Drawing.Font($fontFamily, 9.5, [System.Drawing.FontStyle]::Regular)
$fontMono = New-Object System.Drawing.Font('Consolas', 11, [System.Drawing.FontStyle]::Bold)

$form = New-Object System.Windows.Forms.Form
$form.Text = 'IP Guard Alert'
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.ShowInTaskbar = $false
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(145, 27, 38)
$form.RightToLeft = [System.Windows.Forms.RightToLeft]::Yes
$form.RightToLeftLayout = $true
$form.Opacity = 0
$form.Location = New-Object System.Drawing.Point(-32000, -32000)

$root = New-Object System.Windows.Forms.Panel
$root.Dock = [System.Windows.Forms.DockStyle]::Fill
$root.BackColor = [System.Drawing.Color]::FromArgb(151, 28, 41)
$form.Controls.Add($root)

$accent = New-Object System.Windows.Forms.Panel
$accent.Dock = [System.Windows.Forms.DockStyle]::Bottom
$accent.Height = 4
$accent.BackColor = [System.Drawing.Color]::FromArgb(247, 195, 77)
$root.Controls.Add($accent)

$icon = New-Object System.Windows.Forms.Label
$icon.Text = '!'
$icon.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$icon.Font = New-Object System.Drawing.Font('Tahoma', 27, [System.Drawing.FontStyle]::Bold)
$icon.ForeColor = [System.Drawing.Color]::FromArgb(117, 20, 30)
$icon.BackColor = [System.Drawing.Color]::FromArgb(255, 213, 104)
$icon.AutoSize = $false
$icon.Size = New-Object System.Drawing.Size(47, 47)
$icon.Location = New-Object System.Drawing.Point(26, 15)
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
$reason.Font = $fontMeta
$reason.ForeColor = [System.Drawing.Color]::FromArgb(255, 230, 182)
$reason.AutoSize = $false
$reason.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$reason.RightToLeft = [System.Windows.Forms.RightToLeft]::Yes
$root.Controls.Add($reason)

$infoBox = New-Object System.Windows.Forms.Panel
$infoBox.BackColor = [System.Drawing.Color]::FromArgb(108, 20, 30)
$root.Controls.Add($infoBox)

$ipLabel = New-Object System.Windows.Forms.Label
$ipLabel.Text = 'IP  —'
$ipLabel.Font = $fontMono
$ipLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 246, 224)
$ipLabel.AutoSize = $false
$ipLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$ipLabel.RightToLeft = [System.Windows.Forms.RightToLeft]::No
$infoBox.Controls.Add($ipLabel)

$countryLabel = New-Object System.Windows.Forms.Label
$countryLabel.Text = 'COUNTRY  UNKNOWN'
$countryLabel.Font = $fontMono
$countryLabel.ForeColor = [System.Drawing.Color]::FromArgb(247, 195, 77)
$countryLabel.AutoSize = $false
$countryLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$countryLabel.RightToLeft = [System.Windows.Forms.RightToLeft]::No
$infoBox.Controls.Add($countryLabel)

function Set-Layout {
    $screenBounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $form.Size = New-Object System.Drawing.Size($screenBounds.Width, 80)
    $form.Location = New-Object System.Drawing.Point($screenBounds.Left, $screenBounds.Top)

    $infoBox.SetBounds(24, 15, 360, 47)
    $ipLabel.SetBounds(8, 3, 172, 40)
    $countryLabel.SetBounds(180, 3, 172, 40)
    $icon.SetBounds($form.ClientSize.Width - 74, 15, 47, 47)
    $title.SetBounds(410, 13, $form.ClientSize.Width - 510, 31)
    $reason.SetBounds(410, 43, $form.ClientSize.Width - 510, 20)
}

function Get-Status {
    try {
        if (-not (Test-Path -LiteralPath $StatusFile)) { return $null }
        return (Get-Content -LiteralPath $StatusFile -Raw -Encoding UTF8 | ConvertFrom-Json)
    } catch {
        return $null
    }
}

function Show-Alert([object]$status) {
    $ip = if ($status.ip) { [string]$status.ip } else { 'UNKNOWN' }
    $country = if ($status.countryCode) { [string]$status.countryCode } else { 'UNKNOWN' }
    $ipLabel.Text = "IP  $ip"
    $countryLabel.Text = "COUNTRY  $country"
    $reason.Text = if ($status.reason) { [string]$status.reason } else { 'آی‌پی عمومی در فهرست امن تأیید نشده است.' }
    Set-Layout
    $form.Opacity = 1
    if (-not $form.Visible) { $form.Show() }
    $form.TopMost = $false
    $form.TopMost = $true
    $form.BringToFront()
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
    $fontTitle.Dispose(); $fontBody.Dispose(); $fontMeta.Dispose(); $fontMono.Dispose(); $fontCollection.Dispose()
})

Set-Layout
[System.Windows.Forms.Application]::Run($form)
