[CmdletBinding()]
param(
    [ValidateRange(1, 60)]
    [int]$IntervalMinutes = 2,
    [switch]$Build
)

$ErrorActionPreference = 'Stop'

$taskName = 'Audio Keep Alive'
$installDirectory = Join-Path $env:ProgramData 'AudioKeepAlive'
$legacyInstallDirectory = Join-Path $env:LOCALAPPDATA 'AudioKeepAlive'
$sourceExecutable = Join-Path $PSScriptRoot 'dist\AudioKeepAlive.exe'
$installedExecutable = Join-Path $installDirectory 'AudioKeepAlive.exe'
$runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$runValueName = 'AudioKeepAlive'

if ($Build -or -not (Test-Path -LiteralPath $sourceExecutable)) {
    & (Join-Path $PSScriptRoot 'build.ps1')
}
if (-not (Test-Path -LiteralPath $sourceExecutable)) {
    throw "Build output not found: $sourceExecutable"
}

Get-Process -Name 'AudioKeepAlive' -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Path -eq $installedExecutable -or
        $_.Path -eq (Join-Path $legacyInstallDirectory 'AudioKeepAlive.exe')
    } |
    Stop-Process -Force
Remove-ItemProperty -Path $runKey -Name $runValueName -ErrorAction SilentlyContinue

if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
Copy-Item -LiteralPath $sourceExecutable -Destination $installedExecutable -Force
Remove-Item -LiteralPath (Join-Path $installDirectory 'AudioKeepAlive.cs') -Force -ErrorAction SilentlyContinue
if (Test-Path -LiteralPath $legacyInstallDirectory) {
    Remove-Item -LiteralPath $legacyInstallDirectory -Recurse -Force
}

$startBoundary = (Get-Date).AddSeconds(10).ToString("yyyy-MM-dd'T'HH:mm:sszzz")
$userSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$escapedCommand = [Security.SecurityElement]::Escape($installedExecutable)

$taskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>Plays a very quiet audio pulse periodically to keep the active audio device awake.</Description>
  </RegistrationInfo>
  <Triggers>
    <TimeTrigger>
      <Repetition>
        <Interval>PT$($IntervalMinutes)M</Interval>
        <StopAtDurationEnd>false</StopAtDurationEnd>
      </Repetition>
      <StartBoundary>$startBoundary</StartBoundary>
      <Enabled>true</Enabled>
    </TimeTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$userSid</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>true</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT30S</ExecutionTimeLimit>
    <Priority>7</Priority>
    <RestartOnFailure>
      <Interval>PT1M</Interval>
      <Count>3</Count>
    </RestartOnFailure>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>$escapedCommand</Command>
    </Exec>
  </Actions>
</Task>
"@

Register-ScheduledTask -TaskName $taskName -Xml $taskXml -Force | Out-Null
Start-ScheduledTask -TaskName $taskName

Write-Host "Installed: $installedExecutable"
Write-Host "Scheduled task: $taskName (every $IntervalMinutes minute(s))"
