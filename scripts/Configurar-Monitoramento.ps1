<#
.SYNOPSIS
    Etapa 4: Data Collector Sets (coleta e alertas), fonte de eventos e tarefa agendada.

.DESCRIPTION
    Roteiro do professor, secoes 6.1 a 6.3.

    Cria:
      1. CitizenTech_Monitor   Data Collector Set com os 3 contadores (CPU, memoria, disco),
                               amostra a cada 15 s, arquivo .blg em C:\PerfLogs\CitizenTech.
      2. CitizenTech_Alertas   Data Collector Set de ALERTA do Monitor de Desempenho:
                               CPU > 80 %, memoria < 500 MB, disco C: < 15 GB livres.
                               Cada disparo gera o evento 2031 em
                               Microsoft-Windows-Diagnosis-PLA/Operational.
      3. Fonte de eventos CitizenTechMonitor no log Application.
      4. Copia dos scripts para C:\Scripts.
      5. Tarefa CitizenTech_Monitor_Alertas (SYSTEM, a cada 5 min) rodando Monitor-Recursos.ps1.
      6. Tarefa CitizenTech_DCS_Inicio que religa os dois conjuntos depois de um reboot
         (um Data Collector Set nao volta sozinho apos reiniciar).

    Diferencas em relacao ao roteiro:
      - No roteiro os contadores aparecem como "\\Processor(_Total)\\% Processor Time".
        Em PowerShell a barra nao e caractere de escape, entao "\\" fica duplicado e o
        caminho fica invalido. Aqui o caminho usa barra simples.
      - O coletor de contadores do PLA nao tem metodo AddCounter; a lista e atribuida
        na propriedade PerformanceCounters.
      - Os nomes dos contadores sao traduzidos para o idioma do Windows.

.EXAMPLE
    .\Configurar-Monitoramento.ps1
#>
[CmdletBinding()]
param([string]$ConfigPath)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'lib\CitizenTech.Common.psm1') -Force
$cfg = if ($ConfigPath) { Import-CTConfig -Path $ConfigPath } else { Import-CTConfig }
$m = $cfg.Monitor

function Remove-DcsSeExistir([string]$nome) {
    $d = New-Object -ComObject Pla.DataCollectorSet
    try { $d.Query($nome, $null) } catch { return }
    if ($d.Status -eq 1) { $d.Stop($true); Start-Sleep -Seconds 2 }
    $d.Delete()
    Write-CTLog "Conjunto $nome antigo removido para recriar."
}

