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
    private static GraphicsPath RoundedRect(float x, float y, float width, float height, float radius)
    {
        var path = new GraphicsPath();
        path.AddArc(x, y, radius, radius, 180, 90);
        path.AddArc(x + width - radius, y, radius, radius, 270, 90);
        path.AddArc(x + width - radius, y + height - radius, radius, radius, 0, 90);
        path.AddArc(x, y + height - radius, radius, radius, 90, 90);
        path.CloseFigure();
        return path;
    }

    private static void DrawIcon(Graphics g, int size)
    {
        float s = size / 256f;
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        g.Clear(Color.Transparent);

        using (var shadow = new SolidBrush(Color.FromArgb(65, 2, 12, 38)))
        using (var body = new SolidBrush(Color.FromArgb(255, 20, 39, 97)))
        using (var rim = new Pen(Color.FromArgb(255, 66, 215, 255), 12 * s))
        using (var circuit = new Pen(Color.FromArgb(255, 180, 246, 255), 9 * s))
        using (var core = new SolidBrush(Color.FromArgb(255, 80, 229, 255)))
        using (var node = new SolidBrush(Color.White))
        {
            var shield = new PointF[] {
                new PointF(128*s, 19*s), new PointF(219*s, 53*s), new PointF(205*s, 156*s),
                new PointF(128*s, 230*s), new PointF(51*s, 156*s), new PointF(37*s, 53*s)
            };
            var shadowShield = new PointF[] {
                new PointF(134*s, 28*s), new PointF(225*s, 62*s), new PointF(211*s, 165*s),
                new PointF(134*s, 239*s), new PointF(57*s, 165*s), new PointF(43*s, 62*s)
            };
            g.FillPolygon(shadow, shadowShield);
            g.FillPolygon(body, shield);
            g.DrawPolygon(rim, shield);

            float cx = 128*s, cy = 128*s;
            float r = 24*s;
            g.FillEllipse(core, cx-r, cy-r, r*2, r*2);
            var points = new PointF[] {
                new PointF(86*s, 88*s), new PointF(170*s, 88*s),
                new PointF(78*s, 158*s), new PointF(178*s, 158*s)
            };
            foreach (var point in points)
            {
                g.DrawLine(circuit, cx, cy, point.X, point.Y);
                g.FillEllipse(node, point.X - 11*s, point.Y - 11*s, 22*s, 22*s);
            }
            g.FillEllipse(node, cx - 7*s, cy - 7*s, 14*s, 14*s);
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
