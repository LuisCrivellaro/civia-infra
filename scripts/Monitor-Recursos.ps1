<#
.SYNOPSIS
    Etapa 4: le CPU, memoria e disco, compara com os limites e registra alertas.

.DESCRIPTION
    Baseado no script do roteiro (secao 6.2). Roda a cada 5 minutos pela tarefa
    CitizenTech_Monitor_Alertas, como SYSTEM.

    O que ele faz a cada execucao:
      1. Mede CPU (media de 3 amostras de 1 s), memoria disponivel (MB) e espaco livre em C: (GB).
      2. Compara com os limites (CPU > 80 %, RAM < 500 MB, disco < 15 GB).
      3. Grava uma linha em monitor.log em toda execucao (historico de medicoes).
      4. Se algum limite foi ultrapassado, grava em alertas.log e no log Application
         (fonte CitizenTechMonitor, evento 9001, Warning).

    Diferencas em relacao ao roteiro:
      - Get-Counter so aceita o nome do contador no idioma do Windows. O script
        traduz "\Processor(_Total)\% Processor Time" para o idioma local e, se
        mesmo assim falhar, usa CIM (Win32_Processor / Win32_OperatingSystem).
      - Usa [System.Diagnostics.EventLog]::WriteEntry, que funciona no Windows
        PowerShell 5.1 e no PowerShell 7 (Write-EventLog nao existe no 7).

    Modo de teste (-ModoTeste):
      Serve para demonstrar o caminho do alerta sem estressar a VM. As medicoes
      continuam reais, mas os limites sao trocados por valores que sempre disparam.
      Tudo fica marcado como [TESTE], vai para alertas-teste.log e usa o evento 9100
      (Information). Nao conta como alerta real.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File C:\Scripts\Monitor-Recursos.ps1
    .\Monitor-Recursos.ps1 -ModoTeste
    .\Monitor-Recursos.ps1 -LimiteCPU 50 -LogDir D:\logs -SemEventLog
#>
[CmdletBinding()]
param(
    [double]$LimiteCPU = 80,
    [double]$LimiteRAM = 500,
    [double]$LimiteDisco = 15,
    [string]$Unidade = 'C:',
    [string]$LogDir = 'C:\Scripts\logs',
    [string]$EventSource = 'CitizenTechMonitor',
    [switch]$ModoTeste,
    [switch]$SemEventLog
)

$ErrorActionPreference = 'Stop'

function Get-ContadorLocal {
    param([string]$CaminhoIngles)
    # Get-Counter e o PLA so aceitam o nome do contador no idioma do Windows.
    # Pega o indice do nome em ingles (lista 009) e busca o mesmo indice na lista
    # do idioma instalado (ex.: 016 = portugues). Testa o caminho antes de devolver.
    if ($CaminhoIngles -notmatch '^\\(?<obj>[^\\(]+)(?<inst>\([^)]*\))?\\(?<ctr>.+)$') { return $CaminhoIngles }
    $obj = $Matches['obj']; $inst = [string]$Matches['inst']; $ctr = $Matches['ctr']
    try {
        $perf = [Microsoft.Win32.Registry]::PerformanceData
        $en = $perf.GetValue('Counter 009')
        $indice = @{}
        for ($i = 0; $i -lt $en.Count - 1; $i += 2) { if (-not $indice.ContainsKey($en[$i + 1])) { $indice[$en[$i + 1]] = $en[$i] } }
        $idiomas = @([System.Globalization.CultureInfo]::InstalledUICulture.LCID, [System.Globalization.CultureInfo]::CurrentUICulture.LCID) |
            ForEach-Object { '{0:x3}' -f ($_ -band 0x3FF) } | Select-Object -Unique
        foreach ($id in $idiomas) {
            if ($id -eq '009') { continue }
            $loc = $perf.GetValue("Counter $id")
            if (-not $loc) { continue }
            $nomes = @{}
            for ($i = 0; $i -lt $loc.Count - 1; $i += 2) { $nomes[$loc[$i]] = $loc[$i + 1] }
            $o = if ($indice.ContainsKey($obj) -and $nomes.ContainsKey($indice[$obj])) { $nomes[$indice[$obj]] } else { $obj }
            $c = if ($indice.ContainsKey($ctr) -and $nomes.ContainsKey($indice[$ctr])) { $nomes[$indice[$ctr]] } else { $ctr }
            $candidato = '\{0}{1}\{2}' -f $o, $inst, $c
            try { Get-Counter -Counter $candidato -MaxSamples 1 -ErrorAction Stop | Out-Null; return $candidato } catch { }
        }
    } catch { }
    return $CaminhoIngles
}

