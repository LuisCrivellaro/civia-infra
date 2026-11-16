<#
.SYNOPSIS
    Etapa 5: falha controlada do IIS e verificacao da recuperacao automatica.

.DESCRIPTION
    RODE SOMENTE NA VM DO LABORATORIO. O script derruba o servidor web de proposito.

    O roteiro (secao 7.2) para o W3SVC com Stop-Service e espera 30 s. Esse teste
    nao prova a recuperacao do Service Control Manager: o SCM so aplica as acoes de
    recuperacao quando o processo termina inesperadamente. Uma parada limpa fica
    parada, e o "Iniciando manualmente..." do roteiro acaba sendo quem sobe o servico.

    Por isso ha tres modos, cada um ligado a um mecanismo:

      -Modo Crash   (padrao) encerra a forca o processo svchost que hospeda W3SVC/WAS.
                    Quem recupera: SCM (sc.exe failure). Prova: evento 7031 no log System.
      -Modo Parada  Stop-Service W3SVC (igual ao roteiro).
                    Quem recupera: tarefa CitizenTech_Recuperacao (a cada 2 min).
                    Prova: linha "AGENDADA | W3SVC" nova no recuperacao.log.
      -Modo Pool    Stop-WebAppPool CitizenTechPool (site responde 503).
                    Quem recupera: tarefa CitizenTech_Recuperacao.

    Passos registrados (pedidos na atividade):
      [1] estado inicial do servico   [2] HTTP antes da falha   [3] falha provocada
      [4] indisponibilidade observada [5] espera da recuperacao [6] estado final
      [7] HTTP depois

    Resultado final, sem meio-termo:
      RECUPERACAO AUTOMATICA COMPROVADA   - voltou sem nenhuma acao deste script
      RECUPERACAO MANUAL (NAO AUTOMATICA) - so voltou com -PermitirFallbackManual
      FALHA                               - nao voltou

    Saida completa em C:\Scripts\logs\teste-falha-<data>.log (transcript).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File C:\Scripts\Teste-Falha.ps1
    .\Teste-Falha.ps1 -Modo Parada -TimeoutSegundos 180
    .\Teste-Falha.ps1 -Modo Pool -Confirmar
#>
[CmdletBinding()]
param(
    [ValidateSet('Crash', 'Parada', 'Pool')]
    [string]$Modo = 'Crash',
    [string]$Url = 'http://localhost/',
    [string]$Pool = 'CitizenTechPool',
    [string]$LogDir = 'C:\Scripts\logs',
    [int]$TimeoutSegundos = 0,
    [switch]$PermitirFallbackManual,
    [switch]$Confirmar
)

$ErrorActionPreference = 'Stop'
if ($TimeoutSegundos -le 0) { $TimeoutSegundos = if ($Modo -eq 'Crash') { 90 } else { 180 } }

function Passo([string]$t) { Write-Host "`n$t" -ForegroundColor Yellow }

function Get-Http {
    try {
        $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
        return [pscustomobject]@{ Codigo = [int]$r.StatusCode; Detalhe = 'OK' }
    } catch {
        $cod = 0
        if ($_.Exception.Response) { $cod = [int]$_.Exception.Response.StatusCode }
        return [pscustomobject]@{ Codigo = $cod; Detalhe = $_.Exception.Message }
    }
}

# Seguranca: so em Windows Server, como administrador, e com confirmacao
$os = Get-CimInstance Win32_OperatingSystem
if ($os.ProductType -notin 2, 3) { Write-Host 'Abortado: este teste so roda no Windows Server da VM.' -ForegroundColor Red; exit 3 }
$id = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $id.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { Write-Host 'Abortado: abra o PowerShell como Administrador.' -ForegroundColor Red; exit 3 }
if (-not $Confirmar) {
    $resp = Read-Host "Este teste vai derrubar o IIS em $env:COMPUTERNAME (modo $Modo). Digite SIM para continuar"
    if ($resp -ne 'SIM') { Write-Host 'Cancelado.'; exit 0 }
}

New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
$carimbo = Get-Date -Format 'yyyyMMdd-HHmmss'
$transcript = Join-Path $LogDir "teste-falha-$Modo-$carimbo.log"
Start-Transcript -Path $transcript | Out-Null
$logRec = Join-Path $LogDir 'recuperacao.log'
$linhasRecAntes = if (Test-Path $logRec) { @(Get-Content $logRec).Count } else { 0 }
$resultado = 'FALHA'
$mecanismo = ''

