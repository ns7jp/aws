[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ExpectedAccountId,
    [string]$ExpectedRegion = 'ap-northeast-1'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$runName = Get-Date -Format 'yyyyMMdd-HHmmss'
$runDir = Join-Path $repoRoot "evidence/runs/$runName"

function Invoke-AwsJson {
    param([string[]]$Arguments, [string]$OutputFile)
    $result = & aws @Arguments
    if ($LASTEXITCODE -ne 0) { throw "aws command failed with exit code $LASTEXITCODE" }
    $result | Set-Content -LiteralPath (Join-Path $runDir $OutputFile) -Encoding utf8
}

$identityJson = & aws sts get-caller-identity --output json
if ($LASTEXITCODE -ne 0) { throw "Unable to identify the AWS caller." }
$identity = $identityJson | ConvertFrom-Json
$configuredRegion = (& aws configure get region).Trim()
if ($LASTEXITCODE -ne 0) { throw "Unable to read the configured AWS Region." }

if ($identity.Account -ne $ExpectedAccountId) {
    throw "Account gate failed. No evidence commands were run."
}
if ($configuredRegion -ne $ExpectedRegion) {
    throw "Region gate failed. No evidence commands were run."
}

New-Item -ItemType Directory -Path $runDir | Out-Null

@"
# Run context

- Time (JST): $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')
- Region: $configuredRegion
- Account: REDACTED
- Role ARN: REDACTED
- Status: Commands executed; test judgments must be added manually.
"@ | Set-Content -LiteralPath (Join-Path $runDir '00-context.md') -Encoding utf8

Invoke-AwsJson -Arguments @('ec2', 'describe-instances', '--filters', 'Name=tag:Project,Values=aws-casepack', 'Name=instance-state-name,Values=running', '--query', 'Reservations[].Instances[].{InstanceId:InstanceId,AZ:Placement.AvailabilityZone,PrivateIp:PrivateIpAddress,PublicIp:PublicIpAddress,SecurityGroups:SecurityGroups}', '--output', 'json') -OutputFile 'instances.json'
Invoke-AwsJson -Arguments @('cloudwatch', 'describe-alarms', '--alarm-name-prefix', 'aws-casepack-', '--output', 'json') -OutputFile 'alarms.json'
Invoke-AwsJson -Arguments @('autoscaling', 'describe-auto-scaling-groups', '--query', 'AutoScalingGroups[?contains(AutoScalingGroupName,`aws-casepack`)]', '--output', 'json') -OutputFile 'autoscaling.json'

Write-Host "Evidence collected in $runDir"
Write-Warning 'Review and redact every file before publication. Collection is not a PASS judgment.'
