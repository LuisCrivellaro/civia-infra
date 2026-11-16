<#
.SYNOPSIS
    Salva a saida real dos comandos de evidencia em arquivos .txt, por etapa.

.DESCRIPTION
    Roda os mesmos comandos que o roteiro pede para printar e grava cada saida em
    evidencias\<etapa>\<nn>-<nome>.txt, com data, hostname e o comando no cabecalho.
    Nao altera nada no servidor. Os prints de tela (navegador, services.msc,
    Monitor de Desempenho, Visualizador de Eventos) continuam sendo manuais.

.PARAMETER Etapas
    01-rede, 02-ad-dns, 03-iis, 04-ntfs-gpo, 05-monitoramento, 06-teste-falha, 07-logs, ficha.
    Padrao: todas.

.EXAMPLE
    .\Coletar-Evidencias.ps1
    .\Coletar-Evidencias.ps1 -Etapas 03-iis, ficha
#>
[CmdletBinding()]
param(
    [ValidateSet('01-rede', '02-ad-dns', '03-iis', '04-ntfs-gpo', '05-monitoramento', '06-teste-falha', '07-logs', 'ficha')]
    [string[]]$Etapas = @('01-rede', '02-ad-dns', '03-iis', '04-ntfs-gpo', '05-monitoramento', '06-teste-falha', '07-logs', 'ficha'),
    [string]$SaidaDir,
    [string]$ConfigPath
)

$ErrorActionPreference = 'Continue'
# $PSScriptRoot fica vazio no valor padrao de parametros no PowerShell 5.1
if (-not $SaidaDir) { $SaidaDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'evidencias' }
Import-Module (Join-Path $PSScriptRoot 'lib\CitizenTech.Common.psm1') -Force
$cfg = if ($ConfigPath) { Import-CTConfig -Path $ConfigPath } else { Import-CTConfig }
Import-Module WebAdministration -ErrorAction SilentlyContinue

$site = $cfg.IIS.SiteName; $pool = $cfg.IIS.PoolName
$fqdn = "$($cfg.Hostname).$($cfg.DomainName)".ToLower()
$ouDn = "OU=$($cfg.AD.OUName)," + (($cfg.DomainName -split '\.' | ForEach-Object { "DC=$_" }) -join ',')
$logs = $cfg.LogsDir

