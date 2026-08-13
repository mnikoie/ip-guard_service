param(
    [string]$PersianOutputPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'docs\images\quick-start-fa.png'),
    [string]$EnglishOutputPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'docs\images\quick-start-en.png')
)

$ErrorActionPreference = 'Stop'
Add-Type -ReferencedAssemblies 'System.Drawing' -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Drawing.Text;

public static class IPGuardInstallGuide
{
    private static GraphicsPath RoundedRect(float x, float y, float width, float height, float radius)
    {
        GraphicsPath path = new GraphicsPath();
        path.AddArc(x, y, radius, radius, 180, 90);
        path.AddArc(x + width - radius, y, radius, radius, 270, 90);
        path.AddArc(x + width - radius, y + height - radius, radius, radius, 0, 90);
        path.AddArc(x, y + height - radius, radius, radius, 90, 90);
        path.CloseFigure();
        return path;
    }

    private static void Text(Graphics g, string value, Font font, Brush brush, RectangleF bounds, StringAlignment alignment, bool rtl)
    {
        using (StringFormat format = new StringFormat())
        {
            format.Alignment = alignment;
            format.LineAlignment = StringAlignment.Center;
            format.Trimming = StringTrimming.EllipsisCharacter;
            if (rtl) { format.FormatFlags = StringFormatFlags.DirectionRightToLeft; }
            g.DrawString(value, font, brush, bounds, format);
        }
    }

    private static void Card(Graphics g, FontFamily family, int x, int y, int number, string title, string detail, string command, Color accent, bool rtl)
    {
        const int W = 830, H = 290;
        using (GraphicsPath card = RoundedRect(x, y, W, H, 34))
        using (SolidBrush cardBrush = new SolidBrush(Color.FromArgb(255, 21, 33, 58)))
        using (SolidBrush accentBrush = new SolidBrush(accent))
        using (SolidBrush dark = new SolidBrush(Color.FromArgb(255, 11, 23, 45)))
        using (SolidBrush white = new SolidBrush(Color.White))
        using (SolidBrush muted = new SolidBrush(Color.FromArgb(255, 194, 210, 231)))
        using (SolidBrush cyan = new SolidBrush(Color.FromArgb(255, 109, 229, 255)))
        using (Font numberFont = new Font(family, 25, FontStyle.Bold))
        using (Font titleFont = new Font(family, 26, FontStyle.Bold))
        using (Font detailFont = new Font(family, 16.5f, FontStyle.Regular))
        using (Font codeFont = new Font("Consolas", 17, FontStyle.Bold))
        {
            g.FillPath(cardBrush, card);
            int accentX = rtl ? x + 28 : x + W - 38;
            int numberX = rtl ? x + W - 118 : x + 44;
            int textX = rtl ? x + 125 : x + 150;
            int textWidth = rtl ? W - 205 : W - 205;
            g.FillRectangle(accentBrush, accentX, y + 28, 10, 234);
            g.FillEllipse(accentBrush, numberX, y + 46, 74, 74);
            Text(g, number.ToString(), numberFont, dark, new RectangleF(numberX, y + 46, 74, 74), StringAlignment.Center, false);
            Text(g, title, titleFont, white, new RectangleF(textX, y + 44, textWidth, 58), rtl ? StringAlignment.Far : StringAlignment.Near, rtl);
            Text(g, detail, detailFont, muted, new RectangleF(textX, y + 118, textWidth, 60), rtl ? StringAlignment.Far : StringAlignment.Near, rtl);
            using (GraphicsPath chip = RoundedRect(x + 150, y + 204, 530, 52, 14))
            {
                g.FillPath(dark, chip);
                Text(g, command, codeFont, cyan, new RectangleF(x + 170, y + 204, 490, 52), StringAlignment.Center, false);
            }
        }
    }

    private static void Header(Graphics g, FontFamily family, string titleValue, string subtitleValue, bool rtl)
    {
        using (SolidBrush white = new SolidBrush(Color.White))
        using (SolidBrush cyan = new SolidBrush(Color.FromArgb(255, 100, 230, 255)))
        using (Font title = new Font(family, 40, FontStyle.Bold))
        using (Font subtitle = new Font(family, 20, FontStyle.Regular))
        {
            Text(g, titleValue, title, white, new RectangleF(90, 54, 1740, 72), StringAlignment.Center, rtl);
            Text(g, subtitleValue, subtitle, cyan, new RectangleF(90, 136, 1740, 42), StringAlignment.Center, rtl);
        }
    }

