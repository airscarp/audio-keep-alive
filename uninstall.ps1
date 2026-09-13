[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$taskName = 'Audio Keep Alive'
$installDirectory = Join-Path $env:ProgramData 'AudioKeepAlive'
$legacyInstallDirectory = Join-Path $env:LOCALAPPDATA 'AudioKeepAlive'
$installedExecutable = Join-Path $installDirectory 'AudioKeepAlive.exe'
$runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'

if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

Get-Process -Name 'AudioKeepAlive' -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Path -eq $installedExecutable -or
        $_.Path -eq (Join-Path $legacyInstallDirectory 'AudioKeepAlive.exe')
    } |
    Stop-Process -Force
Remove-ItemProperty -Path $runKey -Name 'AudioKeepAlive' -ErrorAction SilentlyContinue

if (Test-Path -LiteralPath $installDirectory) {
    Remove-Item -LiteralPath $installDirectory -Recurse -Force
}
if (Test-Path -LiteralPath $legacyInstallDirectory) {
    Remove-Item -LiteralPath $legacyInstallDirectory -Recurse -Force
}

Write-Host 'Audio Keep Alive was removed.'
