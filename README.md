# Audio Keep Alive

A tiny, open-source Windows utility that helps prevent Bluetooth speakers, soundbars, headphones, and other audio devices from entering standby.

Windows Task Scheduler launches a short-lived native audio pulse at a fixed interval. No Audio Keep Alive process remains running between pulses.

## Features

- Invisible: no terminal or application window
- Minimal overhead: zero persistent CPU or memory use
- Resilient: every pulse is a fresh process
- Self-recovering: Task Scheduler retries failures and continues future runs
- Device-independent: uses the current Windows default audio output
- Offline and dependency-free after installation
- No telemetry, network access, services, or administrator rights

## How it works

The scheduled task runs the Windows GUI host `rundll32.exe` every two minutes. It loads `AudioKeepAlive.dll`, calls the exported `RunKeepAlive` function, and plays approximately one second of digital silence through the default output device.

Each invocation then exits. If audio playback hangs, the DLL cancels it after three seconds. Task Scheduler also enforces a one-minute execution limit, retries failures up to three times, and starts missed runs when possible.

Because every interval starts a new process, one failed invocation cannot permanently stop later pulses.

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1 or later
- Visual Studio Build Tools with the C++ toolchain only when building from source

The checked-in release DLL lets normal users install without a compiler.

## Install

Open PowerShell in the repository directory:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
```

The installer:

1. Copies `dist\AudioKeepAlive.dll` to `%LOCALAPPDATA%\AudioKeepAlive`.
2. Registers the hidden `Audio Keep Alive` scheduled task.
3. Configures a pulse every two minutes.
4. Removes the obsolete persistent-process installation.
5. Starts one immediate verification pulse.

Choose another interval:

```powershell
.\install.ps1 -IntervalMinutes 5
```

## Status

```powershell
.\status.ps1 | Format-List
```

Expected healthy state:

- `Installed: True`
- `TaskRegistered: True`
- `TaskState: Ready` between pulses
- `LastTaskResult: 0` after a successful pulse
- `LegacyRunEntry:` empty

No persistent Audio Keep Alive process is expected.

## Uninstall

```powershell
.\uninstall.ps1
```

This removes the scheduled task, installed files, and any legacy startup entry.

## Build from source

```powershell
.\build.ps1
```

Output:

```text
dist\AudioKeepAlive.dll
```

Or rebuild during installation:

```powershell
.\install.ps1 -Build
```

## Security and privacy

The project is intentionally small and auditable. It:

- generates silence in memory;
- writes only installation files and `last-error.txt` when playback fails;
- registers one per-user scheduled task;
- makes no network requests;
- collects no data.

The task action uses the Windows system binary `%WINDIR%\System32\rundll32.exe` and the locally installed project DLL.

## Limitations

- Windows sends the pulse to the current default audio output.
- Some devices detect true digital silence and may still enter standby.
- The task runs only while the installing user has an interactive session, because Windows audio is session-scoped.
- This keeps an already connected audio path active; it does not reconnect a powered-off Bluetooth device.

## License

MIT. See [LICENSE](LICENSE).
