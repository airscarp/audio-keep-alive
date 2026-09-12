[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$taskName = 'Audio Keep Alive'
$installDirectory = Join-Path $env:LOCALAPPDATA 'AudioKeepAlive'
$installedExecutable = Join-Path $installDirectory 'AudioKeepAlive.exe'
$runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$runValueName = 'AudioKeepAlive'

Remove-ItemProperty -Path $runKey -Name $runValueName -ErrorAction SilentlyContinue

Get-Process -Name 'AudioKeepAlive' -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -eq $installedExecutable } |
    Stop-Process -Force

if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

if (Test-Path -LiteralPath $installDirectory) {
    Remove-Item -LiteralPath $installDirectory -Recurse -Force
}

Write-Host 'Audio Keep Alive was removed.'
