[CmdletBinding()]
param()

$taskName = 'Audio Keep Alive'
$installDirectory = Join-Path $env:ProgramData 'AudioKeepAlive'
$legacyInstallDirectory = Join-Path $env:LOCALAPPDATA 'AudioKeepAlive'
$installedExecutable = Join-Path $installDirectory 'AudioKeepAlive.exe'
$errorFile = Join-Path $installDirectory 'last-error.txt'
$runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'

$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
$taskInfo = if ($task) { Get-ScheduledTaskInfo -TaskName $taskName } else { $null }
$action = if ($task) { $task.Actions | Select-Object -First 1 } else { $null }
$trigger = if ($task) { $task.Triggers | Select-Object -First 1 } else { $null }
$legacyRunEntry = Get-ItemPropertyValue -Path $runKey -Name 'AudioKeepAlive' -ErrorAction SilentlyContinue

[pscustomobject]@{
    Installed          = Test-Path -LiteralPath $installedExecutable
    InstalledExecutable = $installedExecutable
    LegacyInstallPresent = Test-Path -LiteralPath $legacyInstallDirectory
    TaskRegistered = $null -ne $task
    TaskState      = if ($task) { $task.State } else { 'Not installed' }
    TaskEnabled    = if ($task) { $task.Settings.Enabled } else { $false }
    RepeatInterval = if ($trigger) { $trigger.Repetition.Interval } else { $null }
    LastRunTime    = if ($taskInfo) { $taskInfo.LastRunTime } else { $null }
    LastTaskResult = if ($taskInfo) { $taskInfo.LastTaskResult } else { $null }
    NextRunTime    = if ($taskInfo) { $taskInfo.NextRunTime } else { $null }
    Action         = if ($action) { "$($action.Execute) $($action.Arguments)" } else { $null }
    LegacyRunEntry = $legacyRunEntry
    LastError      = if (Test-Path -LiteralPath $errorFile) { Get-Content -LiteralPath $errorFile -Raw } else { $null }
}