# Cada item: Etapa, Nome do arquivo, comando (texto exibido) e scriptblock
$itens = @(
    ,@('01-rede', '01-hostname', 'hostname', { hostname })
    ,@('01-rede', '02-winver-versao', 'Get-ComputerInfo (versao do Windows)', { Get-ComputerInfo -Property OsName, OsVersion, OsBuildNumber, WindowsVersion, CsProcessors, CsTotalPhysicalMemory | Format-List })
    ,@('01-rede', '03-ipconfig-all', 'ipconfig /all', { ipconfig /all })
    ,@('01-rede', '04-get-netipconfiguration', 'Get-NetIPConfiguration -Detailed', { Get-NetIPConfiguration -Detailed })
    ,@('02-ad-dns', '01-get-addomain', 'Get-ADDomain | Select-Object Name, DNSRoot, DomainMode', { Get-ADDomain | Select-Object Name, DNSRoot, DomainMode, NetBIOSName, PDCEmulator | Format-List })
    ,@('02-ad-dns', '02-nslookup', "nslookup $fqdn", { nslookup $fqdn })
    ,@('02-ad-dns', '03-get-dnsserverzone', 'Get-DnsServerZone', { Get-DnsServerZone | Format-Table ZoneName, ZoneType, IsDsIntegrated, IsReverseLookupZone -AutoSize })
    ,@('02-ad-dns', '04-usuarios', "Get-ADUser -Filter * -SearchBase `"$ouDn`"", { Get-ADUser -Filter * -SearchBase $ouDn | Select-Object Name, SamAccountName, Enabled | Format-Table -AutoSize })
    ,@('02-ad-dns', '05-grupos', 'Get-ADGroupMember (grupos CitizenTech)', { foreach ($g in @($cfg.AD.GrupoAdmins, $cfg.AD.GrupoUsuarios)) { "== $g"; Get-ADGroupMember -Identity $g | Select-Object Name, SamAccountName | Format-Table -AutoSize } })
    ,@('03-iis', '01-windowsfeature-web', 'Get-WindowsFeature -Name Web-* | Where-Object Installed', { Get-WindowsFeature -Name Web-* | Where-Object Installed | Format-Table Name, DisplayName, InstallState -AutoSize })
    ,@('03-iis', '02-get-website', "Get-Website | Where-Object Name -eq $site | Format-List", { Get-Website | Where-Object Name -eq $site | Format-List Name, State, PhysicalPath, ApplicationPool, Bindings })
    ,@('03-iis', '03-get-webapppoolstate', "Get-WebAppPoolState -Name $pool", { Get-WebAppPoolState -Name $pool; Get-ItemProperty "IIS:\AppPools\$pool" | Select-Object Name, managedRuntimeVersion, autoStart, startMode | Format-List })
    ,@('03-iis', '04-invoke-webrequest', 'Invoke-WebRequest http://localhost', { Invoke-WebRequest -Uri $cfg.IIS.UrlTeste -UseBasicParsing | Select-Object StatusCode, StatusDescription, @{n='Tamanho';e={$_.RawContentLength}} | Format-List })
    ,@('03-iis', '05-get-acl-site', "Get-Acl $($cfg.IIS.SitePath)", { (Get-Acl $cfg.IIS.SitePath).Access | Format-Table IdentityReference, FileSystemRights, AccessControlType, IsInherited -AutoSize })
    ,@('04-ntfs-gpo', '01-get-smbshare', 'Get-SmbShare / Get-SmbShareAccess', { Get-SmbShare -Name $cfg.Share.Nome | Format-List Name, Path, ScopeName, Description; Get-SmbShareAccess -Name $cfg.Share.Nome | Format-Table -AutoSize })
    ,@('04-ntfs-gpo', '02-get-acl-share', "Get-Acl $($cfg.Share.Path)", { (Get-Acl $cfg.Share.Path).Access | Format-Table IdentityReference, FileSystemRights, AccessControlType, IsInherited -AutoSize })
    ,@('04-ntfs-gpo', '03-get-gpo-all', 'Get-GPO -All', { Get-GPO -All | Select-Object DisplayName, GpoStatus, CreationTime | Format-Table -AutoSize })
    ,@('04-ntfs-gpo', '04-gpo-link-valor', 'Get-GPInheritance / Get-GPRegistryValue', { Get-GPInheritance -Target $ouDn | Select-Object -ExpandProperty GpoLinks | Format-Table DisplayName, Enabled, Enforced, Target -AutoSize; Get-GPRegistryValue -Name $cfg.GPO.Nome -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -ValueName NoControlPanel | Format-List })
    ,@('04-ntfs-gpo', '05-rdp', 'Configuracao RDP e firewall', { Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' | Select-Object fDenyTSConnections | Format-List; Get-NetFirewallRule -Group '@FirewallAPI.dll,-28752' | Format-Table DisplayName, Enabled, Direction, Profile -AutoSize })
    ,@('04-ntfs-gpo', '06-get-dfsnroot', 'Get-DfsnRoot (opcional)', { Get-DfsnRoot | Format-Table Path, Type, State -AutoSize })
    ,@('05-monitoramento', '01-logman-query', 'logman query', { logman query $cfg.Monitor.DcsNome; logman query CitizenTech_Alertas })
    ,@('05-monitoramento', '02-perflogs', "Get-ChildItem $($cfg.Monitor.DcsPath) -Recurse", { Get-ChildItem $cfg.Monitor.DcsPath -Recurse | Format-Table FullName, Length, LastWriteTime -AutoSize })
    ,@('05-monitoramento', '03-get-counter', 'Get-Counter CPU -SampleInterval 2 -MaxSamples 3', { Get-Counter (Get-CTCounterPath '\Processor(_Total)\% Processor Time') -SampleInterval 2 -MaxSamples 3 })
    ,@('05-monitoramento', '04-execucao-monitor', 'Monitor-Recursos.ps1', { & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $cfg.ScriptsDir 'Monitor-Recursos.ps1') -LogDir $logs })
    ,@('05-monitoramento', '05-tarefa-agendada', 'Get-ScheduledTask / Get-ScheduledTaskInfo', { Get-ScheduledTask -TaskName 'CitizenTech*' | Get-ScheduledTaskInfo | Format-Table TaskName, LastRunTime, LastTaskResult, NextRunTime -AutoSize })
    ,@('05-monitoramento', '06-monitor-log', "Get-Content $logs\monitor.log -Tail 30", { Get-Content (Join-Path $logs 'monitor.log') -Tail 30 })
    ,@('05-monitoramento', '07-alertas', 'alertas.log, alertas-teste.log e eventos 9001/9100', { foreach ($f in 'alertas.log', 'alertas-teste.log') { "== $f"; Get-Content (Join-Path $logs $f) -Tail 20 -ErrorAction SilentlyContinue }; Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName=$cfg.Monitor.EventSource} -MaxEvents 10 -ErrorAction SilentlyContinue | Format-Table TimeCreated, Id, LevelDisplayName, Message -Wrap })
    ,@('05-monitoramento', '08-alertas-perfmon', 'Eventos 2031 do Monitor de Desempenho', { Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Diagnosis-PLA/Operational'; Id=2031} -MaxEvents 10 -ErrorAction SilentlyContinue | Format-Table TimeCreated, Id, Message -Wrap })
    ,@('06-teste-falha', '01-sc-qfailure', 'sc.exe qfailure W3SVC', { sc.exe qfailure W3SVC; sc.exe qfailure WAS })
    ,@('06-teste-falha', '02-pool-recuperacao', 'Pool: rapidFailProtection e autoStart', { Get-ItemProperty "IIS:\AppPools\$pool" | Select-Object Name, autoStart, @{n='rapidFailProtection';e={$_.failure.rapidFailProtection}} | Format-List })
    ,@('06-teste-falha', '03-teste-falha-resumo', 'teste-falha-resumo.log', { Get-Content (Join-Path $logs 'teste-falha-resumo.log') })
    ,@('06-teste-falha', '04-recuperacao-log', 'recuperacao.log', { Get-Content (Join-Path $logs 'recuperacao.log') -Tail 40 })
    ,@('06-teste-falha', '05-eventos-scm', 'Eventos 7031/7034/7036 do W3SVC', { Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Service Control Manager'; Id=7031,7034} -MaxEvents 10 -ErrorAction SilentlyContinue | Format-Table TimeCreated, Id, Message -Wrap })
    ,@('07-logs', '01-auditpol', 'auditpol /get /category:*', { auditpol /get /category:* })
    ,@('07-logs', '02-security-eventos', 'Get-WinEvent Security -MaxEvents 20', { Get-WinEvent -LogName Security -MaxEvents 20 | Format-Table TimeCreated, Id, @{n='Mensagem';e={($_.Message -split "`n")[0]}} -AutoSize })
    ,@('07-logs', '03-logon-4624-4625', 'Eventos 4624/4625', { Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4624,4625} -MaxEvents 15 -ErrorAction SilentlyContinue | Format-Table TimeCreated, Id, @{n='Mensagem';e={($_.Message -split "`n")[0]}} -AutoSize })
    ,@('07-logs', '04-acesso-arquivo-4663', 'Eventos 4663', { Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4663} -MaxEvents 15 -ErrorAction SilentlyContinue | Format-Table TimeCreated, Id, @{n='Mensagem';e={($_.Message -split "`n")[0]}} -AutoSize })
    ,@('07-logs', '05-sacl-site', "Get-Acl -Audit $($cfg.IIS.SitePath)", { (Get-Acl $cfg.IIS.SitePath -Audit).Audit | Format-Table IdentityReference, FileSystemRights, AuditFlags -AutoSize })
    ,@('07-logs', '06-logs-iis', 'Get-ChildItem C:\inetpub\logs\LogFiles -Recurse', { Get-ChildItem 'C:\inetpub\logs\LogFiles' -Recurse | Select-Object FullName, Length, LastWriteTime | Format-Table -AutoSize; "== ultimas linhas"; Get-ChildItem 'C:\inetpub\logs\LogFiles' -Recurse -Filter *.log | Sort-Object LastWriteTime | Select-Object -Last 1 | Get-Content -Tail 15 })
    ,@('ficha', '00-ficha-infraestrutura', 'Bloco de validacao final (roteiro 8.1)', {
        '=== FICHA DA INFRAESTRUTURA ==='
        hostname
        ipconfig /all
        nslookup $fqdn
        Test-NetConnection -ComputerName $fqdn -Port 80
        Get-ADDomain | Select-Object Name, DNSRoot
        Get-WindowsFeature -Name Web-Server, AD-Domain-Services, DNS, FS-FileServer | Select-Object Name, InstallState
        Get-Website | Select-Object Name, State, PhysicalPath
        Get-WebAppPoolState -Name $pool
        Get-Service W3SVC, DNS | Select-Object Name, Status
        Get-SmbShare | Select-Object Name, Path
        Get-GPO -All | Select-Object DisplayName, GpoStatus
    })
)

