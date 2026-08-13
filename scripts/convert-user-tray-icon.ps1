param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
Add-Type -ReferencedAssemblies 'System.Drawing' -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Collections.Generic;

public static class IPGuardUserIcon
{
    private static Bitmap Resize(Bitmap source, int size)
    {
        Bitmap result = new Bitmap(size, size, PixelFormat.Format32bppArgb);
        using (Graphics graphics = Graphics.FromImage(result))
        {
            graphics.Clear(Color.Transparent);
            graphics.CompositingMode = CompositingMode.SourceCopy;
            graphics.CompositingQuality = CompositingQuality.HighQuality;
            graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
            graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
            graphics.SmoothingMode = SmoothingMode.HighQuality;
            float scale = Math.Min((float)size / source.Width, (float)size / source.Height);
            float width = source.Width * scale;
            float height = source.Height * scale;
            graphics.DrawImage(source, new RectangleF((size - width) / 2f, (size - height) / 2f, width, height));
        }
        return result;
    }

    public static void Create(string inputPath, string outputPath)
    {
        int[] sizes = new int[] { 16, 20, 24, 32, 40, 48, 64, 128, 256 };
        List<byte[]> frames = new List<byte[]>();
        using (Bitmap source = new Bitmap(inputPath))
        {
            foreach (int size in sizes)
            {
                using (Bitmap frame = Resize(source, size))
                using (MemoryStream memory = new MemoryStream())
                {
                    frame.Save(memory, ImageFormat.Png);
                    frames.Add(memory.ToArray());
                }
            }
        }
        using (BinaryWriter output = new BinaryWriter(File.Create(outputPath)))
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
            foreach (byte[] frame in frames) output.Write(frame);
        }
    }
}
'@

[IPGuardUserIcon]::Create($InputPath, $OutputPath)
