[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$taskName = 'Audio Keep Alive'
$installDirectory = Join-Path $env:LOCALAPPDATA 'AudioKeepAlive'

if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

if (Test-Path -LiteralPath $installDirectory) {
    Remove-Item -LiteralPath $installDirectory -Recurse -Force
}

Write-Host 'Audio Keep Alive was removed.'
