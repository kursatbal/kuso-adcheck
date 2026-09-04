# KusoADCheck — Proje Bağlamı

## Proje Nedir?
Active Directory sağlık raporu üreten tek bir PowerShell betiği.
Betik DC üzerinde çalışır, çıktı olarak self-contained bir HTML raporu üretir.

## Ana Dosya
`C:\Users\kbal\Desktop\kusoadcheck_extracted\KusoADCheck\AD-Full-HealthCheck.ps1`

## Deploy Döngüsü
**ÖNEMLİ:** Script Invoke-Command içinde çalışırsa double-hop problemi oluşur — diğer DC'lere WMI/SMB ile ulaşamaz, skor yanlış (yüksek) çıkar.
**Doğru yöntem: Scheduled Task ile çalıştır (SYSTEM account, double-hop yok)**

```powershell
$pass = ConvertTo-SecureString "<PASSWORD>" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential("<DOMAIN>\administrator", $pass)
New-PSDrive -Name "DC1" -PSProvider FileSystem -Root "\\<DC_IP>\c$\temp" -Credential $cred | Out-Null
Copy-Item "...\AD-Full-HealthCheck.ps1" "DC1:\AD-Full-HealthCheck.ps1" -Force
Invoke-Command -ComputerName <DC_IP> -Credential $cred -ScriptBlock {
    schtasks /create /tn "ADHealthRun" /tr "powershell.exe -ExecutionPolicy Bypass -NonInteractive -File C:\temp\AD-Full-HealthCheck.ps1" /sc once /st 00:00 /ru SYSTEM /rl HIGHEST /f | Out-Null
    schtasks /run /tn "ADHealthRun" | Out-Null
    Start-Sleep -Seconds 5
    do { Start-Sleep -Seconds 5 } while ((schtasks /query /tn "ADHealthRun" /fo LIST 2>$null) -match "Status:\s+Running")
    schtasks /delete /tn "ADHealthRun" /f | Out-Null
}
Copy-Item "DC1:\latest.html" "C:\Users\kbal\Desktop\latest.html" -Force
Remove-PSDrive "DC1" -Force
Start-Process "chrome.exe" "C:\Users\kbal\Desktop\latest.html"
```

- Test lab bilgileri (DC IP, kullanıcı, parola) yerel notlarda tutulur, repoya işlenmez.

## Rapor Yapısı — Navigasyon Bölümleri
**Security:** AD Risk Dashboard, Risk Baseline Diff, AD User Risk Level  
**Inventory & Operations:** Windows OS Overview, AD Users Overview, Groups & Security,
Inactive Objects, Exchange/O365 Users, Service Accounts, Locked Accounts,
Password Expiry, Password Policies (PSO), Group Policy Check (+ OU-GPO Hierarchy tree),
AD Tier List (T0/T1/T2)  
**Infrastructure:** AD Sites & Topology, DC Health & FSMO, AD Trusts,
DNS Health, SYSVOL / NETLOGON, Hybrid / Entra Join, Skipped / Unreachable DCs

## Dil Kuralı (KRİTİK)
- HTML her zaman **İngilizce** base yazılır
- Türkçe çeviriler YALNIZCA `domTextExactTr` JS sözlüğüne eklenir
  (ana blok ~satır 7041, son `Object.assign` blokları dosya sonuna doğru)
- GPO/OU/politika adları `data-no-translate='true'` alır — çevrilmez
- GPO içi kural/ayar isimleri (policy setting names) Türkçeye çevrilmez

## Temel Teknik Notlar
- `OuTreeData` (PascalCase, ConvertTo-Json): Effective GPO Calculator için
- `ouTreeData` (camelCase): OU-GPO Hierarchy ağacı için — JS'de `OuTreeData`'dan türetiliyor
- Global fonksiyonlar (`gpcToggleAllInherited`, `gpcExpandAll`, vb.) IIFE **dışında** tanımlı olmalı (onclick erişimi için)
- Script DC'de çalıştığında `Invoke-Command -ComputerName $DCs[0]` double-hop'a yol açar — DNS gibi yerel sorgular doğrudan çağrılmalı

## Son Eklenen Bölümler
- **Service Accounts**: SPN user tablosu + gMSA listesi
- **AD Trusts**: SID Filtering / TGT Delegation / Selective Auth tablosu
- **DNS Health**: Forward+Reverse zone tablosu, DnsAdmins listesi (`Get-DnsServerZone` doğrudan çağrılıyor)
- **SYSVOL / NETLOGON**: FRS/DFSR per-DC durumu, GPP cpassword dosyaları, NETLOGON hassas içerik
