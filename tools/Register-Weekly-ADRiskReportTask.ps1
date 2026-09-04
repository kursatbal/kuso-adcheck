param(
    [Parameter(Mandatory=$true)]
    [string]$TaskName,

    [Parameter(Mandatory=$true)]
    [string]$SmtpServer,

    [Parameter(Mandatory=$true)]
    [string]$From,

    [Parameter(Mandatory=$true)]
    [string]$To,

    [string]$RunAsUser = "SYSTEM",
    [string]$DayOfWeek = "Monday",
    [string]$Time = "09:00",
    [string]$ProjectRoot = "$(Split-Path -Parent $PSScriptRoot)",
    [switch]$UseSsl
)

$ErrorActionPreference = 'Stop'

$healthScript = Join-Path $ProjectRoot 'AD-Full-HealthCheck.ps1'
$mailScript = Join-Path $ProjectRoot 'tools\Send-ADRiskDiffEmail.ps1'

if (-not (Test-Path $healthScript)) {
    throw "Health check script not found: $healthScript"
}
if (-not (Test-Path $mailScript)) {
    throw "Mail script not found: $mailScript"
}

$sslFlag = if ($UseSsl) { '-UseSsl' } else { '' }
$taskCommand = "& { Set-Location '$ProjectRoot'; .\AD-Full-HealthCheck.ps1 -SkipHeavyTelemetry; .\tools\Send-ADRiskDiffEmail.ps1 -SmtpServer '$SmtpServer' -From '$From' -To '$To' -ReportRoot '$ProjectRoot' $sslFlag }"

$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -Command \"$taskCommand\""
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $DayOfWeek -At $Time

if ($RunAsUser -eq 'SYSTEM') {
    $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
} else {
    $principal = New-ScheduledTaskPrincipal -UserId $RunAsUser -LogonType Interactive -RunLevel Highest
}

$settings = New-ScheduledTaskSettingsSet -Compatibility Win8 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Write-Host "Scheduled task registered: $TaskName"
Write-Host "Schedule: Weekly $DayOfWeek at $Time"