try {
    Import-Module WebAdministration
    Write-Host "=== TESTE DE FALHA - CITIZENTECH - modo $Modo - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" -ForegroundColor Cyan

    Passo '[1] Estado inicial do servico, pool e site'
    Get-Service W3SVC, WAS | Format-Table Name, Status -AutoSize | Out-Host
    Write-Host "Pool $Pool : $((Get-WebAppPoolState -Name $Pool).Value)"

    Passo '[2] Resposta HTTP antes da falha'
    $antes = Get-Http
    Write-Host "HTTP $($antes.Codigo) ($($antes.Detalhe))"
    if ($antes.Codigo -ne 200) { throw 'O site ja estava fora do ar antes do teste. Corrija antes de testar a recuperacao.' }

    Passo "[3] Provocando a falha (modo $Modo)"
    $inicio = Get-Date
    switch ($Modo) {
        'Crash' {
            $svc = Get-CimInstance Win32_Service -Filter "Name='W3SVC'"
            $procId = $svc.ProcessId
            $vizinhos = Get-CimInstance Win32_Service | Where-Object ProcessId -eq $procId | Select-Object -ExpandProperty Name
            Write-Host "W3SVC roda no processo $procId junto com: $($vizinhos -join ', ')"
            $permitidos = @('W3SVC', 'WAS', 'IISADMIN', 'W3LOGSVC')
            $outros = $vizinhos | Where-Object { $_ -notin $permitidos }
            if ($outros) { throw "O processo $procId tambem hospeda $($outros -join ', '). Abortado para nao derrubar outros servicos." }
            Stop-Process -Id $procId -Force
            Write-Host "Processo $procId encerrado a forca (simula queda inesperada do servico)." -ForegroundColor Red
        }
        'Parada' {
            Stop-Service W3SVC -Force
            Write-Host 'W3SVC parado com Stop-Service (parada limpa).' -ForegroundColor Red
        }
        'Pool' {
            Stop-WebAppPool -Name $Pool
            Write-Host "Pool $Pool parado." -ForegroundColor Red
        }
    }

    Passo '[4] Acessando o site durante a falha'
    Start-Sleep -Milliseconds 800
    Get-Service W3SVC | Format-Table Name, Status -AutoSize | Out-Host
    $durante = Get-Http
    if ($durante.Codigo -eq 200) {
        Write-Host 'O site continuou respondendo 200. A indisponibilidade nao foi observada; o teste nao comprova a recuperacao.' -ForegroundColor Red
        $indisponivel = $false
    } else {
        Write-Host "Site indisponivel, como esperado: HTTP $($durante.Codigo) - $($durante.Detalhe)" -ForegroundColor Red
        $indisponivel = $true
    }

    Passo "[5] Aguardando recuperacao automatica (ate $TimeoutSegundos s, sem nenhuma acao deste script)"
    $recuperou = $false
    $limite = $inicio.AddSeconds($TimeoutSegundos)
    while ((Get-Date) -lt $limite) {
        Start-Sleep -Seconds 3
        $st = (Get-Service W3SVC).Status
        $h = Get-Http
        Write-Host ("  {0:HH:mm:ss}  W3SVC={1}  HTTP={2}" -f (Get-Date), $st, $h.Codigo)
        if ($st -eq 'Running' -and $h.Codigo -eq 200) { $recuperou = $true; break }
    }
    $tempo = [math]::Round(((Get-Date) - $inicio).TotalSeconds, 1)

    if ($recuperou -and $indisponivel) {
        $resultado = 'RECUPERACAO AUTOMATICA COMPROVADA'
        # Quem recuperou?
        $ev = Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Service Control Manager'; Id = 7031, 7034; StartTime = $inicio } -ErrorAction SilentlyContinue
        $novas = if (Test-Path $logRec) { @(Get-Content $logRec) | Select-Object -Skip $linhasRecAntes } else { @() }
        $daTarefa = $novas | Where-Object { $_ -match '\| AGENDADA \|' }
        if ($Modo -eq 'Crash' -and $ev) {
            $mecanismo = 'Service Control Manager (acoes de recuperacao do sc.exe failure)'
            Write-Host 'Eventos do Service Control Manager:' -ForegroundColor Cyan
            $ev | Format-Table TimeCreated, Id, Message -Wrap | Out-Host
        } elseif ($daTarefa) {
            $mecanismo = 'Tarefa agendada CitizenTech_Recuperacao (Recupera-Site.ps1)'
            Write-Host 'Linhas novas no recuperacao.log:' -ForegroundColor Cyan
            $daTarefa | Out-Host
        } else {
            $mecanismo = 'Nao identificado (voltou sem acao deste script, mas sem evento 7031 nem linha da tarefa)'
        }
    } elseif ($recuperou -and -not $indisponivel) {
        $resultado = 'INCONCLUSIVO (a indisponibilidade nao foi observada)'
    } elseif ($PermitirFallbackManual) {
        Write-Host 'Nao voltou sozinho no tempo limite. Fallback MANUAL (nao conta como recuperacao automatica).' -ForegroundColor Red
        Start-Service W3SVC
        if ((Get-WebAppPoolState -Name $Pool).Value -ne 'Started') { Start-WebAppPool -Name $Pool }
        Start-Sleep -Seconds 5
        if ((Get-Http).Codigo -eq 200) { $resultado = 'RECUPERACAO MANUAL (NAO AUTOMATICA)' }
        $mecanismo = 'Start-Service/Start-WebAppPool executado por este script'
    }

    Passo '[6] Estado final'
    Get-Service W3SVC, WAS | Format-Table Name, Status -AutoSize | Out-Host
    Write-Host "Pool $Pool : $((Get-WebAppPoolState -Name $Pool).Value)"

    Passo '[7] Resposta HTTP depois'
    $depois = Get-Http
    Write-Host "HTTP $($depois.Codigo) ($($depois.Detalhe))"
} catch {
    Write-Host "Erro no teste: $($_.Exception.Message)" -ForegroundColor Red
    $resultado = "ERRO: $($_.Exception.Message)"
} finally {
    $cor = if ($resultado -like 'RECUPERACAO AUTOMATICA*') { 'Green' } else { 'Red' }
    Write-Host "`n=== RESULTADO: $resultado ===" -ForegroundColor $cor
    if ($mecanismo) { Write-Host "Mecanismo: $mecanismo" }
    if ($tempo) { Write-Host "Tempo ate voltar: $tempo s" }
    Add-Content -Path (Join-Path $LogDir 'teste-falha-resumo.log') -Value ("{0} | modo={1} | {2} | mecanismo={3} | tempo={4}s | transcript={5}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Modo, $resultado, $mecanismo, $tempo, $transcript)
    Stop-Transcript | Out-Null
    Write-Host "Transcript: $transcript"
}
if ($resultado -like 'RECUPERACAO AUTOMATICA*') { exit 0 } else { exit 1 }
