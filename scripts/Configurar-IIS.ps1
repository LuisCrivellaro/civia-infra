<#
.SYNOPSIS
    Etapa 2: IIS, pool, site CitizenTech (Caminho A - estatico) e permissoes NTFS.

.DESCRIPTION
    Roteiro do professor, secoes 4.1, 4.2 e 4.4.

    Ajustes em relacao ao roteiro:
      - O "Default Web Site" ja usa a porta 80. Se ele continuar ativo, o site
        CitizenTech e criado mas fica Stopped (conflito de binding). O script para
        o Default Web Site e desliga o inicio automatico dele.
      - Instala Web-Scripting-Tools, que traz o modulo WebAdministration usado
        nos scripts de recuperacao e validacao.
      - IIS_IUSRS e resolvido pelo SID (S-1-5-32-568), entao funciona em qualquer idioma.
      - O grupo GG_CitizenTech_Admins recebe Modify na pasta para publicar conteudo.

.EXAMPLE
    .\Configurar-IIS.ps1
    .\Configurar-IIS.ps1 -OrigemApp C:\Temp\citizentech
#>
[CmdletBinding()]
param(
    [string]$OrigemApp,
    [string]$ConfigPath
)

$ErrorActionPreference = 'Stop'
# $PSScriptRoot fica vazio no valor padrao de parametros no PowerShell 5.1
if (-not $OrigemApp) { $OrigemApp = Join-Path (Split-Path $PSScriptRoot -Parent) 'app' }
Import-Module (Join-Path $PSScriptRoot 'lib\CitizenTech.Common.psm1') -Force
$cfg = if ($ConfigPath) { Import-CTConfig -Path $ConfigPath } else { Import-CTConfig }
$iis = $cfg.IIS

try {
    Assert-CTAdmin; Assert-CTWindowsServer
    Initialize-CTLog -LogsDir $cfg.LogsDir

    Write-CTLog 'Instalando IIS (Web-Server) e ferramentas de gerenciamento' -Nivel ETAPA
    $r = Install-WindowsFeature -Name Web-Server, Web-Scripting-Tools -IncludeManagementTools
    if (-not $r.Success) { throw 'Falha ao instalar o IIS.' }
    Get-WindowsFeature -Name Web-* | Where-Object Installed | Format-Table Name, InstallState -AutoSize | Out-Host
    Import-Module WebAdministration

    Write-CTLog "Publicando a aplicacao em $($iis.SitePath)" -Nivel ETAPA
    if (-not (Test-Path (Join-Path $OrigemApp 'index.html'))) { throw "index.html nao encontrado em $OrigemApp" }
    New-Item -Path $iis.SitePath -ItemType Directory -Force | Out-Null
    Copy-Item -Path (Join-Path $OrigemApp '*') -Destination $iis.SitePath -Recurse -Force
    Get-ChildItem $iis.SitePath | Format-Table Name, Length, LastWriteTime -AutoSize | Out-Host

    Write-CTLog 'Liberando a porta 80: parando o Default Web Site' -Nivel ETAPA
    if (Get-Website | Where-Object Name -eq 'Default Web Site') {
        Stop-Website -Name 'Default Web Site' -ErrorAction SilentlyContinue
        Set-ItemProperty 'IIS:\Sites\Default Web Site' -Name serverAutoStart -Value $false
        Write-CTLog 'Default Web Site parado e sem inicio automatico.' -Nivel OK
    }

    Write-CTLog "Pool de aplicativos $($iis.PoolName)" -Nivel ETAPA
    if (-not (Test-Path "IIS:\AppPools\$($iis.PoolName)")) { New-WebAppPool -Name $iis.PoolName | Out-Null }
    # Vazio = "Sem codigo gerenciado". Obrigatorio para site estatico (evita erro 500.19)
    Set-ItemProperty "IIS:\AppPools\$($iis.PoolName)" -Name managedRuntimeVersion -Value $iis.ManagedRuntimeVersion
    Set-ItemProperty "IIS:\AppPools\$($iis.PoolName)" -Name autoStart -Value $true

    Write-CTLog "Site $($iis.SiteName) na porta $($iis.Porta)" -Nivel ETAPA
    if (-not (Get-Website | Where-Object Name -eq $iis.SiteName -ErrorAction SilentlyContinue)) {
        New-Website -Name $iis.SiteName -Port $iis.Porta -PhysicalPath $iis.SitePath -ApplicationPool $iis.PoolName | Out-Null
    } else {
        Set-ItemProperty "IIS:\Sites\$($iis.SiteName)" -Name physicalPath -Value $iis.SitePath
        Set-ItemProperty "IIS:\Sites\$($iis.SiteName)" -Name applicationPool -Value $iis.PoolName
    }
    Set-ItemProperty "IIS:\Sites\$($iis.SiteName)" -Name serverAutoStart -Value $true
    if ((Get-WebAppPoolState -Name $iis.PoolName).Value -ne 'Started') { Start-WebAppPool -Name $iis.PoolName }
    if ((Get-Website | Where-Object Name -eq $iis.SiteName).State -ne 'Started') { Start-Website -Name $iis.SiteName }

    Write-CTLog 'Permissoes NTFS da pasta do site' -Nivel ETAPA
    $iisIusrs = Resolve-CTSid -Sid 'S-1-5-32-568'
    $acl = Get-Acl $iis.SitePath
    $heranca = [System.Security.AccessControl.InheritanceFlags]'ContainerInherit,ObjectInherit'
    $prop = [System.Security.AccessControl.PropagationFlags]::None
    $acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($iisIusrs, 'ReadAndExecute', $heranca, $prop, 'Allow')))
    try {
        $admins = "$($cfg.NetbiosName)\$($cfg.AD.GrupoAdmins)"
        $acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($admins, 'Modify', $heranca, $prop, 'Allow')))
    } catch {
        Write-CTLog "Grupo $($cfg.AD.GrupoAdmins) nao encontrado (AD ainda nao configurado?). Regra ignorada." -Nivel AVISO
    }
    Set-Acl -Path $iis.SitePath -AclObject $acl
    (Get-Acl $iis.SitePath).Access | Format-Table IdentityReference, FileSystemRights, AccessControlType, IsInherited -AutoSize | Out-Host

    Write-CTLog 'Firewall: regra HTTP de entrada do IIS' -Nivel ETAPA
    $regra = Get-NetFirewallRule -Name 'IIS-WebServerRole-HTTP-In-TCP' -ErrorAction SilentlyContinue
    if ($regra) { Enable-NetFirewallRule -Name 'IIS-WebServerRole-HTTP-In-TCP' }
    else {
        New-NetFirewallRule -DisplayName 'CitizenTech HTTP 80' -Direction Inbound -Protocol TCP -LocalPort $iis.Porta -Action Allow -Profile Domain, Private | Out-Null
    }

    Write-CTLog 'Validacao (roteiro 4.2)' -Nivel ETAPA
    Get-Website | Where-Object Name -eq $iis.SiteName | Format-List Name, State, PhysicalPath, ApplicationPool | Out-Host
    Get-WebAppPoolState -Name $iis.PoolName | Out-Host
    Start-Sleep -Seconds 2
    $resp = Invoke-WebRequest -Uri $iis.UrlTeste -UseBasicParsing -TimeoutSec 15
    Write-CTLog "HTTP $($resp.StatusCode) em $($iis.UrlTeste)" -Nivel OK
} catch {
    Write-CTLog $_.Exception.Message -Nivel ERRO
    exit 1
}
