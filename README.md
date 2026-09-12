# Audio Keep Alive

Audio Keep Alive is a lightweight, open-source Windows utility that prevents Bluetooth speakers, headphones, soundbars, USB DACs, and audio interfaces from sleeping or entering automatic standby during quiet periods.

It runs as an invisible, low-resource process and plays a one-second, near-silent PCM pulse at a regular interval. Between pulses it sleeps without consuming CPU time.

## Features

- Keeps the Windows Bluetooth audio stream active during silence.
- Prevents supported speakers, headphones, and soundbars from auto-sleeping.
- Runs invisibly with no terminal window, tray icon, service, or driver.
- Starts automatically when the Windows user signs in.
- Uses approximately 2 MB of private memory and no measurable CPU while idle.
- Works entirely offline with no telemetry or network access.

## Why this approach?

Some devices treat digital silence as inactivity. Audio Keep Alive generates a real but extremely low-level signal (approximately `-81 dBFS`) so the Windows audio path remains active without producing noticeable sound under normal listening conditions.

The utility:

- uses no network connection;
- collects no telemetry;
- installs no service, scheduled task, or driver;
- uses only Windows components;
- never opens a terminal window;
- starts automatically when the user signs in;
- catches playback failures and retries on the next interval.

The executable is a native x64 Win32 application. It does not load .NET, Electron, or another application runtime.

## Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1
- An x64 processor

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

1. Uses the prebuilt native executable included in `dist`.
2. Copies the executable to `%LOCALAPPDATA%\AudioKeepAlive`.
3. Adds a per-user startup entry under `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`.
4. Starts the invisible process immediately.

Windows starts the process again whenever the user signs in. A named mutex prevents duplicate instances.

## Check status

```powershell
.\status.ps1
```

The status output reports installation, automatic startup, process state, process ID, and working-set memory. If playback fails, the executable stores the most recent exception in `%LOCALAPPDATA%\AudioKeepAlive\last-error.txt`. Successful pulses do not write to disk.

## Uninstall

```powershell
.\uninstall.ps1
```

This removes the scheduled task and the installed executable. The repository remains untouched.

## Build only

Building requires Visual Studio 2022 Build Tools with the **Desktop development with C++** workload:

```powershell
.\build.ps1
```

The output is written to `dist\AudioKeepAlive.exe`. To rebuild during installation:

```powershell
.\install.ps1 -Build
```

The repository includes the prebuilt x64 executable so target computers do not need a compiler. The binary is reproducible from `src\AudioKeepAlive.cpp`.

## How it works

The executable builds a mono, 16-bit, 44.1 kHz PCM stream in memory. The stream contains a one-second 440 Hz sine wave at an amplitude of 3 out of 32,767, with a ten-millisecond fade at both ends to prevent clicks. The native Windows `waveOut` API sends it to the current default audio output.

The executable is compiled as a Windows GUI application, so it never allocates a console window. In continuous mode it sleeps between pulses, handles audio failures, and continues retrying. The single process remains in memory to avoid repeated process launches and terminal flashes.

On the development machine, the native process used approximately 1.9 MB of private memory, an 11.8 MB working set including shared Windows libraries, and no measurable CPU time during a three-second idle sample. Actual figures vary by Windows version.

## Troubleshooting

### The Bluetooth speaker still goes to sleep

Install again with a shorter interval:

```powershell
.\install.ps1 -IntervalMinutes 1
```

Also confirm that the speaker is the current default Windows audio output.

### Windows SmartScreen warns about the executable

The included executable is not code-signed, so SmartScreen may show a reputation warning. You can inspect `src\AudioKeepAlive.cpp` and build the executable locally with `.\build.ps1` before installation.

### The device disconnected

Audio Keep Alive prevents idle standby by keeping an existing audio stream active. It does not pair, connect, or reconnect Bluetooth devices.

## Limitations

- Audio is sent to the current default Windows output, not a device selected by name.
- A device must already be connected; this utility does not pair or reconnect Bluetooth devices.
- Some hardware may ignore a signal this quiet. Reduce the interval first if the device still sleeps.
- Keeping a battery-powered speaker awake will increase its battery consumption.

## License

Licensed under the MIT License. See [LICENSE](LICENSE).
