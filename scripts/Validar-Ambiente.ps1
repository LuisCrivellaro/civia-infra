<#
.SYNOPSIS
    Valida todos os criterios da atividade e grava o resultado de cada verificacao.

.DESCRIPTION
    So le o estado do servidor. Nao altera nenhuma configuracao.
    Cada verificacao tem um dos resultados:
      PASSOU  - conferido e de acordo com o esperado
      FALHOU  - conferido e fora do esperado
      ERRO    - a verificacao nao conseguiu rodar (modulo ausente, sem permissao etc.)
    Saida: tabela na tela + CSV e TXT em evidencias\00-validacao.

.EXAMPLE
    .\Validar-Ambiente.ps1
    .\Validar-Ambiente.ps1 -SaidaDir C:\Temp\validacao
#>
[CmdletBinding()]
param(
    [string]$ConfigPath,
    [string]$SaidaDir
)

$ErrorActionPreference = 'Stop'
# $PSScriptRoot fica vazio no valor padrao de parametros no PowerShell 5.1
if (-not $SaidaDir) { $SaidaDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'evidencias\00-validacao' }
Import-Module (Join-Path $PSScriptRoot 'lib\CitizenTech.Common.psm1') -Force
$cfg = if ($ConfigPath) { Import-CTConfig -Path $ConfigPath } else { Import-CTConfig }
$resultados = New-Object System.Collections.Generic.List[object]

function Check {
    param([string]$Criterio, [string]$Item, [scriptblock]$Teste)
    # O scriptblock devolve @($ok, 'detalhe')
    try {
        $r = & $Teste
        $status = if ($r[0]) { 'PASSOU' } else { 'FALHOU' }
        $det = [string]$r[1]
    } catch {
        $status = 'ERRO'; $det = $_.Exception.Message
    }
    $resultados.Add([pscustomobject]@{ Criterio = $Criterio; Item = $Item; Status = $status; Detalhe = $det })
    $cor = @{ PASSOU = 'Green'; FALHOU = 'Red'; ERRO = 'Yellow' }[$status]
    Write-Host ("[{0,-6}] {1,-22} {2} - {3}" -f $status, $Criterio, $Item, $det) -ForegroundColor $cor
}

function Http([string]$u) {
    try { [int](Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 10).StatusCode }
    catch { if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 } }
}

# Le FailureActions do registro (independe do idioma do sc.exe)
function Get-FailureActions([string]$svc) {
    $b = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\$svc" -Name FailureActions -ErrorAction Stop).FailureActions
    $reset = [BitConverter]::ToUInt32($b, 0)
    $n = [BitConverter]::ToUInt32($b, 12)
    $acoes = for ($i = 0; $i -lt $n; $i++) {
        $o = 20 + 8 * $i
        $tipo = [BitConverter]::ToUInt32($b, $o); $atraso = [BitConverter]::ToUInt32($b, $o + 4)
        "{0}/{1}" -f @{0='none';1='restart';2='reboot';3='run'}[[int]$tipo], $atraso
    }
    [pscustomobject]@{ Reset = $reset; Acoes = $acoes }
}

function Get-Audit([string]$guid) {
    $saida = & auditpol.exe /get /subcategory:$guid /r 2>&1
    if ($LASTEXITCODE -ne 0) { throw "auditpol retornou $LASTEXITCODE (precisa de Administrador)" }
    $linha = ($saida | Select-Object -Skip 1 | Where-Object { $_ }) | Select-Object -First 1
    if (-not $linha) { return '' }
    return ($linha -split ',')[4]
}

$isAdmin = Test-CTAdmin
Write-Host "=== VALIDACAO CITIZENTECH - $env:COMPUTERNAME - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" -ForegroundColor Cyan
if (-not $isAdmin) { Write-Host 'Aviso: sem privilegio de Administrador algumas verificacoes vao dar ERRO.' -ForegroundColor Yellow }