    private static Bitmap BaseCanvas()
    {
        Bitmap bitmap = new Bitmap(1920, 1080, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bitmap))
        using (LinearGradientBrush background = new LinearGradientBrush(new Rectangle(0, 0, 1920, 1080), Color.FromArgb(255, 8, 17, 35), Color.FromArgb(255, 20, 42, 82), 25f))
        {
            g.FillRectangle(background, 0, 0, bitmap.Width, bitmap.Height);
        }
        return bitmap;
    }

    public static void CreatePersian(string outputPath, string fontPath)
    {
        PrivateFontCollection fonts = new PrivateFontCollection(); fonts.AddFontFile(fontPath);
        FontFamily family = fonts.Families[0];
        using (Bitmap bitmap = BaseCanvas())
        using (Graphics g = Graphics.FromImage(bitmap))
        using (SolidBrush muted = new SolidBrush(Color.FromArgb(255, 184, 205, 232)))
        using (SolidBrush footer = new SolidBrush(Color.FromArgb(255, 111, 173, 219)))
        using (Font footerFont = new Font(family, 16, FontStyle.Regular))
        {
            g.SmoothingMode = SmoothingMode.AntiAlias; g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
            Header(g, family, "راهنمای تصویری نصب و اجرای IP Guard", "چهار مرحلهٔ کوتاه برای فعال‌سازی سرویس، هشدار و منوی مدیریت", true);
            // Persian reading order: top-right, top-left, bottom-right, bottom-left.
            Card(g, family, 990, 225, 1, "وابستگی‌ها را نصب کنید", "فایل را اجرا کنید و تا پایان نصب npm صبر کنید.", "1-install-dependencies.bat", Color.FromArgb(255, 85, 224, 187), true);
            Card(g, family, 100, 225, 2, "سرویس را با Administrator نصب کنید", "روی فایل راست‌کلیک کنید و Run as administrator را بزنید.", "2-install-service.bat", Color.FromArgb(255, 112, 193, 255), true);
            Card(g, family, 990, 565, 3, "هشدار دسکتاپ را فعال کنید", "نوار هشدار فارسی برای کاربر فعلی فعال می‌شود.", "install-overlay.bat", Color.FromArgb(255, 191, 133, 255), true);
            Card(g, family, 100, 565, 4, "منوی آیکون AI را فعال کنید", "روی آیکون کنار ساعت راست‌کلیک کنید و سرویس را مدیریت کنید.", "install-tray-manager.bat", Color.FromArgb(255, 255, 194, 90), true);
            Text(g, "نکته: بعد از هر تغییر در config.json، از منوی آیکون گزینهٔ «راه‌اندازی مجدد سرویس» را انتخاب کنید.", footerFont, muted, new RectangleF(100, 932, 1720, 50), StringAlignment.Center, true);
            Text(g, "IP Guard Service  •  Windows 10/11  •  Node.js 18+", footerFont, footer, new RectangleF(100, 1000, 1720, 28), StringAlignment.Center, false);
            bitmap.Save(outputPath, ImageFormat.Png);
        }
        fonts.Dispose();
    }

    public static void CreateEnglish(string outputPath, string fontPath)
    {
        PrivateFontCollection fonts = new PrivateFontCollection(); fonts.AddFontFile(fontPath);
        FontFamily family = fonts.Families[0];
        using (Bitmap bitmap = BaseCanvas())
        using (Graphics g = Graphics.FromImage(bitmap))
        using (SolidBrush muted = new SolidBrush(Color.FromArgb(255, 184, 205, 232)))
        using (SolidBrush footer = new SolidBrush(Color.FromArgb(255, 111, 173, 219)))
        using (Font footerFont = new Font(family, 16, FontStyle.Regular))
        {
            g.SmoothingMode = SmoothingMode.AntiAlias; g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
            Header(g, family, "IP Guard Installation Quick Start", "Four short steps to enable the service, alert, and control menu", false);
            // English reading order: top-left, top-right, bottom-left, bottom-right.
            Card(g, family, 100, 225, 1, "Install dependencies", "Run the file and wait for npm installation to finish.", "1-install-dependencies.bat", Color.FromArgb(255, 85, 224, 187), false);
            Card(g, family, 990, 225, 2, "Install the Windows service", "Right-click the file and choose Run as administrator.", "2-install-service.bat", Color.FromArgb(255, 112, 193, 255), false);
            Card(g, family, 100, 565, 3, "Enable the desktop alert", "This enables the Persian warning banner for the current user.", "install-overlay.bat", Color.FromArgb(255, 191, 133, 255), false);
            Card(g, family, 990, 565, 4, "Enable the AI tray menu", "Right-click the icon beside the clock to manage the service.", "install-tray-manager.bat", Color.FromArgb(255, 255, 194, 90), false);
            Text(g, "Tip: after any config.json change, choose Restart service from the tray menu.", footerFont, muted, new RectangleF(100, 932, 1720, 50), StringAlignment.Center, false);
            Text(g, "IP Guard Service  •  Windows 10/11  •  Node.js 18+", footerFont, footer, new RectangleF(100, 1000, 1720, 28), StringAlignment.Center, false);
            bitmap.Save(outputPath, ImageFormat.Png);
        }
        fonts.Dispose();
    }
}
'@

$projectRoot = Split-Path -Parent $PSScriptRoot
$fontPath = Join-Path $projectRoot 'Vazirmatn-Regular.ttf'
if (-not (Test-Path -LiteralPath $fontPath)) { throw "Vazirmatn font was not found: $fontPath" }
foreach ($path in @($PersianOutputPath, $EnglishOutputPath)) {
    $directory = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $directory)) { New-Item -ItemType Directory -Path $directory -Force | Out-Null }
}
[IPGuardInstallGuide]::CreatePersian($PersianOutputPath, $fontPath)
[IPGuardInstallGuide]::CreateEnglish($EnglishOutputPath, $fontPath)
