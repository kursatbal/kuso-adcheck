# Kuso AD Check

Active Directory security & health assessment tool. A single PowerShell script scans a domain and produces a self-contained, interactive HTML report — no agents, no external dependencies on the target.

Full methodology write-up: https://kursatbal.com/p/kuso-adcheck-metodoloji/

**[View a sample report](sample-report.html)** — generated against a lab domain, all names/hostnames/IPs anonymized.

## What it does

Kuso AD Check evaluates AD security across **21 analysis screens** and **96 security rules** grouped into 6 risk categories, mapping findings to the Microsoft Tiering model (T0–T2) and MITRE ATT&CK techniques.

| Category | Rules | Focus |
|---|---|---|
| Privileged Infrastructure | 55 | DCSync rights, critical ACEs, SMBv1 exposure, AD CS flaws (ESC1/4/6/8) |
| Privileged Accounts | 11 | krbtgt rotation, delegation types, Protected Users membership |
| Stale Objects | 8 | inactive accounts, NTLM versions, LAPS coverage, machine quota |
| Anomalies | 16 | coercion vectors (PetitPotam), GPP password remnants, AS-REP roasting |
| Hygiene | 4 | PSO policies, functional levels, Entra Join adoption |
| Trusts | 2 | SID filtering status, SIDHistory cleanup |

### Report sections

- **Security** — AD Risk Dashboard, Risk Baseline Diff, AD User Risk Level
- **Inventory & Operations** — OS overview, users/groups, inactive objects, Exchange/O365 users, service accounts, locked accounts, password expiry & policies (PSO), Group Policy check + OU-GPO hierarchy tree, AD Tier List (T0/T1/T2)
- **Infrastructure** — AD sites & topology, DC health & FSMO, AD trusts, DNS health, SYSVOL/NETLOGON, hybrid/Entra join, skipped/unreachable DCs

### Extras

- Attack chain simulation (realistic exploitation path graphs)
- Risk simulator — recalculates score for "what if this finding is fixed" scenarios
- Baseline diffing across scan runs
- Remediation tracking (open / closed / exempted workflow, persisted client-side)
- Bilingual report (English base + Turkish translation toggle)

## Usage

```
1. Right-click Deploy.ps1 → "Run with PowerShell"
2. Enter when prompted:
   - DC IP or hostname
   - Domain admin account (domain.local\administrator)
   - Password
3. The report is generated on the DC via a scheduled task (avoids WinRM
   double-hop issues when reaching other DCs), then copied to your Desktop
   as ADHealthReport.html and opened automatically.
```

Report generation typically takes 1–3 minutes.

### Requirements

- PowerShell 5.1+ on the machine you run `Deploy.ps1` from
- SMB (445) and WinRM (5985) access to the target DC
- Domain Admin credentials
- `C:\temp` creatable on the DC

## Repo layout

```
AD-Full-HealthCheck.ps1   Main scan + report generation script
Deploy.ps1                 Interactive deployer (copies script to DC, runs it, pulls the report back)
Run-ADHealthReport.bat     Local shortcut to run the script directly
tools/                     Weekly scheduled task registration, email diff notifier, PingCastle baseline helpers
```

## Author

Kürşat Bal — Systems Engineer