# ---------- 1. Rede e identidade ----------
$C = '1-Rede/Identidade'
Check $C 'Windows Server' { $os = Get-CimInstance Win32_OperatingSystem; @(($os.ProductType -in 2,3), "$($os.Caption) build $($os.BuildNumber)") }
Check $C 'Hostname' { @(($env:COMPUTERNAME -ieq $cfg.Hostname), "atual=$env:COMPUTERNAME esperado=$($cfg.Hostname)") }
Check $C 'IP fixo' {
    $ip = Get-NetIPAddress -AddressFamily IPv4 | Where-Object IPAddress -eq $cfg.Rede.IPAddress
    @(($ip -and $ip.PrefixOrigin -eq 'Manual'), "IP=$($cfg.Rede.IPAddress) origem=$($ip.PrefixOrigin) prefixo=$($ip.PrefixLength)") }
Check $C 'Gateway' {
    $gw = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue).NextHop
    @(($gw -contains $cfg.Rede.Gateway), "gateway=$($gw -join ',')") }
Check $C 'DNS do cliente aponta p/ DC' {
    $dns = (Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses }).ServerAddresses
    $ok = ($dns | Where-Object { $_ -in @($cfg.Rede.IPAddress, '127.0.0.1') }).Count -gt 0
    @($ok, "DNS=$($dns -join ',')") }
Check $C 'Controlador de dominio' { $cs = Get-CimInstance Win32_ComputerSystem; @(($cs.DomainRole -ge 4 -and $cs.Domain -ieq $cfg.DomainName), "dominio=$($cs.Domain) role=$($cs.DomainRole)") }
Check $C 'Get-ADDomain' { $d = Get-ADDomain; @(($d.DNSRoot -ieq $cfg.DomainName), "$($d.Name) / $($d.DNSRoot) / $($d.DomainMode)") }
Check $C 'Zona DNS primaria' { $z = Get-DnsServerZone -Name $cfg.DomainName; @(($z.ZoneType -eq 'Primary'), "tipo=$($z.ZoneType) AD=$($z.IsDsIntegrated)") }
Check $C 'Resolucao do FQDN' {
    $fqdn = "$($cfg.Hostname).$($cfg.DomainName)"
    $r = Resolve-DnsName $fqdn -Type A -DnsOnly
    @(($r.IPAddress -contains $cfg.Rede.IPAddress), "$fqdn -> $($r.IPAddress -join ',')") }
Check $C 'Servico DNS' { $s = Get-Service DNS; @(($s.Status -eq 'Running'), $s.Status) }
Check $C 'OU CitizenTech' { $ou = Get-ADOrganizationalUnit -Filter "Name -eq '$($cfg.AD.OUName)'"; @([bool]$ou, $ou.DistinguishedName) }
foreach ($g in @($cfg.AD.GrupoAdmins, $cfg.AD.GrupoUsuarios)) {
    Check $C "Grupo $g" { $m = @(Get-ADGroupMember -Identity $g); @(($m.Count -gt 0), "membros: $($m.SamAccountName -join ',')") }
}
Check $C 'Usuarios de teste' {
    $u = @(Get-ADUser -Filter * -SearchBase "OU=$($cfg.AD.OUName),$((Get-ADDomain).DistinguishedName)")
    @(($u.Count -ge $cfg.AD.Usuarios.Count -and -not ($u | Where-Object { -not $_.Enabled })), "$($u.Count) usuarios: $($u.SamAccountName -join ',')") }

# ---------- 2. IIS ----------
$C = '2-IIS/NTFS/Share'
Check $C 'Recursos instalados' {
    $f = Get-WindowsFeature Web-Server, AD-Domain-Services, DNS, FS-FileServer
    $falta = $f | Where-Object { -not $_.Installed }
    @((-not $falta), (($f | ForEach-Object { "$($_.Name)=$($_.InstallState)" }) -join ' ')) }
