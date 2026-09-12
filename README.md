# Audio Keep Alive

Audio Keep Alive is a tiny, open-source Windows utility that prevents Bluetooth speakers, soundbars, USB DACs, and other audio devices from entering standby during quiet periods.

It uses Windows Task Scheduler to play a one-second, near-silent PCM pulse at a regular interval. Nothing remains running between pulses.

## Why this approach?

Some devices treat digital silence as inactivity. Audio Keep Alive generates a real but extremely low-level signal (approximately `-81 dBFS`) so the Windows audio path remains active without producing noticeable sound under normal listening conditions.

The utility:

- uses no network connection;
- collects no telemetry;
- installs no service or driver;
- uses only Windows components;
- exits after every one-second pulse;
- retries automatically on the next interval if an audio device is unavailable.

## Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1
- .NET Framework 4.x, included with supported Windows installations

No administrator privileges or third-party packages are required.

## Install

Open Windows PowerShell in the repository directory and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
```

The default pulse interval is two minutes. To use another interval:

```powershell
.\install.ps1 -IntervalMinutes 5
```

Installation performs these steps:

1. Compiles `src\AudioKeepAlive.cs` with the C# compiler included in .NET Framework.
2. Copies the 4–5 KB executable to `%LOCALAPPDATA%\AudioKeepAlive`.
3. Creates a hidden scheduled task named `Audio Keep Alive`.
4. Runs the first pulse immediately, then repeats it at the configured interval.

The task survives restarts. If Windows misses a run during sleep or shutdown, Task Scheduler resumes it when the user session is available.

## Check status

```powershell
.\status.ps1
```

`LastTaskResult` equal to `0` means the most recent pulse completed successfully.

## Uninstall

```powershell
.\uninstall.ps1
```

This removes the scheduled task and the installed executable. The repository remains untouched.

## Build only

```powershell
.\build.ps1
```

The output is written to `bin\AudioKeepAlive.exe`. Generated binaries are excluded from Git so releases can always be rebuilt from source.

## How it works

The executable builds a mono, 16-bit, 44.1 kHz WAV stream in memory. The stream contains a one-second 440 Hz sine wave at an amplitude of 3 out of 32,767, with a ten-millisecond fade at both ends to prevent clicks. `System.Media.SoundPlayer` sends it to the current default Windows audio output and waits for playback to finish.

Task Scheduler launches each pulse as a fresh process. This avoids a permanent background process and makes failures self-recovering: a failed run cannot stop later scheduled runs.

## Limitations

- Audio is sent to the current default Windows output, not a device selected by name.
- A device must already be connected; this utility does not pair or reconnect Bluetooth devices.
- Some hardware may ignore a signal this quiet. Reduce the interval first if the device still sleeps.
- Keeping a battery-powered speaker awake will increase its battery consumption.
- The installed schedule lasts ten years. Re-running `install.ps1` safely renews it.

## License

Licensed under the MIT License. See [LICENSE](LICENSE).
