<#
.SYNOPSIS
    Etapa 1 (identidade): AD DS, dominio citizentech.local, DNS, OU, grupos e usuarios.

.DESCRIPTION
    Roteiro do professor, secoes 3.3 a 3.5. Dividido em etapas porque a
    promocao a controlador de dominio reinicia o servidor:

      -Etapa InstalarRecurso  instala AD-Domain-Services (+ ferramentas). Sem reinicio.
      -Etapa PromoverDominio  cria a floresta citizentech.local com DNS.
                              Roda Test-ADDSForestInstallation antes, pede a senha DSRM
                              e REINICIA a VM ao final.
      -Etapa CriarObjetos     cria OU, grupos e usuarios de teste (pode rodar de novo
                              sem duplicar nada). Pede a senha inicial das contas.

    Pre-requisitos da promocao: hostname final aplicado e IP fixo configurado.

.EXAMPLE
    .\Configurar-AD.ps1 -Etapa InstalarRecurso
    .\Configurar-AD.ps1 -Etapa PromoverDominio
    .\Configurar-AD.ps1 -Etapa CriarObjetos
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidateSet('InstalarRecurso', 'PromoverDominio', 'CriarObjetos')]
    [string]$Etapa,
    [string]$ConfigPath,
    # Opcionais: permitem rodar sem Read-Host (ex.: PowerShell Direct). Nunca grave senhas em arquivo.
    [System.Security.SecureString]$SenhaDSRM,
    [System.Security.SecureString]$SenhaUsuarios
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'lib\CitizenTech.Common.psm1') -Force
$cfg = if ($ConfigPath) { Import-CTConfig -Path $ConfigPath } else { Import-CTConfig }

