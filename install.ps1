[CmdletBinding()]
param(
    [ValidateRange(1, 60)]
    [int]$IntervalMinutes = 2
)

$ErrorActionPreference = 'Stop'

$taskName = 'Audio Keep Alive'
$installDirectory = Join-Path $env:LOCALAPPDATA 'AudioKeepAlive'
$sourceExecutable = Join-Path $PSScriptRoot 'bin\AudioKeepAlive.exe'
$installedExecutable = Join-Path $installDirectory 'AudioKeepAlive.exe'

& (Join-Path $PSScriptRoot 'build.ps1')

New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
Copy-Item -LiteralPath $sourceExecutable -Destination $installedExecutable -Force

# Launching through the built-in PowerShell host is reliable across Windows Task
# Scheduler security contexts. The host exists for only the one-second pulse.
$powerShell = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
$arguments = "-NoProfile -NonInteractive -WindowStyle Hidden -Command `"& '$installedExecutable'; exit `$LASTEXITCODE`""
$action = New-ScheduledTaskAction -Execute $powerShell -Argument $arguments
$trigger = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date).AddMinutes(1) `
    -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) `
    -RepetitionDuration (New-TimeSpan -Days 3650)
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 1) `
    -Hidden

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description 'Keeps the default Windows audio output awake with a one-second near-silent pulse.' `
    -Force | Out-Null

Start-ScheduledTask -TaskName $taskName

Write-Host "Installed scheduled task: $taskName"
Write-Host "Pulse interval: $IntervalMinutes minute(s)"
Write-Host "Installed executable: $installedExecutable"
