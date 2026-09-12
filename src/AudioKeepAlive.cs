using System;
using System.IO;
using System.Media;
using System.Text;

internal static class AudioKeepAlive
{
    private const int SampleRate = 44100;
    private const int DurationMilliseconds = 1000;
    private const double Frequency = 440.0;

    // About -81 dBFS. Non-zero PCM keeps the audio path active while remaining
    // effectively inaudible under normal listening conditions.
    private const short Amplitude = 3;

    [STAThread]
    private static int Main()
    {
        try
        {
            using (var stream = CreatePulse())
            using (var player = new SoundPlayer(stream))
            {
                player.PlaySync();
            }

            return 0;
        }
        catch
        {
            // A missing or disconnected output is temporary. The scheduled task
            // will start a fresh process on its next interval.
            return 1;
        }
    }

    private static MemoryStream CreatePulse()
    {
        int sampleCount = SampleRate * DurationMilliseconds / 1000;
        int dataLength = sampleCount * sizeof(short);
        var stream = new MemoryStream(44 + dataLength);

        using (var writer = new BinaryWriter(stream, Encoding.ASCII, true))
        {
            writer.Write(Encoding.ASCII.GetBytes("RIFF"));
            writer.Write(36 + dataLength);
            writer.Write(Encoding.ASCII.GetBytes("WAVE"));
            writer.Write(Encoding.ASCII.GetBytes("fmt "));
            writer.Write(16);
            writer.Write((short)1);
            writer.Write((short)1);
            writer.Write(SampleRate);
            writer.Write(SampleRate * sizeof(short));
            writer.Write((short)sizeof(short));
            writer.Write((short)16);
            writer.Write(Encoding.ASCII.GetBytes("data"));
            writer.Write(dataLength);

            for (int i = 0; i < sampleCount; i++)
            {
                // Ten-millisecond fade-in/out avoids clicks at pulse boundaries.
                double fade = Math.Min(1.0, Math.Min(i, sampleCount - 1 - i) / 441.0);
                short sample = (short)(Amplitude * fade * Math.Sin(
                    2.0 * Math.PI * Frequency * i / SampleRate));
                writer.Write(sample);
            }
        }

        stream.Position = 0;
        return stream;
    }
}
