KusoADCheck — Active Directory Health Report
============================================

GEREKSINIMLER
-------------
- Windows makinenizde PowerShell 5.1 veya uzeri
- Hedef DC'ye SMB (445) ve WinRM (5985) erisimi
- Domain Admin kullanicisi ve parolasi
- DC'de C:\temp klasoru olusturulabilmeli

KULLANIM
--------
1. Deploy.ps1 dosyasina sag tiklayin
2. "PowerShell ile calistir" secin
3. Sorulan bilgileri girin:
   - DC IP veya hostname  (orn: 10.0.0.5)
   - Domain admin         (orn: domain.local\administrator)
   - Parola
4. Rapor otomatik olarak masaustunuze "ADHealthReport.html" olarak kaydedilir
   ve tarayicida acilir.

NOT: Rapor uretimi 1-3 dakika surebilir, bu normaldir.

SORUN GIDERME
-------------
- "Erisim reddedildi" hatasi: Kullanicinin Domain Admin yetkisi oldugunu dogrulayin
- WinRM hatasi: DC'de "Enable-PSRemoting -Force" calistirin (admin olarak)
- C:\temp hatasi: DC'de C:\temp klasorunu elle olusturun

============================================
vmind.com.tr