foreach ($i in $itens) {
    $etapa, $nome, $cmdTexto, $bloco = $i
    if ($Etapas -notcontains $etapa) { continue }
    $pastaEtapa = if ($etapa -eq 'ficha') { Join-Path $SaidaDir '00-validacao' } else { Join-Path $SaidaDir $etapa }
    New-Item -Path $pastaEtapa -ItemType Directory -Force | Out-Null
    $arquivo = Join-Path $pastaEtapa "$nome.txt"
    $cab = @(
        "# Evidencia: $nome"
        "# Servidor : $env:COMPUTERNAME"
        "# Data     : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "# Comando  : $cmdTexto"
        "# Saida real capturada por scripts\Coletar-Evidencias.ps1"
        ''
    )
    try {
        $saida = & $bloco 2>&1 | Out-String -Width 250
    } catch {
        $saida = "ERRO ao executar: $($_.Exception.Message)"
    }
    ($cab + $saida) | Set-Content -Path $arquivo -Encoding UTF8
    $tag = if ($saida -match 'ERRO ao executar|FullyQualifiedErrorId') { 'VERIFICAR' } else { 'OK' }
    Write-Host ("[{0,-9}] {1}" -f $tag, $arquivo) -ForegroundColor $(if ($tag -eq 'OK') { 'Green' } else { 'Yellow' })
}
Write-Host "`nRevise cada arquivo antes de publicar. Remova qualquer dado sensivel (ex.: MAC, nomes reais)." -ForegroundColor Cyan
