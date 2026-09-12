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
$sourceLauncher = Join-Path $PSScriptRoot 'RunHidden.vbs'
$installedExecutable = Join-Path $installDirectory 'AudioKeepAlive.exe'
$installedLauncher = Join-Path $installDirectory 'RunHidden.vbs'
$runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$runValueName = 'AudioKeepAlive'

if ($Build -or -not (Test-Path -LiteralPath $sourceExecutable)) {
    & (Join-Path $PSScriptRoot 'build.ps1')
}
if (-not (Test-Path -LiteralPath $sourceExecutable)) {
    throw "Build output not found: $sourceExecutable"
}

Get-Process -Name 'AudioKeepAlive' -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -eq $installedExecutable } |
    Stop-Process -Force
Remove-ItemProperty -Path $runKey -Name $runValueName -ErrorAction SilentlyContinue

if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
Copy-Item -LiteralPath $sourceExecutable -Destination $installedExecutable -Force
Copy-Item -LiteralPath $sourceLauncher -Destination $installedLauncher -Force
Remove-Item -LiteralPath (Join-Path $installDirectory 'AudioKeepAlive.dll') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $installDirectory 'AudioKeepAlive.cs') -Force -ErrorAction SilentlyContinue

$wscript = Join-Path $env:WINDIR 'System32\wscript.exe'
$taskArguments = '//B //NoLogo "{0}"' -f $installedLauncher
$startBoundary = (Get-Date).AddSeconds(10).ToString("yyyy-MM-dd'T'HH:mm:sszzz")
$userSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$escapedCommand = [Security.SecurityElement]::Escape($wscript)
$escapedArguments = [Security.SecurityElement]::Escape($taskArguments)

$taskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>Plays a short silent audio pulse periodically to keep the active audio device awake.</Description>
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
    <ExecutionTimeLimit>PT1M</ExecutionTimeLimit>
    <Priority>7</Priority>
    <RestartOnFailure>
      <Interval>PT1M</Interval>
      <Count>3</Count>
    </RestartOnFailure>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>$escapedCommand</Command>
      <Arguments>$escapedArguments</Arguments>
    </Exec>
  </Actions>
</Task>
"@

Register-ScheduledTask -TaskName $taskName -Xml $taskXml -Force | Out-Null
Start-ScheduledTask -TaskName $taskName

Write-Host "Installed: $installedExecutable"
Write-Host "Scheduled task: $taskName (every $IntervalMinutes minute(s))"
