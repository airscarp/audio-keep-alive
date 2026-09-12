[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$installedExecutable = Join-Path $env:LOCALAPPDATA 'AudioKeepAlive\AudioKeepAlive.exe'
$runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$runValueName = 'AudioKeepAlive'
$errorFile = Join-Path $env:LOCALAPPDATA 'AudioKeepAlive\last-error.txt'

$process = Get-Process -Name 'AudioKeepAlive' -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -eq $installedExecutable } |
    Select-Object -First 1
$runCommand = Get-ItemPropertyValue -Path $runKey -Name $runValueName -ErrorAction SilentlyContinue

[pscustomobject]@{
    Installed = Test-Path -LiteralPath $installedExecutable
    AutoStartRegistered = [bool]$runCommand
    Running = [bool]$process
    ProcessId = if ($process) { $process.Id } else { $null }
    WorkingSetMB = if ($process) { [math]::Round($process.WorkingSet64 / 1MB, 2) } else { $null }
    AutoStartCommand = $runCommand
    LastErrorFile = if (Test-Path -LiteralPath $errorFile) { $errorFile } else { $null }
} | Format-List
