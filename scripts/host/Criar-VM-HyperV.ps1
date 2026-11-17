[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)][string]$IsoPath,
    [string]$NomeVM = 'SRV-CITIZENTECH',
    [string]$NomeSwitch = 'Civia-Externo',
    [string]$AdaptadorFisico,
    [string]$PastaVM = 'C:\Hyper-V',
    [int64]$MemoriaBytes = 4GB,
    [int]$Processadores = 2,
    [int64]$DiscoBytes = 60GB
)

$ErrorActionPreference = 'Stop'

try {
    $adm = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $adm) { throw 'Abra o PowerShell como Administrador.' }
    if (-not (Get-Command New-VM -ErrorAction SilentlyContinue)) { throw 'Modulo Hyper-V ausente. Ative o Hyper-V e reinicie o computador.' }
    if (-not (Test-Path $IsoPath)) { throw "ISO nao encontrada: $IsoPath" }
    if (Get-VM -Name $NomeVM -ErrorAction SilentlyContinue) { throw "Ja existe uma VM chamada $NomeVM. Nada foi alterado." }

    $sw = Get-VMSwitch -Name $NomeSwitch -ErrorAction SilentlyContinue
    if (-not $sw) {
        if (-not $AdaptadorFisico) {
            $AdaptadorFisico = (Get-NetAdapter -Physical | Where-Object Status -eq 'Up' |
                Sort-Object { if ($_.MediaType -eq '802.3') { 0 } else { 1 } } | Select-Object -First 1).Name
        }
        if (-not $AdaptadorFisico) { throw 'Nenhuma placa de rede fisica conectada encontrada.' }
        Write-Host "Criando switch externo $NomeSwitch na placa '$AdaptadorFisico'. A rede do host cai por alguns segundos." -ForegroundColor Yellow
        if ($PSCmdlet.ShouldProcess($AdaptadorFisico, "Criar switch externo $NomeSwitch")) {
            $sw = New-VMSwitch -Name $NomeSwitch -NetAdapterName $AdaptadorFisico -AllowManagementOS $true
        }
    } else { Write-Host "Switch $NomeSwitch ja existe." }

    New-Item -Path $PastaVM -ItemType Directory -Force | Out-Null
    $vhd = Join-Path $PastaVM "$NomeVM\$NomeVM.vhdx"
    if ($PSCmdlet.ShouldProcess($NomeVM, 'Criar VM')) {
        New-VM -Name $NomeVM -Generation 2 -MemoryStartupBytes $MemoriaBytes -SwitchName $NomeSwitch `
            -NewVHDPath $vhd -NewVHDSizeBytes $DiscoBytes -Path $PastaVM | Out-Null
        Set-VM -Name $NomeVM -ProcessorCount $Processadores -StaticMemory -AutomaticCheckpointsEnabled $false `
            -AutomaticStopAction ShutDown -AutomaticStartAction Nothing

        $dvd = Add-VMDvdDrive -VMName $NomeVM -Path $IsoPath -Passthru
        Set-VMFirmware -VMName $NomeVM -FirstBootDevice $dvd

        Enable-VMIntegrationService -VMName $NomeVM -Name 'Guest Service Interface' -ErrorAction SilentlyContinue
    }

    Get-VM -Name $NomeVM | Format-List Name, State, Generation, ProcessorCount, MemoryStartup, Path | Out-Host
    Get-VMHardDiskDrive -VMName $NomeVM | Format-Table Path -AutoSize | Out-Host
    Get-VMNetworkAdapter -VMName $NomeVM | Format-Table Name, SwitchName -AutoSize | Out-Host
    Write-Host 'VM criada. Proximo passo:' -ForegroundColor Green
    Write-Host "  Start-VM -Name $NomeVM; vmconnect.exe localhost $NomeVM"
    Write-Host '  Na janela da VM, aperte uma tecla quando aparecer "Press any key to boot from CD or DVD".'
} catch {
    Write-Host "ERRO: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
