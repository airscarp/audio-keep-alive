[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$source = Join-Path $PSScriptRoot 'src\AudioKeepAlive.cs'
$outputDirectory = Join-Path $PSScriptRoot 'bin'
$output = Join-Path $outputDirectory 'AudioKeepAlive.exe'
$compilerCandidates = @(
    (Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'),
    (Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe')
)
$compiler = $compilerCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

if (-not $compiler) {
    throw 'The Windows .NET Framework C# compiler was not found.'
}

New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

& $compiler /nologo /target:winexe /optimize+ "/out:$output" $source
if ($LASTEXITCODE -ne 0) {
    throw "Compilation failed with exit code $LASTEXITCODE."
}

Write-Host "Built: $output"
