<#
.SYNOPSIS
    Etapa 5: configura a recuperacao automatica (servico W3SVC, pool e tarefa de vigilancia).

.DESCRIPTION
    Roteiro do professor, secoes 7.1 e 7.3. Sao dois mecanismos automaticos, cada um
    para um tipo de falha:

      A. Recuperacao do Service Control Manager (sc.exe failure).
         Reinicia W3SVC (e WAS) quando o processo do servico TERMINA INESPERADAMENTE.
         Importante: ela nao age quando o servico e parado de forma limpa
         (Stop-Service / net stop). Por isso o teste de falha usa dois modos.

      B. Tarefa CitizenTech_Recuperacao (a cada 2 min, SYSTEM) rodando Recupera-Site.ps1.
         Cobre servico parado, pool parado e site parado.

    Pool de aplicativos:
      - failure.rapidFailProtection = false (roteiro: evita que o pool seja desligado
        apos falhas seguidas do processo w3wp).
      - autoStart = true. No roteiro aparece como $pool.failure.autoStart, mas autoStart
        e propriedade do pool, nao do elemento failure; aqui o caminho foi corrigido.

.EXAMPLE
    .\Configurar-Recuperacao.ps1
#>
[CmdletBinding()]
param([string]$ConfigPath)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'lib\CitizenTech.Common.psm1') -Force
$cfg = if ($ConfigPath) { Import-CTConfig -Path $ConfigPath } else { Import-CTConfig }
$rec = $cfg.Recuperacao

try {
    Assert-CTAdmin; Assert-CTWindowsServer
    Initialize-CTLog -LogsDir $cfg.LogsDir
    Import-Module WebAdministration

    Write-CTLog "Pool $($cfg.IIS.PoolName): rapidFailProtection=false, autoStart=true" -Nivel ETAPA
    $poolPath = "IIS:\AppPools\$($cfg.IIS.PoolName)"
    if (-not (Test-Path $poolPath)) { throw "Pool $($cfg.IIS.PoolName) nao existe. Rode Configurar-IIS.ps1 antes." }
    Set-ItemProperty $poolPath -Name failure.rapidFailProtection -Value $false
    Set-ItemProperty $poolPath -Name autoStart -Value $true
    Get-ItemProperty $poolPath | Select-Object Name, autoStart, @{n='rapidFailProtection';e={$_.failure.rapidFailProtection}}, managedRuntimeVersion | Format-List | Out-Host

    $acoes = ($rec.AcoesMs | ForEach-Object { "restart/$_" }) -join '/'
    foreach ($svc in @('W3SVC', 'WAS')) {
        Write-CTLog "Recuperacao do servico $svc : reset=$($rec.ResetSegundos) actions=$acoes" -Nivel ETAPA
        & sc.exe failure $svc reset= $rec.ResetSegundos actions= $acoes | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "sc.exe failure $svc retornou $LASTEXITCODE" }
        # Tambem aplica a recuperacao se o servico parar com codigo de erro (nao so em crash)
        & sc.exe failureflag $svc 1 | Out-Null
    }
    & sc.exe qfailure W3SVC | Out-Host

    Copy-CTScriptsToServer -Config $cfg
    $script = Join-Path $cfg.ScriptsDir 'Recupera-Site.ps1'
    $argsRec = "-Site `"$($cfg.IIS.SiteName)`" -Pool `"$($cfg.IIS.PoolName)`" -Url `"$($cfg.IIS.UrlTeste)`" -Log `"$($cfg.LogsDir)\recuperacao.log`" -Origem Agendada"
    $t = Register-CTRepeatingTask -Nome $rec.TarefaNome -Script $script -Argumentos $argsRec -IntervaloMin $rec.TarefaIntervaloMin `
        -Descricao 'CitizenTech: verifica W3SVC, pool, site e HTTP e recupera o que estiver parado'
    Write-CTLog "Tarefa $($t.TaskName): $($t.State)" -Nivel OK
    Get-ScheduledTask -TaskName $rec.TarefaNome | Get-ScheduledTaskInfo | Format-List TaskName, LastRunTime, NextRunTime, LastTaskResult | Out-Host
} catch {
    Write-CTLog $_.Exception.Message -Nivel ERRO
    exit 1
}
