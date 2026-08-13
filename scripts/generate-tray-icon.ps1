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
        g.Clear(Color.Transparent);

        using (var halo = new SolidBrush(Color.FromArgb(82, 101, 69, 255)))
        using (var background = new SolidBrush(Color.FromArgb(255, 31, 22, 66)))
        using (var rim = new Pen(Color.FromArgb(255, 148, 118, 255), 10 * s))
        using (var petal = new Pen(Color.FromArgb(255, 245, 246, 255), 27 * s))
        using (var core = new SolidBrush(Color.FromArgb(255, 129, 242, 221)))
        {
            g.FillEllipse(halo, 14*s, 14*s, 228*s, 228*s);
            g.FillEllipse(background, 27*s, 27*s, 202*s, 202*s);
            g.DrawEllipse(rim, 27*s, 27*s, 202*s, 202*s);
            petal.StartCap = LineCap.Round;
            petal.EndCap = LineCap.Round;

            // A custom six-petal "neural iris": distinctive enough at 16px,
            // while keeping the visual language of modern AI tools.
            g.TranslateTransform(128*s, 128*s);
            for (int i = 0; i < 6; i++)
            {
                g.DrawBezier(petal,
                    new PointF(0, -12*s),
                    new PointF(32*s, -62*s),
                    new PointF(75*s, -33*s),
                    new PointF(56*s, 4*s));
                g.RotateTransform(60);
            }
            g.ResetTransform();
            g.FillEllipse(core, 113*s, 113*s, 30*s, 30*s);
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
