
Set-StrictMode -Version 2.0

$script:CTLogFile = $null

function Import-CTConfig {
    [CmdletBinding()]
    param([string]$Path = (Join-Path $PSScriptRoot '..\config\CitizenTech.config.psd1'))
    if (-not (Test-Path $Path)) { throw "Arquivo de configuracao nao encontrado: $Path" }
    $cfg = Import-PowerShellDataFile -Path $Path
    return $cfg
}

function Initialize-CTLog {
    param([Parameter(Mandatory)][string]$LogsDir, [string]$Nome = 'configuracao.log')
    if (-not (Test-Path $LogsDir)) { New-Item -Path $LogsDir -ItemType Directory -Force | Out-Null }
    $script:CTLogFile = Join-Path $LogsDir $Nome
}

function Write-CTLog {
    param(
        [Parameter(Mandatory)][string]$Mensagem,
        [ValidateSet('INFO','OK','AVISO','ERRO','ETAPA')][string]$Nivel = 'INFO'
    )
    $linha = "{0} | {1,-5} | {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Nivel, $Mensagem
    $cor = switch ($Nivel) { 'OK' {'Green'} 'AVISO' {'Yellow'} 'ERRO' {'Red'} 'ETAPA' {'Cyan'} default {'Gray'} }
    Write-Host $linha -ForegroundColor $cor
    if ($script:CTLogFile) {
        try { Add-Content -Path $script:CTLogFile -Value $linha -ErrorAction Stop } catch { }
    }
}

function Test-CTAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-CTAdmin {
    if (-not (Test-CTAdmin)) { throw 'Execute este script em um PowerShell aberto como Administrador.' }
}

function Test-CTWindowsServer {
    $os = Get-CimInstance Win32_OperatingSystem
    return ($os.ProductType -in 2, 3)
}

function Assert-CTWindowsServer {
    if (-not (Test-CTWindowsServer)) {
        throw 'Este script altera funcoes do Windows Server e so deve rodar na VM do laboratorio.'
    }
}

function Resolve-CTSid {
    param([Parameter(Mandatory)][string]$Sid)
    $obj = New-Object System.Security.Principal.SecurityIdentifier($Sid)
    return $obj.Translate([System.Security.Principal.NTAccount]).Value
}

function Get-CTDomainUsersName {
    $dom = Get-ADDomain -ErrorAction Stop
    return Resolve-CTSid -Sid ("{0}-513" -f $dom.DomainSID.Value)
}

function Get-CTCounterPath {
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

function Copy-CTScriptsToServer {
    param([Parameter(Mandatory)][hashtable]$Config)
    $origem = Split-Path $PSScriptRoot -Parent
    $destino = $Config.ScriptsDir
    foreach ($d in @($destino, (Join-Path $destino 'lib'), (Join-Path $destino 'config'), $Config.LogsDir)) {
        if (-not (Test-Path $d)) { New-Item -Path $d -ItemType Directory -Force | Out-Null }
    }
    if ((Resolve-Path $origem).Path.TrimEnd('\') -ieq $destino.TrimEnd('\')) { return }
    Copy-Item -Path (Join-Path $origem '*.ps1') -Destination $destino -Force
    Copy-Item -Path (Join-Path $origem 'lib\*') -Destination (Join-Path $destino 'lib') -Force
    Copy-Item -Path (Join-Path $origem 'config\*') -Destination (Join-Path $destino 'config') -Force
}

function Register-CTRepeatingTask {
    param(
        [Parameter(Mandatory)][string]$Nome,
        [Parameter(Mandatory)][string]$Script,
        [string]$Argumentos = '',
        [Parameter(Mandatory)][int]$IntervaloMin,
        [string]$Descricao = ''
    )
    $arg = "-NoProfile -ExecutionPolicy Bypass -File `"$Script`" $Argumentos".Trim()
    $acao = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $arg
    $gatilho = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes $IntervaloMin)
    $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    $ajustes = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 10)
    if (Get-ScheduledTask -TaskName $Nome -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $Nome -Confirm:$false
    }
    Register-ScheduledTask -TaskName $Nome -Action $acao -Trigger $gatilho -Principal $principal -Settings $ajustes -Description $Descricao | Out-Null
    try {
        $log = New-Object System.Diagnostics.Eventing.Reader.EventLogConfiguration 'Microsoft-Windows-TaskScheduler/Operational'
        if (-not $log.IsEnabled) { $log.IsEnabled = $true; $log.SaveChanges() }
    } catch { }
    return Get-ScheduledTask -TaskName $Nome
}

Export-ModuleMember -Function *-CT*
