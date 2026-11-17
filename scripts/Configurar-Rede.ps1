[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [ValidateSet('Diagnosticar', 'Renomear', 'IPFixo')]
    [string]$Acao = 'Diagnosticar',
    [int]$InterfaceIndex,
    [switch]$Reiniciar,
    [string]$ConfigPath
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'lib\CitizenTech.Common.psm1') -Force
$cfg = if ($ConfigPath) { Import-CTConfig -Path $ConfigPath } else { Import-CTConfig }

function Show-Rede {
    Write-CTLog 'Adaptadores de rede' -Nivel ETAPA
    Get-NetAdapter | Sort-Object ifIndex | Format-Table ifIndex, Name, InterfaceDescription, Status, MacAddress -AutoSize | Out-Host
    Write-CTLog 'Configuracao IPv4 atual' -Nivel ETAPA
    Get-NetIPConfiguration | ForEach-Object {
        [pscustomobject]@{
            ifIndex  = $_.InterfaceIndex
            Interface = $_.InterfaceAlias
            IPv4     = ($_.IPv4Address.IPAddress -join ', ')
            Prefixo  = ($_.IPv4Address.PrefixLength -join ', ')
            Gateway  = ($_.IPv4DefaultGateway.NextHop -join ', ')
            DNS      = ($_.DNSServer | Where-Object AddressFamily -eq 2 | ForEach-Object { $_.ServerAddresses }) -join ', '
            DHCP     = (Get-NetIPInterface -InterfaceIndex $_.InterfaceIndex -AddressFamily IPv4).Dhcp
        }
    } | Format-Table -AutoSize | Out-Host
    Write-CTLog ("Hostname atual: {0} | Hostname desejado: {1}" -f $env:COMPUTERNAME, $cfg.Hostname)
    Write-CTLog ("IP desejado (config): {0}/{1} gw {2} dns {3}" -f $cfg.Rede.IPAddress, $cfg.Rede.PrefixLength, $cfg.Rede.Gateway, ($cfg.Rede.DnsServers -join ','))
    Write-CTLog 'Confira se o IP desejado esta na mesma sub-rede do gateway e fora da faixa do DHCP do roteador.' -Nivel AVISO
}

try {
    Initialize-CTLog -LogsDir $cfg.LogsDir
    switch ($Acao) {
        'Diagnosticar' {
            Show-Rede
        }
        'Renomear' {
            Assert-CTAdmin; Assert-CTWindowsServer
            if ($env:COMPUTERNAME -ieq $cfg.Hostname) {
                Write-CTLog "O servidor ja se chama $($cfg.Hostname). Nada a fazer." -Nivel OK
                break
            }
            if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Renomear para $($cfg.Hostname)")) {
                Rename-Computer -NewName $cfg.Hostname -Force
                Write-CTLog "Nome alterado para $($cfg.Hostname). Vale apos reiniciar." -Nivel OK
                if ($Reiniciar) { Write-CTLog 'Reiniciando em 10 segundos...' -Nivel AVISO; Start-Sleep 10; Restart-Computer -Force }
                else { Write-CTLog 'Reinicie a VM antes de configurar o IP e o AD (Restart-Computer).' -Nivel AVISO }
            }
        }
        'IPFixo' {
            Assert-CTAdmin; Assert-CTWindowsServer
            if (-not $InterfaceIndex) {
                Show-Rede
                throw 'Informe -InterfaceIndex com o ifIndex da interface conectada (veja a tabela acima).'
            }
            $ip = $cfg.Rede.IPAddress
            $atual = Get-NetIPAddress -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
            if ($atual.IPAddress -contains $ip -and $atual.PrefixOrigin -contains 'Manual') {
                Write-CTLog "A interface $InterfaceIndex ja tem o IP fixo $ip." -Nivel OK
            } else {
                Write-CTLog "Testando se $ip ja esta em uso na rede..."
                if (Test-Connection -ComputerName $ip -Count 2 -Quiet) {
                    throw "O IP $ip respondeu ao ping. Escolha outro IP livre e ajuste a config."
                }
                if ($PSCmdlet.ShouldProcess("Interface $InterfaceIndex", "Aplicar IP fixo $ip/$($cfg.Rede.PrefixLength) gw $($cfg.Rede.Gateway)")) {
                    Set-NetIPInterface -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 -Dhcp Disabled
                    Get-NetIPAddress -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
                        Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
                    Get-NetRoute -InterfaceIndex $InterfaceIndex -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
                        Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue
                    New-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress $ip -PrefixLength $cfg.Rede.PrefixLength -DefaultGateway $cfg.Rede.Gateway | Out-Null
                    Write-CTLog "IP fixo aplicado: $ip/$($cfg.Rede.PrefixLength), gateway $($cfg.Rede.Gateway)" -Nivel OK
                }
            }
            if ($PSCmdlet.ShouldProcess("Interface $InterfaceIndex", "Definir DNS $($cfg.Rede.DnsServers -join ',')")) {
                Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -ServerAddresses (@($cfg.Rede.DnsServers) + '::1')
                Write-CTLog "DNS definido: $($cfg.Rede.DnsServers -join ', '), ::1" -Nivel OK
            }
            for ($i = 0; $i -lt 15; $i++) {
                if ((Get-NetIPAddress -InterfaceIndex $InterfaceIndex -IPAddress $ip -ErrorAction SilentlyContinue).AddressState -eq 'Preferred') { break }
                Start-Sleep -Seconds 1
            }
            Write-CTLog 'Teste do gateway:'
            $gw = $false
            try { $gw = Test-Connection -ComputerName $cfg.Rede.Gateway -Count 2 -Quiet } catch { }
            if ($gw) { Write-CTLog 'Gateway respondeu.' -Nivel OK } else { Write-CTLog 'Gateway nao respondeu ao ping (pode ser bloqueio de ICMP). Confira a rede.' -Nivel AVISO }
            Write-CTLog 'Evidencia: rode "ipconfig /all" e capture a tela (evidencias/01-rede).' -Nivel INFO
        }
    }
} catch {
    Write-CTLog $_.Exception.Message -Nivel ERRO
    exit 1
}
