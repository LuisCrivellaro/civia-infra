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

    Get-Counter -Counter @($cCPU, $cRAM, $cDisco) -SampleInterval 1 -MaxSamples 1 | Out-Null

    New-Item -Path $m.DcsPath -ItemType Directory -Force | Out-Null

    Write-CTLog "Criando Data Collector Set $($m.DcsNome)" -Nivel ETAPA
    Remove-DcsSeExistir $m.DcsNome
    $dcs = New-Object -ComObject Pla.DataCollectorSet
    $dcs.DisplayName = $m.DcsNome
    $dcs.Duration = 0                   
    $dcs.RootPath = $m.DcsPath
    $dcs.SubdirectoryFormat = 1          
    $dcs.SubdirectoryFormatPattern = 'yyyyMMdd\-NNNNNN'
    $col = $dcs.DataCollectors.CreateDataCollector(0)   
    $col.Name = 'Recursos'
    $col.FileName = 'Recursos_'
    $col.SampleInterval = $m.IntervaloAmostra
    $col.LogFileFormat = 3               
    $col.PerformanceCounters = [string[]]@($cCPU, $cRAM, $cDisco)
    $dcs.DataCollectors.Add($col)
    $dcs.Commit($m.DcsNome, $null, 0x0003) | Out-Null
    $dcs.Start($false)
    Write-CTLog "$($m.DcsNome) criado e iniciado." -Nivel OK

    $nomeAlerta = 'CitizenTech_Alertas'
    Write-CTLog "Criando Data Collector Set de alerta $nomeAlerta" -Nivel ETAPA
    Remove-DcsSeExistir $nomeAlerta
    $dcsA = New-Object -ComObject Pla.DataCollectorSet
    $dcsA.DisplayName = $nomeAlerta
    $dcsA.Duration = 0
    $dcsA.RootPath = $m.DcsPath
    $al = $dcsA.DataCollectors.CreateDataCollector(3)  
    $al.Name = 'LimitesCitizenTech'
    $al.SampleInterval = $m.IntervaloAmostra
    $al.EventLog = $true                 
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

    if (-not [System.Diagnostics.EventLog]::SourceExists($m.EventSource)) {
        New-EventLog -LogName Application -Source $m.EventSource
        Write-CTLog "Fonte de eventos $($m.EventSource) criada no log Application." -Nivel OK
    }

    Copy-CTScriptsToServer -Config $cfg
    Write-CTLog "Scripts copiados para $($cfg.ScriptsDir)" -Nivel OK

    $script = Join-Path $cfg.ScriptsDir 'Monitor-Recursos.ps1'
    $args5 = "-LimiteCPU $($m.LimiteCPU) -LimiteRAM $($m.LimiteRAM) -LimiteDisco $($m.LimiteDiscoGB) -LogDir `"$($cfg.LogsDir)`" -EventSource $($m.EventSource)"
    $t = Register-CTRepeatingTask -Nome $m.TarefaNome -Script $script -Argumentos $args5 -IntervaloMin $m.TarefaIntervaloMin `
        -Descricao 'CitizenTech: verifica CPU, memoria e disco e registra alertas'
    Write-CTLog "Tarefa $($t.TaskName): $($t.State)" -Nivel OK

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
