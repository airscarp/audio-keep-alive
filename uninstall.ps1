[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$taskName = 'Audio Keep Alive'
$installDirectory = Join-Path $env:LOCALAPPDATA 'AudioKeepAlive'
$obsoleteExecutable = Join-Path $installDirectory 'AudioKeepAlive.exe'
$runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'

if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

Get-Process -Name 'AudioKeepAlive' -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -eq $obsoleteExecutable } |
    Stop-Process -Force
Remove-ItemProperty -Path $runKey -Name 'AudioKeepAlive' -ErrorAction SilentlyContinue

if (Test-Path -LiteralPath $installDirectory) {
    Remove-Item -LiteralPath $installDirectory -Recurse -Force
}

Write-Host 'Audio Keep Alive was removed.'
