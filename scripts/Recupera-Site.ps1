[CmdletBinding()]
param(
    [string]$Site = 'CitizenTech',
    [string]$Pool = 'CitizenTechPool',
    [string]$Url = 'http://localhost/',
    [string]$Log = 'C:\Scripts\logs\recuperacao.log',
    [ValidateSet('Manual', 'Agendada')]
    [string]$Origem = 'Manual',
    [switch]$RegistrarOk
)

$ErrorActionPreference = 'Stop'
New-Item -Path (Split-Path $Log) -ItemType Directory -Force | Out-Null
$script:acoes = 0

function Registrar([string]$componente, [string]$texto, [string]$cor = 'Cyan') {
    $linha = "{0} | {1} | {2} | {3}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Origem.ToUpper(), $componente, $texto
    Add-Content -Path $Log -Value $linha
    Write-Host $linha -ForegroundColor $cor
}

function Testar-Http {
    try {
        $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10
        return [int]$r.StatusCode
    } catch {
        if ($_.Exception.Response) { return [int]$_.Exception.Response.StatusCode }
        return 0
    }
}

try {
    Import-Module WebAdministration -ErrorAction Stop

    $svc = Get-Service W3SVC
    if ($svc.Status -ne 'Running') {
        Registrar 'W3SVC' "estava $($svc.Status). Iniciando." 'Yellow'
        Start-Service W3SVC
        (Get-Service W3SVC).WaitForStatus('Running', '00:00:30')
        Registrar 'W3SVC' "estado apos acao: $((Get-Service W3SVC).Status)" 'Green'
        $script:acoes++
    }

    $estadoPool = (Get-WebAppPoolState -Name $Pool).Value
    if ($estadoPool -ne 'Started') {
        Registrar 'POOL' "$Pool estava $estadoPool. Iniciando." 'Yellow'
        Start-WebAppPool -Name $Pool
        Start-Sleep -Seconds 2
        Registrar 'POOL' "estado apos acao: $((Get-WebAppPoolState -Name $Pool).Value)" 'Green'
        $script:acoes++
    }

    $estadoSite = (Get-Website | Where-Object Name -eq $Site).State
    if ($estadoSite -ne 'Started') {
        Registrar 'SITE' "$Site estava $estadoSite. Iniciando." 'Yellow'
        Start-Website -Name $Site
        Start-Sleep -Seconds 2
        Registrar 'SITE' "estado apos acao: $((Get-Website | Where-Object Name -eq $Site).State)" 'Green'
        $script:acoes++
    }

    $codigo = Testar-Http
    if ($codigo -eq 200) {
        if ($script:acoes -gt 0) { Registrar 'HTTP' "site respondendo com HTTP 200 apos $($script:acoes) acao(oes). RECUPERADO." 'Green' }
        elseif ($RegistrarOk) { Registrar 'HTTP' 'tudo em ordem, HTTP 200. Nenhuma acao.' 'Green' }
        else { Write-Host "$(Get-Date -Format 'HH:mm:ss') Tudo em ordem: W3SVC, pool, site e HTTP 200." -ForegroundColor Green }
        exit 0
    }

    Registrar 'HTTP' "resposta $codigo (0 = sem conexao). Executando iisreset /restart." 'Red'
    & iisreset.exe /restart | Out-Null
    Start-Sleep -Seconds 10
    $codigo = Testar-Http
    if ($codigo -eq 200) {
        Registrar 'HTTP' 'recuperado apos iisreset. HTTP 200. RECUPERADO.' 'Green'
        exit 0
    }
    Registrar 'HTTP' "falha persistente (HTTP $codigo). Verificar C:\inetpub\logs\LogFiles e o Visualizador de Eventos." 'Red'
    exit 1
} catch {
    try { Registrar 'ERRO' $_.Exception.Message 'Red' } catch { Write-Host $_.Exception.Message -ForegroundColor Red }
    exit 2
}