Check $C 'Servico W3SVC' { $s = Get-Service W3SVC; @(($s.Status -eq 'Running'), $s.Status) }
Import-Module WebAdministration -ErrorAction SilentlyContinue
Check $C 'Site' { $w = Get-Website | Where-Object Name -eq $cfg.IIS.SiteName; @(($w.State -eq 'Started' -and $w.PhysicalPath -ieq $cfg.IIS.SitePath), "estado=$($w.State) pasta=$($w.PhysicalPath) pool=$($w.ApplicationPool)") }
Check $C 'Pool' {
    $p = Get-Item "IIS:\AppPools\$($cfg.IIS.PoolName)"
    @(($p.State -eq 'Started' -and $p.managedRuntimeVersion -eq $cfg.IIS.ManagedRuntimeVersion), "estado=$($p.State) runtime='$($p.managedRuntimeVersion)'") }
Check $C 'HTTP localhost' { $c = Http $cfg.IIS.UrlTeste; @(($c -eq 200), "HTTP $c em $($cfg.IIS.UrlTeste)") }
Check $C 'HTTP pelo FQDN' { $u = "http://$($cfg.Hostname).$($cfg.DomainName)/"; $c = Http $u; @(($c -eq 200), "HTTP $c em $u") }
Check $C 'Porta 80 (Test-NetConnection)' { $t = Test-NetConnection -ComputerName "$($cfg.Hostname).$($cfg.DomainName)" -Port 80 -WarningAction SilentlyContinue; @($t.TcpTestSucceeded, "TcpTestSucceeded=$($t.TcpTestSucceeded)") }
Check $C 'NTFS IIS_IUSRS' {
    $n = Resolve-CTSid 'S-1-5-32-568'
    $r = (Get-Acl $cfg.IIS.SitePath).Access | Where-Object { $_.IdentityReference -eq $n -and $_.AccessControlType -eq 'Allow' -and ($_.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::ReadAndExecute) -eq [System.Security.AccessControl.FileSystemRights]::ReadAndExecute }
    @([bool]$r, "$n : $($r.FileSystemRights -join ',')") }
Check $C 'Compartilhamento' { $s = Get-SmbShare -Name $cfg.Share.Nome; @(($s.Path -ieq $cfg.Share.Path), "\\$env:COMPUTERNAME\$($s.Name) -> $($s.Path)") }
Check $C 'Permissoes do share' {
    $a = Get-SmbShareAccess -Name $cfg.Share.Nome
    $adm = $a | Where-Object { $_.AccountName -like "*\$($cfg.AD.GrupoAdmins)" -and $_.AccessRight -eq 'Full' }
    $everyone = $a | Where-Object { $_.AccountName -eq (Resolve-CTSid 'S-1-1-0') }
    @(($adm -and -not $everyone), (($a | ForEach-Object { "$($_.AccountName)=$($_.AccessRight)" }) -join '; ')) }

# ---------- GPO e RDP (fazem parte do funcionamento completo) ----------
$C = '6-GPO/RDP/DFS'
Check $C 'GPO existe' { $g = Get-GPO -Name $cfg.GPO.Nome; @(($g.GpoStatus -eq 'AllSettingsEnabled'), "status=$($g.GpoStatus)") }
Check $C 'GPO vinculada a OU' {
    $ou = "OU=$($cfg.AD.OUName),$((Get-ADDomain).DistinguishedName)"
    $l = (Get-GPInheritance -Target $ou).GpoLinks | Where-Object DisplayName -eq $cfg.GPO.Nome
    @(($l -and $l.Enabled), "link em $ou enabled=$($l.Enabled)") }
