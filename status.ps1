[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$taskName = 'Audio Keep Alive'

$task = Get-ScheduledTask -TaskName $taskName
$info = Get-ScheduledTaskInfo -TaskName $taskName

[pscustomobject]@{
    TaskName = $taskName
    Enabled = $task.Settings.Enabled
    State = $task.State
    LastRunTime = $info.LastRunTime
    LastTaskResult = $info.LastTaskResult
    NextRunTime = $info.NextRunTime
    Interval = $task.Triggers[0].Repetition.Interval
} | Format-List
