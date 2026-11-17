<#
.SYNOPSIS
    Roda a demonstracao do video em partes, na ordem e no tempo do roteiro (secao 10).

.DESCRIPTION
    Cada parte limpa a tela, mostra o titulo e o tempo previsto, exibe cada comando
    antes de executa-lo e espera ENTER para seguir. Nada aqui altera a configuracao,
    exceto a parte 6, que roda o Teste-Falha.ps1 (derruba e observa o IIS por alguns
    segundos). Rode na VM, em um PowerShell como Administrador.

.EXAMPLE
    C:\Scripts\Demo-Video.ps1
    C:\Scripts\Demo-Video.ps1 -ComecarNaParte 6
    C:\Scripts\Demo-Video.ps1 -SoParte 3
#>
[CmdletBinding()]
param(
    [int]$ComecarNaParte = 1,
    [ValidateRange(0, 8)][int]$SoParte = 0,
    [switch]$Testar
)

if ($SoParte) { $ComecarNaParte = $SoParte }
Import-Module WebAdministration -ErrorAction SilentlyContinue
$ou = 'OU=CitizenTech,DC=citizentech,DC=local'

function Titulo([int]$n, [string]$tempo, [string]$texto) {
    if (-not $Testar) { Clear-Host }
    Write-Host ('=' * 78) -ForegroundColor DarkCyan
    Write-Host (" PARTE {0} ({1})  {2}" -f $n, $tempo, $texto) -ForegroundColor Cyan
    Write-Host ('=' * 78) -ForegroundColor DarkCyan
}
function Cmd([string]$texto, [scriptblock]$bloco) {
    Write-Host "`nPS> $texto" -ForegroundColor Yellow
    (& $bloco 2>&1 | Out-String -Width 200).TrimEnd() | Write-Host
}
function Abrir([string]$exe, [string]$arg) { if (-not $Testar) { if ($arg) { Start-Process $exe $arg } else { Start-Process $exe } } }
function Proxima {
    if ($SoParte) { exit 0 }
    if ($Testar) { return }; Write-Host "`n[ENTER para a proxima parte]" -ForegroundColor DarkGray -NoNewline; [void](Read-Host) }

