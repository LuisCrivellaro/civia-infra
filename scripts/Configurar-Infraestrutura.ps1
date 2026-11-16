<#
.SYNOPSIS
    Etapa 3: File Server, GPO, acesso remoto (RDP), auditoria e DFS (opcional).

.DESCRIPTION
    Roteiro do professor, secoes 4.5 e 5.1 a 5.4. Requer o dominio ja criado.

    Ajustes em relacao ao roteiro:
      - "Domain Users", "Everyone" e o grupo de firewall "Area de Trabalho Remota"
        mudam de nome conforme o idioma do Windows. O script usa SIDs e o
        identificador interno do grupo de firewall (@FirewallAPI.dll,-28752).
      - auditpol usa os GUIDs das subcategorias (Logon e File System) pelo mesmo motivo.
      - RDP: usa so o RDP administrativo, sem a funcao RDS. RDS Session Host em
        controlador de dominio nao e recomendado e exige licenca depois de 120 dias.
        Exige NLA e limita as regras de firewall a sub-rede local.
      - DFS: no roteiro, New-DfsnRoot recebe "C:\Shares\CitizenTech" como TargetPath.
        O TargetPath precisa ser um caminho UNC de um compartilhamento proprio da raiz,
        e um namespace DomainV2 usa o nome do dominio (\\citizentech.local\...).
        O script cria a raiz certa e publica a pasta CitizenTech dentro dela.
        DFS Replication nao e configurado: precisa de um segundo servidor.

.PARAMETER Componentes
    FileServer, GPO, RDP, Auditoria, DFS. Padrao: todos menos DFS.

.EXAMPLE
    .\Configurar-Infraestrutura.ps1
    .\Configurar-Infraestrutura.ps1 -Componentes DFS
#>
[CmdletBinding()]
param(
    [ValidateSet('FileServer', 'GPO', 'RDP', 'Auditoria', 'DFS')]
    [string[]]$Componentes = @('FileServer', 'GPO', 'RDP', 'Auditoria'),
    [string]$ConfigPath
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'lib\CitizenTech.Common.psm1') -Force
$cfg = if ($ConfigPath) { Import-CTConfig -Path $ConfigPath } else { Import-CTConfig }

# GUIDs das subcategorias de auditoria (iguais em qualquer idioma)
$GuidLogon      = '{0CCE9215-69AE-11D9-BED3-505054503030}'
$GuidFileSystem = '{0CCE921D-69AE-11D9-BED3-505054503030}'

