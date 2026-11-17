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

    try {
        $p = Get-ContadorLocal -CaminhoIngles '\Memory\Available MBytes'
        $ram = (Get-Counter -Counter $p).CounterSamples[0].CookedValue
        $fonte.RAM = 'Get-Counter'
    } catch {
        $ram = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1KB
        $fonte.RAM = 'CIM'
    }

    $disco = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$Unidade'"
    if (-not $disco) { throw "Unidade $Unidade nao encontrada." }
    $discoGB = $disco.FreeSpace / 1GB
    $discoPct = if ($disco.Size) { 100 * $disco.FreeSpace / $disco.Size } else { 0 }

    if ($ModoTeste) {
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