try {
    Assert-CTAdmin; Assert-CTWindowsServer
    Initialize-CTLog -LogsDir $cfg.LogsDir

    switch ($Etapa) {
        'InstalarRecurso' {
            Write-CTLog 'Instalando AD-Domain-Services com ferramentas de gerenciamento' -Nivel ETAPA
            $r = Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
            $r | Format-Table Success, RestartNeeded, ExitCode -AutoSize | Out-Host
            if (-not $r.Success) { throw 'Falha na instalacao do AD-Domain-Services.' }
            Get-WindowsFeature AD-Domain-Services, RSAT-AD-PowerShell | Format-Table Name, InstallState -AutoSize | Out-Host
            Write-CTLog 'Recurso instalado. Proximo passo: -Etapa PromoverDominio' -Nivel OK
        }

        'PromoverDominio' {
            # Verificacoes antes de algo irreversivel
            $cs = Get-CimInstance Win32_ComputerSystem
            if ($cs.DomainRole -ge 4) {
                Write-CTLog "Este servidor ja e controlador de dominio ($($cs.Domain)). Nada a fazer." -Nivel OK
                break
            }
            if ($env:COMPUTERNAME -ine $cfg.Hostname) {
                throw "Hostname atual ($env:COMPUTERNAME) diferente de $($cfg.Hostname). Rode Configurar-Rede.ps1 -Acao Renomear e reinicie antes."
            }
            $manual = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.PrefixOrigin -eq 'Manual' -and $_.IPAddress -eq $cfg.Rede.IPAddress }
            if (-not $manual) {
                throw "IP fixo $($cfg.Rede.IPAddress) nao encontrado. Rode Configurar-Rede.ps1 -Acao IPFixo antes."
            }
            if (-not (Get-WindowsFeature AD-Domain-Services).Installed) {
                throw 'AD-Domain-Services nao instalado. Rode -Etapa InstalarRecurso antes.'
            }
            Import-Module ADDSDeployment
            Write-CTLog 'Informe a senha do modo de restauracao (DSRM). Guarde em local seguro, fora do repositorio.' -Nivel AVISO
            $dsrm = if ($SenhaDSRM) { $SenhaDSRM } else { Read-Host -AsSecureString 'Senha DSRM' }

            Write-CTLog 'Rodando Test-ADDSForestInstallation (nao altera nada)' -Nivel ETAPA
            $teste = Test-ADDSForestInstallation -DomainName $cfg.DomainName -DomainNetbiosName $cfg.NetbiosName `
                -InstallDns -SafeModeAdministratorPassword $dsrm -Force -WarningAction SilentlyContinue
            $teste | Format-List Status, Message | Out-Host
            if ($teste.Status -ne 'Success') { throw 'O teste de pre-requisitos da floresta falhou. Veja a mensagem acima.' }

            if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Promover a DC da floresta $($cfg.DomainName) e REINICIAR")) {
                Write-CTLog "Promovendo $($env:COMPUTERNAME) a DC de $($cfg.DomainName). O servidor vai reiniciar." -Nivel AVISO
                Install-ADDSForest -DomainName $cfg.DomainName -DomainNetbiosName $cfg.NetbiosName `
                    -InstallDns -SafeModeAdministratorPassword $dsrm -Force
                # Install-ADDSForest reinicia sozinho ao terminar
            }
        }

        'CriarObjetos' {
            Import-Module ActiveDirectory
            $dom = Get-ADDomain
            $base = $dom.DistinguishedName
            $ouDn = "OU=$($cfg.AD.OUName),$base"

            Write-CTLog "Dominio: $($dom.DNSRoot) ($($dom.DomainMode))" -Nivel ETAPA
            if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouDn'" -ErrorAction SilentlyContinue)) {
                New-ADOrganizationalUnit -Name $cfg.AD.OUName -Path $base -ProtectedFromAccidentalDeletion $true
                Write-CTLog "OU criada: $ouDn" -Nivel OK
            } else { Write-CTLog "OU ja existe: $ouDn" }

            foreach ($g in @($cfg.AD.GrupoAdmins, $cfg.AD.GrupoUsuarios)) {
                if (-not (Get-ADGroup -Filter "Name -eq '$g'" -ErrorAction SilentlyContinue)) {
                    New-ADGroup -Name $g -GroupScope Global -GroupCategory Security -Path $ouDn
                    Write-CTLog "Grupo criado: $g" -Nivel OK
                } else { Write-CTLog "Grupo ja existe: $g" }
            }

            $senha = $SenhaUsuarios
            foreach ($u in $cfg.AD.Usuarios) {
                if (-not (Get-ADUser -Filter "SamAccountName -eq '$($u.Sam)'" -ErrorAction SilentlyContinue)) {
                    if (-not $senha) {
                        Write-CTLog 'Senha inicial das contas de teste (precisa atender a politica de complexidade).' -Nivel AVISO
                        $senha = Read-Host -AsSecureString 'Senha inicial'
                    }
                    New-ADUser -Name $u.Nome -SamAccountName $u.Sam -UserPrincipalName "$($u.Sam)@$($dom.DNSRoot)" `
                        -Path $ouDn -AccountPassword $senha -Enabled $true -ChangePasswordAtLogon $false
                    Write-CTLog "Usuario criado: $($u.Sam)" -Nivel OK
                } else { Write-CTLog "Usuario ja existe: $($u.Sam)" }
                $membros = Get-ADGroupMember -Identity $u.Grupo | Select-Object -ExpandProperty SamAccountName
                if ($membros -notcontains $u.Sam) {
                    Add-ADGroupMember -Identity $u.Grupo -Members $u.Sam
                    Write-CTLog "$($u.Sam) adicionado ao grupo $($u.Grupo)" -Nivel OK
                }
            }

            Write-CTLog 'Validacao (mesmos comandos do roteiro, secao 3.5)' -Nivel ETAPA
            Get-ADUser -Filter * -SearchBase $ouDn | Select-Object Name, SamAccountName, Enabled | Format-Table -AutoSize | Out-Host
            foreach ($g in @($cfg.AD.GrupoAdmins, $cfg.AD.GrupoUsuarios)) {
                Write-Host "Membros de $g" -ForegroundColor Cyan
                Get-ADGroupMember -Identity $g | Select-Object Name, SamAccountName | Format-Table -AutoSize | Out-Host
            }
        }
    }
} catch {
    Write-CTLog $_.Exception.Message -Nivel ERRO
    exit 1
}
