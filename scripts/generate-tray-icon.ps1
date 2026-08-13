param(
    [string]$OutputPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'assets\ip-guard-ai.ico')
)

$ErrorActionPreference = 'Stop'
Add-Type -ReferencedAssemblies 'System.Drawing' -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Collections.Generic;

public static class IPGuardSimpleIcon
{
    private static void DrawIcon(Graphics g, int size)
    {
        float s = size / 256f;
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.AntiAliasGridFit;
        g.Clear(Color.Transparent);

        using (var halo = new SolidBrush(Color.FromArgb(75, 42, 214, 255)))
        using (var background = new SolidBrush(Color.FromArgb(255, 10, 30, 78)))
        using (var rim = new Pen(Color.FromArgb(255, 83, 225, 255), 12 * s))
        using (var letters = new SolidBrush(Color.White))
        using (var spark = new SolidBrush(Color.FromArgb(255, 102, 239, 255)))
        using (var font = new Font("Segoe UI", 108 * s, FontStyle.Bold, GraphicsUnit.Pixel))
        {
            g.FillEllipse(halo, 14*s, 14*s, 228*s, 228*s);
            g.FillEllipse(background, 24*s, 24*s, 208*s, 208*s);
            g.DrawEllipse(rim, 24*s, 24*s, 208*s, 208*s);

            using (var format = new StringFormat())
            {
                format.Alignment = StringAlignment.Center;
                format.LineAlignment = StringAlignment.Center;
                g.DrawString("AI", font, letters, new RectangleF(27*s, 30*s, 202*s, 185*s), format);
            }

            PointF[] star = new PointF[] {
                new PointF(206*s, 38*s), new PointF(213*s, 55*s), new PointF(230*s, 62*s),
                new PointF(213*s, 69*s), new PointF(206*s, 86*s), new PointF(199*s, 69*s),
                new PointF(182*s, 62*s), new PointF(199*s, 55*s)
            };
            g.FillPolygon(spark, star);
        }
    }

    public static void Create(string outputPath)
    {
        int[] sizes = new int[] { 16, 20, 24, 32, 40, 48, 64, 128, 256 };
        var frames = new List<byte[]>();
        foreach (var size in sizes)
        {
            using (var bitmap = new Bitmap(size, size, PixelFormat.Format32bppArgb))
            using (var graphics = Graphics.FromImage(bitmap))
            using (var memory = new MemoryStream())
            {
                DrawIcon(graphics, size);
                bitmap.Save(memory, ImageFormat.Png);
                frames.Add(memory.ToArray());
            }
        }
        using (var output = new BinaryWriter(File.Create(outputPath)))
        {
            output.Write((ushort)0); output.Write((ushort)1); output.Write((ushort)frames.Count);
            int offset = 6 + (16 * frames.Count);
            for (int i = 0; i < sizes.Length; i++)
            {
                int size = sizes[i];
                output.Write((byte)(size == 256 ? 0 : size));
                output.Write((byte)(size == 256 ? 0 : size));
                output.Write((byte)0); output.Write((byte)0);
                output.Write((ushort)1); output.Write((ushort)32);
                output.Write(frames[i].Length); output.Write(offset);
                offset += frames[i].Length;
            }
            foreach (var frame in frames) { output.Write(frame); }
        }
    }
}
'@

[IPGuardSimpleIcon]::Create($OutputPath)
