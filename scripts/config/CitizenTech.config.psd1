# Configuracao central do laboratorio CitizenTech (Operating Systems - GS FIAP 2026)
#
# Todos os scripts de configuracao e validacao leem este arquivo.
# Valores marcados com AJUSTAR dependem da rede real da VM: confira com
# "Configurar-Rede.ps1 -Acao Diagnosticar" antes de aplicar.
#
# Nao coloque senhas aqui. Os scripts pedem senhas com Read-Host -AsSecureString.
@{
    # Identidade do servidor
    Hostname        = 'SRV-CITIZENTECH'
    DomainName      = 'citizentech.local'
    NetbiosName     = 'CITIZENTECH'

    # Rede (AJUSTAR conforme a rede da VM)
    Rede = @{
        IPAddress    = '192.168.0.250'    # rede de casa 192.168.0.0/24; .250 nao respondeu ao ping em 15/11/2026
        PrefixLength = 24                 # AJUSTAR: 24 = 255.255.255.0
        Gateway      = '192.168.0.1'      # gateway (roteador) da rede de casa
        # O DC aponta para ele mesmo como DNS (exigencia do AD).
        # Antes da promocao o proprio IP ainda nao responde DNS; isso e esperado.
        DnsServers   = @('192.168.0.250') # o proprio servidor
    }

    # Active Directory
    AD = @{
        OUName      = 'CitizenTech'
        GrupoAdmins = 'GG_CitizenTech_Admins'
        GrupoUsuarios = 'GG_CitizenTech_Usuarios'
        # Contas ficticias de teste (nao sao integrantes reais da equipe)
        Usuarios = @(
            @{ Nome = 'Ana Souza';   Sam = 'ana.souza';   Grupo = 'GG_CitizenTech_Admins' }
            @{ Nome = 'Bruno Teste'; Sam = 'bruno.teste'; Grupo = 'GG_CitizenTech_Usuarios' }
        )
    }

    # IIS
    IIS = @{
        SiteName   = 'CitizenTech'
        PoolName   = 'CitizenTechPool'
        SitePath   = 'C:\inetpub\citizentech'
        Porta      = 80
        # Caminho A (aplicacao estatica): managedRuntimeVersion vazio
        ManagedRuntimeVersion = ''
        UrlTeste   = 'http://localhost/'
        UrlHealth  = 'http://localhost/health.txt'
    }

    # File Server
    Share = @{
        Nome = 'CitizenTech'
        Path = 'C:\Shares\CitizenTech'
    }

    # DFS (opcional)
    DFS = @{
        NamespaceName = 'CitizenTechDFS'
        RootPath      = 'C:\DFSRoots\CitizenTechDFS'
        PastaDFS      = 'Arquivos'
    }

    # GPO
    GPO = @{
        Nome = 'GPO_CitizenTech_Usuarios'
    }

    # Pasta de execucao no servidor (mesma usada no roteiro do professor)
    ScriptsDir = 'C:\Scripts'
    LogsDir    = 'C:\Scripts\logs'

    # Monitoramento
    Monitor = @{
        DcsNome          = 'CitizenTech_Monitor'
        DcsPath          = 'C:\PerfLogs\CitizenTech'
        IntervaloAmostra = 15          # segundos (Data Collector Set)
        LimiteCPU        = 80          # % de uso
        LimiteRAM        = 500         # MB disponiveis
        LimiteDiscoGB    = 15          # GB livres em C:
        EventSource      = 'CitizenTechMonitor'
        TarefaNome       = 'CitizenTech_Monitor_Alertas'
        TarefaIntervaloMin = 5
    }

    # Recuperacao
    Recuperacao = @{
        TarefaNome         = 'CitizenTech_Recuperacao'
        TarefaIntervaloMin = 2
        # sc.exe failure W3SVC reset= 86400 actions= restart/5000/restart/10000/restart/30000
        ResetSegundos      = 86400
        AcoesMs            = @(5000, 10000, 30000)
    }
}