if ($ComecarNaParte -le 1) {
    Titulo 1 '0:00-0:40' 'Servidor: hostname, IP fixo e dominio'
    Cmd 'hostname' { hostname }
    Cmd 'ipconfig /all (linhas de IPv4, mascara, gateway, DNS e DHCP)' { ipconfig /all | Select-String 'Host Name|Primary Dns Suffix|DHCP Enabled|IPv4 Address|Subnet Mask|Default Gateway . . . . . . . . . : [0-9]|DNS Servers . . . . . . . . . . . : [0-9]' | ForEach-Object { $_.Line } }
    Cmd 'Get-NetRoute 0.0.0.0/0 (gateway padrao)' { Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Format-Table DestinationPrefix, NextHop, InterfaceAlias -AutoSize }
    Cmd 'Get-DnsClientServerAddress -AddressFamily IPv4' { Get-DnsClientServerAddress -InterfaceAlias Ethernet -AddressFamily IPv4 | Format-Table InterfaceAlias, ServerAddresses -AutoSize }
    Cmd 'Get-NetIPAddress -AddressFamily IPv4 (origem do IP)' { Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet | Format-Table IPAddress, PrefixLength, PrefixOrigin -AutoSize }
    Cmd 'Get-ADDomain | Select-Object Name, DNSRoot, DomainMode' { Get-ADDomain | Format-List Name, DNSRoot, DomainMode }
    Proxima
}
if ($ComecarNaParte -le 2) {
    Titulo 2 '0:40-1:30' 'Active Directory e DNS'
    Cmd 'nslookup -type=A srv-citizentech.citizentech.local 127.0.0.1' { nslookup -type=A srv-citizentech.citizentech.local 127.0.0.1 2>$null }
    Cmd 'Get-DnsServerZone' { Get-DnsServerZone | Where-Object { -not $_.IsReverseLookupZone } | Format-Table ZoneName, ZoneType, IsDsIntegrated -AutoSize }
    Cmd "Get-ADUser -Filter * -SearchBase '$ou'" { Get-ADUser -Filter * -SearchBase $ou | Format-Table Name, SamAccountName, Enabled -AutoSize }
    Cmd 'Get-ADGroupMember (grupos do projeto)' {
        & { foreach ($g in 'GG_CitizenTech_Admins', 'GG_CitizenTech_Usuarios') {
            Get-ADGroupMember $g | Select-Object @{n='Grupo';e={$g}}, Name, SamAccountName
        } } | Format-Table -AutoSize
    }
    Proxima
}
if ($ComecarNaParte -le 3) {
    Titulo 3 '1:30-2:40' 'IIS: site, pool e permissoes NTFS'
    Cmd 'Get-Website -Name CitizenTech' { Get-Website | Where-Object Name -eq 'CitizenTech' | Format-List Name, State, PhysicalPath, ApplicationPool }
    Cmd 'Get-WebAppPoolState CitizenTechPool + runtime' {
        $p = Get-Item IIS:\AppPools\CitizenTechPool
        [pscustomobject]@{ Pool = $p.Name; Estado = $p.State; Runtime = "'$($p.managedRuntimeVersion)' (sem codigo gerenciado)"; AutoStart = $p.autoStart } | Format-List
    }
    Cmd 'Invoke-WebRequest http://localhost' { Invoke-WebRequest http://localhost -UseBasicParsing | Format-List StatusCode, StatusDescription }
    Cmd 'Get-Acl C:\inetpub\citizentech (permissoes explicitas)' { (Get-Acl C:\inetpub\citizentech).Access | Where-Object { -not $_.IsInherited } | Format-Table IdentityReference, FileSystemRights, AccessControlType -AutoSize }
    Proxima
}
if ($ComecarNaParte -le 4) {
    Titulo 4 '2:40-3:30' 'GPO e compartilhamento de arquivos'
    Cmd 'Get-GPO -All' { Get-GPO -All | Format-Table DisplayName, GpoStatus -AutoSize }
    Cmd "Get-GPInheritance -Target '$ou'" { (Get-GPInheritance -Target $ou).GpoLinks | Format-Table DisplayName, Enabled, Target -AutoSize }
    Cmd 'Get-GPRegistryValue (NoControlPanel)' { Get-GPRegistryValue -Name GPO_CitizenTech_Usuarios -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -ValueName NoControlPanel | Format-List ValueName, Value }
    Cmd 'Get-SmbShare CitizenTech + Get-SmbShareAccess' { Get-SmbShare CitizenTech | Format-List Name, Path; Get-SmbShareAccess CitizenTech | Format-Table AccountName, AccessRight -AutoSize }
    Write-Host "`nAbrindo \\SRV-CITIZENTECH\CitizenTech no Explorador..." -ForegroundColor Yellow
    Abrir explorer.exe '\\SRV-CITIZENTECH\CitizenTech'
    $relatorio = 'C:\Scripts\prints\relatorio-gpo.html'
    New-Item (Split-Path $relatorio) -ItemType Directory -Force | Out-Null
    Get-GPOReport -Name GPO_CitizenTech_Usuarios -ReportType Html -Path $relatorio
    Write-Host "Abrindo o relatorio da GPO no Edge..." -ForegroundColor Yellow
    Abrir 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe' "--new-window `"$relatorio`""
    $print = 'C:\Scripts\prints\gpo-painel-bloqueado-bruno.png'
    if (Test-Path $print) {
        Write-Host "Abrindo o print do teste da GPO com o bruno.teste..." -ForegroundColor Yellow
        Abrir mspaint.exe "`"$print`""
    }
    Proxima
}
if ($ComecarNaParte -le 5) {
    Titulo 5 '3:30-4:30' 'Monitoramento: Data Collector Sets, script de alerta e agendamento'
    Cmd 'logman query CitizenTech_Monitor' { logman query CitizenTech_Monitor | Select-String 'Status|Sample|Processor|Memory|LogicalDisk' }
    Cmd 'logman query CitizenTech_Alertas' { logman query CitizenTech_Alertas | Select-String 'Status|>|<' }
    Cmd 'C:\Scripts\Monitor-Recursos.ps1' { & powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Scripts\Monitor-Recursos.ps1 }
    Cmd 'Get-Content C:\Scripts\logs\monitor.log -Tail 5' { Get-Content C:\Scripts\logs\monitor.log -Tail 5 }
    Cmd 'Get-Content C:\Scripts\logs\alertas.log' { Get-Content C:\Scripts\logs\alertas.log -ErrorAction SilentlyContinue }
    Cmd 'Get-ScheduledTaskInfo CitizenTech_Monitor_Alertas' { Get-ScheduledTask CitizenTech_Monitor_Alertas | Get-ScheduledTaskInfo | Format-List LastRunTime, LastTaskResult, NextRunTime }
    Write-Host "`nAbrindo o Monitor de Desempenho (perfmon)..." -ForegroundColor Yellow
    Abrir perfmon.exe
    Proxima
}
if ($ComecarNaParte -le 6) {
    Titulo 6 '4:30-5:40' 'Teste de falha e recuperacao automatica'
    Cmd 'sc.exe qfailure W3SVC' { sc.exe qfailure W3SVC }
    if ($Testar) { Write-Host '(modo -Testar: teste de falha nao executado)' } else {
        # espera o ENTER sem mostrar nenhum aviso na tela
        [void](Read-Host)
        & C:\Scripts\Teste-Falha.ps1 -Modo Crash -Confirmar
    }
    Cmd 'Eventos 7031 do Service Control Manager (ultimos 5 min)' {
        Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 7031; StartTime = (Get-Date).AddMinutes(-5) } -ErrorAction SilentlyContinue |
            Format-Table TimeCreated, Id, Message -Wrap
    }
    Proxima
}
if ($ComecarNaParte -le 7) {
    Titulo 7 '5:40-6:40' 'Auditoria e logs'
    Cmd 'auditpol /get (Logon e File System)' { auditpol /get /subcategory:'{0CCE9215-69AE-11D9-BED3-505054503030},{0CCE921D-69AE-11D9-BED3-505054503030}' }
    Cmd 'Get-WinEvent Security, eventos 4624 (logon) e 4663 (acesso a arquivo)' {
        Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4663 } -MaxEvents 4 | ForEach-Object {
            [pscustomobject]@{ Hora = $_.TimeCreated; Id = $_.Id; Arquivo = (($_.Message -split "`n") | Where-Object { $_ -match 'Object Name' } | Select-Object -First 1).Split(':', 2)[1].Trim() }
        } | Format-Table -AutoSize
        Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4624 } -MaxEvents 3 | Format-Table TimeCreated, Id -AutoSize
    }
    Cmd 'Get-ChildItem C:\inetpub\logs\LogFiles -Recurse' { Get-ChildItem C:\inetpub\logs\LogFiles -Recurse -File | Format-Table FullName, Length, LastWriteTime -AutoSize }
    Write-Host "`nAbrindo o Visualizador de Eventos no log Security..." -ForegroundColor Yellow
    Abrir eventvwr.exe '/c:Security'
    Proxima
}
if ($ComecarNaParte -le 8) {
    Titulo 8 '6:40-7:00' 'Civia no ar'
    Cmd 'Invoke-WebRequest http://srv-citizentech.citizentech.local' { Invoke-WebRequest http://srv-citizentech.citizentech.local -UseBasicParsing | Format-List StatusCode, StatusDescription }
    Write-Host "`nFim da demonstracao. Repositorio: https://github.com/LuisCrivellaro/civia-infra" -ForegroundColor Green
}