function Set-CTFileServer {
    Write-CTLog 'File Server e compartilhamento' -Nivel ETAPA
    $r = Install-WindowsFeature -Name FS-FileServer -IncludeManagementTools
    if (-not $r.Success) { throw 'Falha ao instalar FS-FileServer.' }
    $path = $cfg.Share.Path
    New-Item -Path $path -ItemType Directory -Force | Out-Null

    $admins = "$($cfg.NetbiosName)\$($cfg.AD.GrupoAdmins)"
    $domainUsers = Get-CTDomainUsersName

    # NTFS: admins do projeto modificam, usuarios do dominio so leem
    $acl = Get-Acl $path
    $h = [System.Security.AccessControl.InheritanceFlags]'ContainerInherit,ObjectInherit'
    $p = [System.Security.AccessControl.PropagationFlags]::None
    $acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($admins, 'Modify', $h, $p, 'Allow')))
    $acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($domainUsers, 'ReadAndExecute', $h, $p, 'Allow')))
    Set-Acl -Path $path -AclObject $acl

    # Compartilhamento: mesmas regras do roteiro (Full para admins, Read para Domain Users)
    if (-not (Get-SmbShare -Name $cfg.Share.Nome -ErrorAction SilentlyContinue)) {
        New-SmbShare -Name $cfg.Share.Nome -Path $path -FullAccess $admins -ReadAccess $domainUsers `
            -FolderEnumerationMode AccessBased -Description 'Arquivos do projeto CitizenTech' | Out-Null
        Write-CTLog "Compartilhamento criado: \\$($cfg.Hostname)\$($cfg.Share.Nome)" -Nivel OK
    } else {
        Grant-SmbShareAccess -Name $cfg.Share.Nome -AccountName $admins -AccessRight Full -Force | Out-Null
        Grant-SmbShareAccess -Name $cfg.Share.Nome -AccountName $domainUsers -AccessRight Read -Force | Out-Null
        Write-CTLog 'Compartilhamento ja existia. Permissoes reaplicadas.'
    }
    # Remove o acesso "Everyone" que o Windows poderia ter adicionado
    $everyone = Resolve-CTSid -Sid 'S-1-1-0'
    if (Get-SmbShareAccess -Name $cfg.Share.Nome | Where-Object AccountName -eq $everyone) {
        Revoke-SmbShareAccess -Name $cfg.Share.Nome -AccountName $everyone -Force | Out-Null
    }
    Set-Content -Path (Join-Path $path 'LEIA-ME.txt') -Value "Pasta compartilhada do projeto CitizenTech. Criada em $(Get-Date -Format 'yyyy-MM-dd HH:mm')." -Encoding ASCII
    Get-SmbShare -Name $cfg.Share.Nome | Format-List Name, Path, ScopeName, FolderEnumerationMode | Out-Host
    Get-SmbShareAccess -Name $cfg.Share.Nome | Format-Table AccountName, AccessControlType, AccessRight -AutoSize | Out-Host
}

function Set-CTGPO {
    Write-CTLog 'GPO de usuarios (bloqueio do Painel de Controle)' -Nivel ETAPA
    Import-Module GroupPolicy
    $nome = $cfg.GPO.Nome
    $ouDn = "OU=$($cfg.AD.OUName),$((Get-ADDomain).DistinguishedName)"
    if (-not (Get-GPO -Name $nome -ErrorAction SilentlyContinue)) {
        New-GPO -Name $nome -Comment 'Bloqueia o Painel de Controle para usuarios da OU CitizenTech' | Out-Null
        Write-CTLog "GPO criada: $nome" -Nivel OK
    }
    $links = (Get-GPInheritance -Target $ouDn).GpoLinks | Select-Object -ExpandProperty DisplayName
    if ($links -notcontains $nome) {
        New-GPLink -Name $nome -Target $ouDn -LinkEnabled Yes | Out-Null
        Write-CTLog "GPO vinculada a $ouDn" -Nivel OK
    }
    Set-GPRegistryValue -Name $nome -Key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' `
        -ValueName 'NoControlPanel' -Type DWord -Value 1 | Out-Null
    New-Item -Path $cfg.LogsDir -ItemType Directory -Force | Out-Null
    $rel = Join-Path $cfg.LogsDir 'GPO_Report.html'
    Get-GPOReport -Name $nome -ReportType Html -Path $rel
    Write-CTLog "Relatorio da GPO: $rel" -Nivel OK
    Get-GPO -All | Select-Object DisplayName, GpoStatus | Format-Table -AutoSize | Out-Host
    Write-CTLog 'Para ver o efeito, faca logon com um usuario da OU em um cliente do dominio e rode gpupdate /force.' -Nivel AVISO
}

function Set-CTRDP {
    Write-CTLog 'Acesso remoto (RDP administrativo com NLA)' -Nivel ETAPA
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Value 1
    # Primeiro restringe, depois liga, e so entao rele as regras. Na primeira versao o
    # Set-NetFirewallRule regravava o objeto lido antes do Enable e as regras voltavam a
    # ficar desligadas (encontrado pelo Validar-Ambiente na VM em 16/11/2026).
    $grupoRdp = '@FirewallAPI.dll,-28752'
    # So aceita conexoes da rede local, nunca da internet
    Set-NetFirewallRule -Group $grupoRdp -RemoteAddress LocalSubnet
    Enable-NetFirewallRule -Group $grupoRdp
    Get-NetFirewallRule -Group $grupoRdp | Format-Table DisplayName, Enabled, Profile, Direction -AutoSize | Out-Host
    Get-Service TermService | Format-Table Name, Status, StartType -AutoSize | Out-Host
    Write-CTLog 'RDP habilitado so para a sub-rede local. Nao crie redirecionamento de porta 3389 no roteador.' -Nivel OK
}

