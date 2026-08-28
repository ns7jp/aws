[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        [Parameter(Mandatory)]
        [string[]]$ArgumentList
    )

    & $FilePath @ArgumentList
    if ($LASTEXITCODE -ne 0) {
        throw "$FilePath failed with exit code $LASTEXITCODE"
    }
}

Push-Location $repoRoot
try {
    Invoke-CheckedCommand -FilePath 'terraform' -ArgumentList @('-chdir=terraform', 'fmt', '-check', '-recursive')
    Invoke-CheckedCommand -FilePath 'terraform' -ArgumentList @('-chdir=terraform', 'init', '-backend=false', '-input=false')
    Invoke-CheckedCommand -FilePath 'terraform' -ArgumentList @('-chdir=terraform', 'validate')
    Invoke-CheckedCommand -FilePath 'python' -ArgumentList @('tests/static_checks.py')
    Write-Host 'All local static checks passed.' -ForegroundColor Green
}
finally {
    Pop-Location
}