Check $C 'GPO NoControlPanel=1' { $v = Get-GPRegistryValue -Name $cfg.GPO.Nome -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -ValueName NoControlPanel; @(($v.Value -eq 1), "valor=$($v.Value)") }
Check $C 'RDP habilitado' { $v = (Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server').fDenyTSConnections; @(($v -eq 0), "fDenyTSConnections=$v") }
Check $C 'RDP com NLA' { $v = (Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp').UserAuthentication; @(($v -eq 1), "UserAuthentication=$v") }
Check $C 'Firewall RDP so rede local' {
    $r = Get-NetFirewallRule -Group '@FirewallAPI.dll,-28752' | Where-Object { $_.Enabled -eq 'True' -and $_.Direction -eq 'Inbound' }
    $addr = ($r | Get-NetFirewallAddressFilter).RemoteAddress | Select-Object -Unique
    @(($r -and ($addr -notcontains 'Any')), "regras ativas=$(@($r).Count) remoto=$($addr -join ',')") }
Check $C 'DFS (opcional)' { $d = Get-DfsnRoot -Path "\\$($cfg.DomainName)\$($cfg.DFS.NamespaceName)" -ErrorAction Stop; @(($d.State -eq 'Online'), "$($d.Path) $($d.State)") }

# ---------- 3. Monitoramento ----------
$C = '3-Monitoramento'
Check $C 'DCS CitizenTech_Monitor' {
    $d = New-Object -ComObject Pla.DataCollectorSet; $d.Query($cfg.Monitor.DcsNome, $null)
    $ctr = @($d.DataCollectors | ForEach-Object { $_.PerformanceCounters })
    @(($d.Status -eq 1 -and $ctr.Count -ge 3), "status=$($d.Status) (1=rodando) contadores=$($ctr -join ' ; ')") }
Check $C 'DCS CitizenTech_Alertas' {
    $d = New-Object -ComObject Pla.DataCollectorSet; $d.Query('CitizenTech_Alertas', $null)
    $th = @($d.DataCollectors | ForEach-Object { $_.AlertThresholds })
    @(($d.Status -eq 1 -and $th.Count -ge 3), "status=$($d.Status) limites=$($th -join ' ; ')") }
Check $C 'Arquivos .blg' { $f = Get-ChildItem $cfg.Monitor.DcsPath -Recurse -Filter *.blg; @(($f.Count -gt 0), "$(@($f).Count) arquivo(s), mais recente $(($f | Sort-Object LastWriteTime | Select-Object -Last 1).LastWriteTime)") }
Check $C 'Leitura dos 3 contadores' {
    $c = Get-Counter -Counter @((Get-CTCounterPath '\Processor(_Total)\% Processor Time'), (Get-CTCounterPath '\Memory\Available MBytes'), (Get-CTCounterPath '\LogicalDisk(C:)\% Free Space')) -MaxSamples 1
    @(($c.CounterSamples.Count -eq 3), (($c.CounterSamples | ForEach-Object { "{0}={1:N1}" -f ($_.Path -split '\\')[-1], $_.CookedValue }) -join ' ; ')) }
Check $C 'Script em C:\Scripts' { $p = Join-Path $cfg.ScriptsDir 'Monitor-Recursos.ps1'; @((Test-Path $p), $p) }
Check $C 'Fonte de eventos' { $e = [System.Diagnostics.EventLog]::SourceExists($cfg.Monitor.EventSource); @($e, $cfg.Monitor.EventSource) }
Check $C 'Tarefa de monitoramento' {
    $i = Get-ScheduledTask -TaskName $cfg.Monitor.TarefaNome | Get-ScheduledTaskInfo
    $rodou = $i.LastRunTime -gt (Get-Date).AddMinutes(-15)
    @(($rodou -and $i.LastTaskResult -eq 0), "ultima=$($i.LastRunTime) resultado=$($i.LastTaskResult) proxima=$($i.NextRunTime)") }
Check $C 'monitor.log atualizado' {
    $f = Join-Path $cfg.LogsDir 'monitor.log'
    $ult = Get-Content $f -Tail 1
    @(((Get-Item $f).LastWriteTime -gt (Get-Date).AddMinutes(-15)), $ult) }

# ---------- 4. Recuperacao ----------
$C = '4-Recuperacao'
Check $C 'sc failure W3SVC' { $f = Get-FailureActions 'W3SVC'; @(($f.Reset -gt 0 -and ($f.Acoes -match '^restart').Count -ge 1), "reset=$($f.Reset)s acoes=$($f.Acoes -join ',')") }
Check $C 'Pool rapidFail/autoStart' {
    $p = Get-Item "IIS:\AppPools\$($cfg.IIS.PoolName)"
    @((-not $p.failure.rapidFailProtection -and $p.autoStart), "rapidFailProtection=$($p.failure.rapidFailProtection) autoStart=$($p.autoStart)") }
Check $C 'Tarefa de recuperacao' {
    $i = Get-ScheduledTask -TaskName $cfg.Recuperacao.TarefaNome | Get-ScheduledTaskInfo
    @(($i.LastRunTime -gt (Get-Date).AddMinutes(-10)), "ultima=$($i.LastRunTime) resultado=$($i.LastTaskResult)") }
Check $C 'Teste de falha registrado' {
    $f = Join-Path $cfg.LogsDir 'teste-falha-resumo.log'
    $ok = Select-String -Path $f -Pattern 'RECUPERACAO AUTOMATICA COMPROVADA' -SimpleMatch
    @([bool]$ok, $(if ($ok) { $ok[-1].Line } else { 'nenhum teste com recuperacao automatica comprovada' })) }

# ---------- 5. Auditoria ----------
$C = '5-Auditoria/Logs'
Check $C 'auditpol Logon' { $s = Get-Audit '{0CCE9215-69AE-11D9-BED3-505054503030}'; @((($s -match 'Success|xito|Sucesso') -and ($s -match 'Failure|Falha')), $s) }
Check $C 'auditpol File System' { $s = Get-Audit '{0CCE921D-69AE-11D9-BED3-505054503030}'; @((($s -match 'Success|xito|Sucesso') -and ($s -match 'Failure|Falha')), $s) }
Check $C 'SACL na pasta do site' { $a = (Get-Acl $cfg.IIS.SitePath -Audit).Audit; @((@($a).Count -gt 0), (($a | ForEach-Object { "$($_.IdentityReference):$($_.FileSystemRights):$($_.AuditFlags)" }) -join '; ')) }
Check $C 'Eventos de logon (4624)' { $e = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4624} -MaxEvents 1; @([bool]$e, "ultimo em $($e.TimeCreated)") }
Check $C 'Eventos de acesso a arquivo (4663)' { $e = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4663} -MaxEvents 1; @([bool]$e, "ultimo em $($e.TimeCreated)") }
Check $C 'Logs do IIS' { $f = Get-ChildItem 'C:\inetpub\logs\LogFiles' -Recurse -Filter *.log; @((@($f).Count -gt 0), "$(@($f).Count) arquivo(s)") }

# ---------- Saida ----------
New-Item -Path $SaidaDir -ItemType Directory -Force | Out-Null
$carimbo = Get-Date -Format 'yyyyMMdd-HHmmss'
$csv = Join-Path $SaidaDir "validacao-$carimbo.csv"
$txt = Join-Path $SaidaDir "validacao-$carimbo.txt"
$resultados | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
$resumo = $resultados | Group-Object Status | ForEach-Object { "$($_.Name)=$($_.Count)" }
@(
    "Validacao CitizenTech - $env:COMPUTERNAME - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "Executado como administrador: $isAdmin"
    "Resumo: $($resumo -join ' | ')"
    ''
    ($resultados | Format-Table Criterio, Item, Status, Detalhe -AutoSize -Wrap | Out-String -Width 250)
) | Set-Content -Path $txt -Encoding UTF8

Write-Host "`nResumo: $($resumo -join ' | ')" -ForegroundColor Cyan
Write-Host "Resultado salvo em:`n  $txt`n  $csv"
if ($resultados | Where-Object Status -ne 'PASSOU') { exit 1 } else { exit 0 }
