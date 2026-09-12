[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$source = Join-Path $PSScriptRoot 'src\AudioKeepAlive.cpp'
$buildDirectory = Join-Path $PSScriptRoot 'build'
$outputDirectory = Join-Path $PSScriptRoot 'dist'
$executableOutput = Join-Path $outputDirectory 'AudioKeepAlive.exe'
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'

if (-not (Test-Path -LiteralPath $vswhere)) {
    throw 'Visual Studio Installer (vswhere.exe) was not found.'
}

$installationPath = & $vswhere `
    -latest `
    -products '*' `
    -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    -property installationPath
if (-not $installationPath) {
    throw 'Visual Studio C++ Build Tools were not found.'
}

$vcvars = Join-Path $installationPath 'VC\Auxiliary\Build\vcvars64.bat'
if (-not (Test-Path -LiteralPath $vcvars)) {
    throw "Compiler environment script not found: $vcvars"
}

New-Item -ItemType Directory -Path $buildDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

$batchFile = Join-Path $env:TEMP ("AudioKeepAlive-build-{0}.cmd" -f [guid]::NewGuid())
$batch = @"
@echo off
call "$vcvars" >nul
pushd "$buildDirectory"
cl /nologo /O2 /GL /MT /DUNICODE /D_UNICODE /EHsc /W4 /Fe:"$executableOutput" "$source" /link /SUBSYSTEM:WINDOWS /OPT:REF /OPT:ICF /LTCG /INCREMENTAL:NO
set BUILD_EXIT=%ERRORLEVEL%
popd
exit /b %BUILD_EXIT%
"@

try {
    Set-Content -LiteralPath $batchFile -Value $batch -Encoding Ascii
    & $env:ComSpec /d /c $batchFile
    if ($LASTEXITCODE -ne 0) {
        throw "Compilation failed with exit code $LASTEXITCODE."
    }
}
finally {
    Remove-Item -LiteralPath $batchFile -Force -ErrorAction SilentlyContinue
}

Remove-Item -LiteralPath (Join-Path $outputDirectory 'AudioKeepAlive.dll') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $outputDirectory 'AudioKeepAlive.lib') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $outputDirectory 'AudioKeepAlive.exp') -Force -ErrorAction SilentlyContinue

Write-Host "Built: $executableOutput"
