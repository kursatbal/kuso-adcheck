param(
    [Parameter(Mandatory=$true)]
    [string]$SmtpServer,

    [Parameter(Mandatory=$true)]
    [string]$From,

    [Parameter(Mandatory=$true)]
    [string]$To,

    [int]$Port = 25,
    [switch]$UseSsl,
    [string]$SubjectPrefix = "AD Risk Weekly",
    [string]$ReportRoot = "$(Split-Path -Parent $PSScriptRoot)",
    [string]$CredentialUser,
    [string]$CredentialPassword
)

$ErrorActionPreference = 'Stop'

function Get-LatestReportFile {
    param([string]$Root)
    $latest = Get-ChildItem -Path $Root -Filter "AD_Full_Overview_*.html" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($latest) { return $latest.FullName }

    $fallback = Join-Path $Root 'latest.html'
    if (Test-Path $fallback) { return $fallback }
    return $null
}

function Get-DomainRiskScore {
    param([string]$ReportPath)
    if (-not (Test-Path $ReportPath)) { return "N/A" }

    $raw = Get-Content -Path $ReportPath -Raw -ErrorAction SilentlyContinue
    if (-not $raw) { return "N/A" }

    $m = [regex]::Match($raw, 'Domain Risk Level:\s*(\d+)\s*/\s*100')
    if ($m.Success) { return $m.Groups[1].Value }
    return "N/A"
}

function Get-BaselineDiffSummary {
    param([string]$Root)

    $snapshot = Join-Path $Root 'tools\pingcastle_baseline_snapshot.json'
    if (-not (Test-Path $snapshot)) {
        return [PSCustomObject]@{
            GeneratedAt = "N/A"
            Total = "N/A"
            Note = "Baseline snapshot not found"
        }
    }

    try {
        $obj = Get-Content -Path $snapshot -Raw | ConvertFrom-Json
        $count = @($obj.Findings).Count
        return [PSCustomObject]@{
            GeneratedAt = [string]$obj.GeneratedAt
            Total = $count
            Note = "Current finding inventory"
        }
    } catch {
        return [PSCustomObject]@{
            GeneratedAt = "N/A"
            Total = "N/A"
            Note = "Failed to parse baseline snapshot"
        }
    }
}

$reportFile = Get-LatestReportFile -Root $ReportRoot
$score = Get-DomainRiskScore -ReportPath $reportFile
$baseline = Get-BaselineDiffSummary -Root $ReportRoot

$subject = "{0} - Score {1}/100 - {2}" -f $SubjectPrefix, $score, (Get-Date -Format 'yyyy-MM-dd')
$body = @"
AD Risk weekly report has been generated.

Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Score: $score / 100
Report: $reportFile

Baseline snapshot date: $($baseline.GeneratedAt)
Baseline finding total: $($baseline.Total)
Note: $($baseline.Note)

Next step:
- Review Critical/High findings in AD Risk Dashboard
- Update remediation statuses
- Re-run report after fixes
"@

$credential = $null
if ($CredentialUser -and $CredentialPassword) {
    $secure = ConvertTo-SecureString $CredentialPassword -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($CredentialUser, $secure)
}

$mailParams = @{
    SmtpServer = $SmtpServer
    From = $From
    To = $To
    Subject = $subject
    Body = $body
    Port = $Port
}
if ($UseSsl) { $mailParams['UseSsl'] = $true }
if ($credential) { $mailParams['Credential'] = $credential }

Send-MailMessage @mailParams
Write-Host "Mail sent: $subject"
