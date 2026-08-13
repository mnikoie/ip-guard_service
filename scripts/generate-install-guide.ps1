param(
    [string]$OutputPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'docs\images\quick-start-fa.png')
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
            format.FormatFlags = rtl ? StringFormatFlags.DirectionRightToLeft : StringFormatFlags.NoWrap;
            g.DrawString(value, font, brush, bounds, format);
        }
    }

    private static void Card(Graphics g, FontFamily family, int x, int y, int number, string title, string detail, Color accent)
    {
        using (GraphicsPath card = RoundedRect(x, y, 830, 290, 34))
        using (SolidBrush cardBrush = new SolidBrush(Color.FromArgb(255, 21, 33, 58)))
        using (SolidBrush accentBrush = new SolidBrush(accent))
        using (SolidBrush white = new SolidBrush(Color.White))
        using (SolidBrush muted = new SolidBrush(Color.FromArgb(255, 194, 210, 231)))
        using (Font numberFont = new Font(family, 25, FontStyle.Bold))
        using (Font titleFont = new Font(family, 28, FontStyle.Bold))
        using (Font detailFont = new Font(family, 17, FontStyle.Regular))
        using (Font codeFont = new Font("Consolas", 17, FontStyle.Bold))
        {
            g.FillPath(cardBrush, card);
            g.FillRectangle(accentBrush, x + 792, y + 28, 10, 234);
            g.FillEllipse(accentBrush, x + 44, y + 46, 74, 74);
            Text(g, number.ToString(), numberFont, new SolidBrush(Color.FromArgb(255, 11, 23, 45)), new RectangleF(x + 44, y + 46, 74, 74), StringAlignment.Center, false);
            Text(g, title, titleFont, white, new RectangleF(x + 150, y + 44, 600, 58), StringAlignment.Far, true);
            Text(g, detail, detailFont, muted, new RectangleF(x + 150, y + 118, 600, 60), StringAlignment.Far, true);
            string command = number == 1 ? "1-install-dependencies.bat" : number == 2 ? "2-install-service.bat" : number == 3 ? "install-overlay.bat" : "install-tray-manager.bat";
            using (GraphicsPath chip = RoundedRect(x + 150, y + 204, 560, 52, 14))
            using (SolidBrush chipBrush = new SolidBrush(Color.FromArgb(255, 12, 23, 44)))
            {
                g.FillPath(chipBrush, chip);
                Text(g, command, codeFont, new SolidBrush(Color.FromArgb(255, 109, 229, 255)), new RectangleF(x + 170, y + 204, 520, 52), StringAlignment.Center, false);
            }
        }
    }

    public static void Create(string outputPath, string fontPath)
    {
        PrivateFontCollection fonts = new PrivateFontCollection();
        fonts.AddFontFile(fontPath);
        FontFamily family = fonts.Families[0];
        using (Bitmap bitmap = new Bitmap(1920, 1080, PixelFormat.Format32bppArgb))
        using (Graphics g = Graphics.FromImage(bitmap))
        using (LinearGradientBrush background = new LinearGradientBrush(new Rectangle(0, 0, 1920, 1080), Color.FromArgb(255, 8, 17, 35), Color.FromArgb(255, 20, 42, 82), 25f))
        using (SolidBrush white = new SolidBrush(Color.White))
        using (SolidBrush cyan = new SolidBrush(Color.FromArgb(255, 100, 230, 255)))
        using (SolidBrush muted = new SolidBrush(Color.FromArgb(255, 184, 205, 232)))
        using (Font title = new Font(family, 42, FontStyle.Bold))
        using (Font subtitle = new Font(family, 21, FontStyle.Regular))
        using (Font footer = new Font(family, 16, FontStyle.Regular))
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
            g.FillRectangle(background, 0, 0, bitmap.Width, bitmap.Height);
            Text(g, "راهنمای تصویری نصب و اجرای IP Guard", title, white, new RectangleF(90, 54, 1740, 72), StringAlignment.Center, true);
            Text(g, "چهار مرحلهٔ کوتاه برای فعال‌سازی سرویس، هشدار و منوی مدیریت", subtitle, cyan, new RectangleF(90, 136, 1740, 42), StringAlignment.Center, true);
            Card(g, family, 100, 225, 1, "وابستگی‌ها را نصب کنید", "فایل را اجرا کنید و تا پایان نصب npm صبر کنید.", Color.FromArgb(255, 85, 224, 187));
            Card(g, family, 990, 225, 2, "سرویس را با Administrator نصب کنید", "روی فایل راست‌کلیک کنید و Run as administrator را بزنید.", Color.FromArgb(255, 112, 193, 255));
            Card(g, family, 100, 565, 3, "هشدار دسکتاپ را فعال کنید", "این مرحله نوار هشدار فارسی را برای کاربر فعلی فعال می‌کند.", Color.FromArgb(255, 191, 133, 255));
            Card(g, family, 990, 565, 4, "منوی آیکون AI را فعال کنید", "روی آیکون کنار ساعت راست‌کلیک کنید و سرویس را مدیریت کنید.", Color.FromArgb(255, 255, 194, 90));
            Text(g, "نکته: بعد از هر تغییر در config.json، از منوی آیکون گزینهٔ «راه‌اندازی مجدد سرویس» را انتخاب کنید.", footer, muted, new RectangleF(100, 932, 1720, 50), StringAlignment.Center, true);
            Text(g, "IP Guard Service  •  Windows 10/11  •  Node.js 18+", footer, new SolidBrush(Color.FromArgb(255, 111, 173, 219)), new RectangleF(100, 1000, 1720, 28), StringAlignment.Center, false);
            bitmap.Save(outputPath, ImageFormat.Png);
        }
        fonts.Dispose();
    }
}
'@

$fontPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'Vazirmatn-Regular.ttf'
if (-not (Test-Path -LiteralPath $fontPath)) { throw "Vazirmatn font was not found: $fontPath" }
$outputDirectory = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDirectory)) { New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null }
[IPGuardInstallGuide]::Create($OutputPath, $fontPath)
