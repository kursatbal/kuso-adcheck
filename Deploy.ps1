#Requires -Version 5.1
<#
.SYNOPSIS
    KusoADCheck — AD Health Report Deployer
    Scripti hedef DC'ye kopyalar, SYSTEM yerine domain admin ile çalıştırır,
    raporu yerel masaüstüne indirir.
#>

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  KusoADCheck — AD Health Report        " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Bilgi al
$DcIP    = Read-Host "DC IP veya hostname (orn: 10.0.0.1)"
$DcUser  = Read-Host "Domain admin kullanici (orn: domain.local\administrator)"
$DcPassRaw = Read-Host "Parola" -AsSecureString

$cred = New-Object System.Management.Automation.PSCredential($DcUser, $DcPassRaw)
$DcPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($DcPassRaw)
)

$ScriptSrc  = Join-Path $PSScriptRoot "AD-Full-HealthCheck.ps1"
$RemotePath = "\\$DcIP\c$\temp"
$ReportDest = Join-Path ([Environment]::GetFolderPath("Desktop")) "ADHealthReport.html"
$TaskName   = "KusoADHealthRun"

if (-not (Test-Path $ScriptSrc)) {
    Write-Host "[HATA] AD-Full-HealthCheck.ps1 bulunamadi: $ScriptSrc" -ForegroundColor Red
    exit 1
}

try {
    Write-Host ""
    Write-Host "[1/4] DC'ye baglaniyor..." -ForegroundColor Yellow
    net use "\\$DcIP\c$" $DcPassPlain /user:$DcUser 2>&1 | Out-Null

    if (-not (Test-Path $RemotePath)) {
        New-Item -ItemType Directory -Path $RemotePath -Force | Out-Null
    }

    Write-Host "[2/4] Script kopyalaniyor..." -ForegroundColor Yellow
    Copy-Item $ScriptSrc "$RemotePath\AD-Full-HealthCheck.ps1" -Force

    Write-Host "[3/4] Rapor uretiliyor (1-3 dakika surebilir)..." -ForegroundColor Yellow
    Invoke-Command -ComputerName $DcIP -Credential $cred -ScriptBlock {
        param($TaskName, $DcUser, $DcPass)
        schtasks /delete /tn $TaskName /f 2>$null | Out-Null
        schtasks /create /tn $TaskName `
            /tr "powershell.exe -ExecutionPolicy Bypass -NonInteractive -File C:\temp\AD-Full-HealthCheck.ps1" `
            /sc once /st 00:00 /ru $DcUser /rp $DcPass /rl HIGHEST /f | Out-Null
        schtasks /run /tn $TaskName | Out-Null

        $elapsed = 0
        do {
            Start-Sleep -Seconds 10
            $elapsed += 10
            $status = (schtasks /query /tn $TaskName /fo LIST 2>$null) -join "`n"
        } while ($status -match "Running" -and $elapsed -lt 300)

        schtasks /delete /tn $TaskName /f | Out-Null
    } -ArgumentList $TaskName, $DcUser, $DcPassPlain

    Write-Host "[4/4] Rapor indiriliyor..." -ForegroundColor Yellow
    Copy-Item "$RemotePath\latest.html" $ReportDest -Force

    net use "\\$DcIP\c$" /delete 2>&1 | Out-Null

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Rapor hazir: $ReportDest" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""

    Start-Process $ReportDest

} catch {
    Write-Host ""
    Write-Host "[HATA] $_" -ForegroundColor Red
    Write-Host ""
    net use "\\$DcIP\c$" /delete 2>&1 | Out-Null
    exit 1
}