function Set-CTAuditoria {
    Write-CTLog 'Politica de auditoria (Logon e File System, sucesso e falha)' -Nivel ETAPA
    & auditpol.exe /set /subcategory:$GuidLogon /success:enable /failure:enable | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'auditpol falhou ao configurar Logon.' }
    & auditpol.exe /set /subcategory:$GuidFileSystem /success:enable /failure:enable | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'auditpol falhou ao configurar File System.' }
    & auditpol.exe /get /subcategory:"$GuidLogon,$GuidFileSystem" | Out-Host

    # SACL na pasta do site e no compartilhamento (roteiro 5.4)
    $everyone = Resolve-CTSid -Sid 'S-1-1-0'
    $h = [System.Security.AccessControl.InheritanceFlags]'ContainerInherit,ObjectInherit'
    $p = [System.Security.AccessControl.PropagationFlags]::None
    foreach ($pasta in @($cfg.IIS.SitePath, $cfg.Share.Path)) {
        if (-not (Test-Path $pasta)) { Write-CTLog "Pasta $pasta nao existe. SACL ignorada." -Nivel AVISO; continue }
        $acl = Get-Acl $pasta -Audit
        $regra = New-Object System.Security.AccessControl.FileSystemAuditRule($everyone, 'ReadData,WriteData', $h, $p, 'Success,Failure')
        $acl.SetAuditRule($regra)
        Set-Acl -Path $pasta -AclObject $acl
        Write-CTLog "Auditoria de leitura/escrita ativada em $pasta" -Nivel OK
    }
    Write-CTLog 'O DC aplica a Default Domain Controllers Policy. Confira de novo com "auditpol /get" depois de um gpupdate.' -Nivel AVISO
}

function Set-CTDFS {
    Write-CTLog 'DFS Namespace (opcional)' -Nivel ETAPA
    $r = Install-WindowsFeature -Name FS-DFS-Namespace -IncludeManagementTools
    if (-not $r.Success) { throw 'Falha ao instalar FS-DFS-Namespace.' }
    $ns = $cfg.DFS.NamespaceName
    New-Item -Path $cfg.DFS.RootPath -ItemType Directory -Force | Out-Null
    if (-not (Get-SmbShare -Name $ns -ErrorAction SilentlyContinue)) {
        New-SmbShare -Name $ns -Path $cfg.DFS.RootPath -ReadAccess (Resolve-CTSid -Sid 'S-1-5-11') `
            -FullAccess (Resolve-CTSid -Sid 'S-1-5-32-544') | Out-Null
    }
    $raiz = "\\$($cfg.DomainName)\$ns"
    if (-not (Get-DfsnRoot -Path $raiz -ErrorAction SilentlyContinue)) {
        New-DfsnRoot -Path $raiz -TargetPath "\\$($cfg.Hostname)\$ns" -Type DomainV2 | Out-Null
        Write-CTLog "Raiz DFS criada: $raiz" -Nivel OK
    }
    $pasta = "$raiz\$($cfg.DFS.PastaDFS)"
    if (-not (Get-DfsnFolder -Path $pasta -ErrorAction SilentlyContinue)) {
        New-DfsnFolder -Path $pasta -TargetPath "\\$($cfg.Hostname)\$($cfg.Share.Nome)" | Out-Null
        Write-CTLog "Pasta DFS $pasta -> \\$($cfg.Hostname)\$($cfg.Share.Nome)" -Nivel OK
    }
    Get-DfsnRoot | Format-Table Path, Type, State -AutoSize | Out-Host
    Get-DfsnFolderTarget -Path $pasta | Format-Table Path, TargetPath, State -AutoSize | Out-Host
}

try {
    Assert-CTAdmin; Assert-CTWindowsServer
    Initialize-CTLog -LogsDir $cfg.LogsDir
    Import-Module ActiveDirectory
    $falhou = $false
    foreach ($c in $Componentes) {
        try {
            switch ($c) {
                'FileServer' { Set-CTFileServer }
                'GPO'        { Set-CTGPO }
                'RDP'        { Set-CTRDP }
                'Auditoria'  { Set-CTAuditoria }
                'DFS'        { Set-CTDFS }
            }
        } catch {
            # Um componente com erro nao impede os outros
            Write-CTLog "[$c] $($_.Exception.Message)" -Nivel ERRO
            $falhou = $true
        }
    }
    if ($falhou) { exit 1 }
} catch {
    Write-CTLog $_.Exception.Message -Nivel ERRO
    exit 1
}
