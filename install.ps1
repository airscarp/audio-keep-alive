[CmdletBinding()]
param(
    [ValidateRange(1, 60)]
    [int]$IntervalMinutes = 2,

    [switch]$Build
)

$ErrorActionPreference = 'Stop'

$taskName = 'Audio Keep Alive'
$installDirectory = Join-Path $env:LOCALAPPDATA 'AudioKeepAlive'
$sourceExecutable = Join-Path $PSScriptRoot 'dist\AudioKeepAlive.exe'
$installedExecutable = Join-Path $installDirectory 'AudioKeepAlive.exe'
$runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$runValueName = 'AudioKeepAlive'

if ($Build -or -not (Test-Path -LiteralPath $sourceExecutable)) {
    & (Join-Path $PSScriptRoot 'build.ps1')
}

Get-Process -Name 'AudioKeepAlive' -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -eq $installedExecutable } |
    Stop-Process -Force

if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
Copy-Item -LiteralPath $sourceExecutable -Destination $installedExecutable -Force
$obsoleteFiles = @('RunHidden.vbs', 'last-launch-error.txt', 'wscript-task-probe.vbs', 'wscript-probe-ok.txt')
foreach ($file in $obsoleteFiles) {
    Remove-Item -LiteralPath (Join-Path $installDirectory $file) -Force -ErrorAction SilentlyContinue
}

$runCommand = "`"$installedExecutable`" --continuous --interval-minutes $IntervalMinutes"
New-Item -Path $runKey -Force | Out-Null
New-ItemProperty -Path $runKey -Name $runValueName -Value $runCommand -PropertyType String -Force | Out-Null

Start-Process -FilePath $installedExecutable -ArgumentList @(
    '--continuous',
    '--interval-minutes',
    $IntervalMinutes
) -WorkingDirectory $installDirectory

Write-Host 'Installed invisible background process with per-user automatic startup.'
Write-Host "Pulse interval: $IntervalMinutes minute(s)"
Write-Host "Installed executable: $installedExecutable"