try {
    Assert-CTAdmin; Assert-CTWindowsServer
    Initialize-CTLog -LogsDir $cfg.LogsDir

    $cCPU   = Get-CTCounterPath '\Processor(_Total)\% Processor Time'
    $cRAM   = Get-CTCounterPath '\Memory\Available MBytes'
    $cDisco = Get-CTCounterPath '\LogicalDisk(C:)\% Free Space'
    $cDiscoMB = Get-CTCounterPath '\LogicalDisk(C:)\Free Megabytes'
    Write-CTLog "Contadores no idioma local: $cCPU | $cRAM | $cDisco" -Nivel ETAPA

    # Confere se os contadores existem antes de criar o conjunto
    Get-Counter -Counter @($cCPU, $cRAM, $cDisco) -SampleInterval 1 -MaxSamples 1 | Out-Null

    New-Item -Path $m.DcsPath -ItemType Directory -Force | Out-Null

    # 1. Conjunto de coleta
    Write-CTLog "Criando Data Collector Set $($m.DcsNome)" -Nivel ETAPA
    Remove-DcsSeExistir $m.DcsNome
    $dcs = New-Object -ComObject Pla.DataCollectorSet
    $dcs.DisplayName = $m.DcsNome
    $dcs.Duration = 0                    # sem limite de tempo
    $dcs.RootPath = $m.DcsPath
    $dcs.SubdirectoryFormat = 1          # usa o padrao abaixo
    $dcs.SubdirectoryFormatPattern = 'yyyyMMdd\-NNNNNN'
    $col = $dcs.DataCollectors.CreateDataCollector(0)   # 0 = contador de desempenho
    $col.Name = 'Recursos'
    $col.FileName = 'Recursos_'
    $col.SampleInterval = $m.IntervaloAmostra
    $col.LogFileFormat = 3               # 3 = binario (.blg), abre no Monitor de Desempenho
    $col.PerformanceCounters = [string[]]@($cCPU, $cRAM, $cDisco)
    $dcs.DataCollectors.Add($col)
    $dcs.Commit($m.DcsNome, $null, 0x0003) | Out-Null
    $dcs.Start($false)
    Write-CTLog "$($m.DcsNome) criado e iniciado." -Nivel OK

    # 2. Conjunto de alertas
    $nomeAlerta = 'CitizenTech_Alertas'
    Write-CTLog "Criando Data Collector Set de alerta $nomeAlerta" -Nivel ETAPA
    Remove-DcsSeExistir $nomeAlerta
    $dcsA = New-Object -ComObject Pla.DataCollectorSet
    $dcsA.DisplayName = $nomeAlerta
    $dcsA.Duration = 0
    $dcsA.RootPath = $m.DcsPath
    $al = $dcsA.DataCollectors.CreateDataCollector(3)   # 3 = alerta
    $al.Name = 'LimitesCitizenTech'
    $al.SampleInterval = $m.IntervaloAmostra
    $al.EventLog = $true                 # grava evento 2031 no log do PLA a cada disparo
    $al.AlertThresholds = [string[]]@(
        "$cCPU>$($m.LimiteCPU)",
        "$cRAM<$($m.LimiteRAM)",
        "$cDiscoMB<$($m.LimiteDiscoGB * 1024)"
    )
    $dcsA.DataCollectors.Add($al)
    $dcsA.Commit($nomeAlerta, $null, 0x0003) | Out-Null
    $dcsA.Start($false)
    Write-CTLog "$nomeAlerta criado e iniciado." -Nivel OK
    try {
        $plaLog = New-Object System.Diagnostics.Eventing.Reader.EventLogConfiguration 'Microsoft-Windows-Diagnosis-PLA/Operational'
        if (-not $plaLog.IsEnabled) { $plaLog.IsEnabled = $true; $plaLog.SaveChanges() }
    } catch { Write-CTLog 'Nao foi possivel conferir o log Diagnosis-PLA/Operational.' -Nivel AVISO }

    # 3. Fonte de eventos
    if (-not [System.Diagnostics.EventLog]::SourceExists($m.EventSource)) {
        New-EventLog -LogName Application -Source $m.EventSource
        Write-CTLog "Fonte de eventos $($m.EventSource) criada no log Application." -Nivel OK
    }

    # 4. Scripts em C:\Scripts
    Copy-CTScriptsToServer -Config $cfg
    Write-CTLog "Scripts copiados para $($cfg.ScriptsDir)" -Nivel OK

    # 5. Tarefa do script de alerta
    $script = Join-Path $cfg.ScriptsDir 'Monitor-Recursos.ps1'
    $args5 = "-LimiteCPU $($m.LimiteCPU) -LimiteRAM $($m.LimiteRAM) -LimiteDisco $($m.LimiteDiscoGB) -LogDir `"$($cfg.LogsDir)`" -EventSource $($m.EventSource)"
    $t = Register-CTRepeatingTask -Nome $m.TarefaNome -Script $script -Argumentos $args5 -IntervaloMin $m.TarefaIntervaloMin `
        -Descricao 'CitizenTech: verifica CPU, memoria e disco e registra alertas'
    Write-CTLog "Tarefa $($t.TaskName): $($t.State)" -Nivel OK

    # 6. Religar os conjuntos apos reboot
    $acao = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument "/c logman start $($m.DcsNome) & logman start $nomeAlerta"
    $gat = New-ScheduledTaskTrigger -AtStartup
    $pri = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    Register-ScheduledTask -TaskName 'CitizenTech_DCS_Inicio' -Action $acao -Trigger $gat -Principal $pri -Force | Out-Null

    Write-CTLog 'Validacao (roteiro 6.1 e 6.3)' -Nivel ETAPA
    & logman.exe query $m.DcsNome | Out-Host
    & logman.exe query $nomeAlerta | Out-Host
    Get-ScheduledTask -TaskName $m.TarefaNome | Select-Object TaskName, State | Format-Table -AutoSize | Out-Host
    Write-CTLog 'Primeira execucao manual do script de alerta:' -Nivel ETAPA
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script -LogDir $cfg.LogsDir -EventSource $m.EventSource
} catch {
    Write-CTLog $_.Exception.Message -Nivel ERRO
    exit 1
}