function Write-Linha([string]$arquivo, [string]$texto) {
    Add-Content -Path (Join-Path $LogDir $arquivo) -Value $texto
}

try {
    New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
    $agora = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $fonte = @{}

    # CPU
    try {
        $p = Get-ContadorLocal -CaminhoIngles '\Processor(_Total)\% Processor Time'
        $amostras = (Get-Counter -Counter $p -SampleInterval 1 -MaxSamples 3).CounterSamples.CookedValue
        $cpu = ($amostras | Measure-Object -Average).Average
        $fonte.CPU = 'Get-Counter'
    } catch {
        $cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
        $fonte.CPU = 'CIM'
    }

    # Memoria disponivel (MB)
    try {
        $p = Get-ContadorLocal -CaminhoIngles '\Memory\Available MBytes'
        $ram = (Get-Counter -Counter $p).CounterSamples[0].CookedValue
        $fonte.RAM = 'Get-Counter'
    } catch {
        $ram = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1KB
        $fonte.RAM = 'CIM'
    }

    # Disco livre (GB e %)
    $disco = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$Unidade'"
    if (-not $disco) { throw "Unidade $Unidade nao encontrada." }
    $discoGB = $disco.FreeSpace / 1GB
    $discoPct = if ($disco.Size) { 100 * $disco.FreeSpace / $disco.Size } else { 0 }

    if ($ModoTeste) {
        # Limites que sempre disparam. Medicoes continuam reais.
        $lCPU = -1; $lRAM = [double]::MaxValue; $lDisco = [double]::MaxValue
    } else {
        $lCPU = $LimiteCPU; $lRAM = $LimiteRAM; $lDisco = $LimiteDisco
    }

    $alertas = @()
    if ($cpu -gt $lCPU)       { $alertas += "CPU alta: $([math]::Round($cpu,2))% (limite $LimiteCPU%)" }
    if ($ram -lt $lRAM)       { $alertas += "Memoria baixa: $([math]::Round($ram,0)) MB livres (limite $LimiteRAM MB)" }
    if ($discoGB -lt $lDisco) { $alertas += "Disco baixo: $([math]::Round($discoGB,2)) GB livres em $Unidade (limite $LimiteDisco GB)" }

    $medicao = "CPU={0}% | RAM livre={1} MB | Disco livre {2}={3} GB ({4}%)" -f `
        [math]::Round($cpu, 1), [math]::Round($ram, 0), $Unidade, [math]::Round($discoGB, 1), [math]::Round($discoPct, 1)
    $tag = if ($ModoTeste) { 'TESTE' } elseif ($alertas.Count) { 'ALERTA' } else { 'NORMAL' }
    Write-Linha 'monitor.log' ("$agora | $tag | $medicao | fontes CPU=$($fonte.CPU) RAM=$($fonte.RAM)")

    if ($alertas.Count -gt 0) {
        if ($ModoTeste) {
            $msg = "$agora | [TESTE] limites forcados, nao e alerta real | " + ($alertas -join ' | ')
            Write-Linha 'alertas-teste.log' $msg
            $tipo = 'Information'; $id = 9100; $cor = 'Magenta'
        } else {
            $msg = "$agora | " + ($alertas -join ' | ')
            Write-Linha 'alertas.log' $msg
            $tipo = 'Warning'; $id = 9001; $cor = 'Yellow'
        }
        if (-not $SemEventLog) {
            try {
                if (-not [System.Diagnostics.EventLog]::SourceExists($EventSource)) {
                    New-EventLog -LogName Application -Source $EventSource
                }
                [System.Diagnostics.EventLog]::WriteEntry($EventSource, $msg, $tipo, $id)
            } catch {
                Write-Warning "Nao foi possivel gravar no log Application: $($_.Exception.Message)"
            }
        }
        Write-Host $msg -ForegroundColor $cor
    } else {
        Write-Host "$(Get-Date -Format 'HH:mm:ss') Recursos normais. $medicao" -ForegroundColor Green
    }
    exit 0
} catch {
    $erro = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | ERRO | $($_.Exception.Message)"
    try { Write-Linha 'monitor.log' $erro } catch { }
    Write-Host $erro -ForegroundColor Red
    exit 2
}
