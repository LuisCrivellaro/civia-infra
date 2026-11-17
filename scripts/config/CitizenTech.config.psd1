@{
    Hostname        = 'SRV-CITIZENTECH'
    DomainName      = 'citizentech.local'
    NetbiosName     = 'CITIZENTECH'

    Rede = @{
        IPAddress    = '192.168.0.250'    
        PrefixLength = 24                 
        Gateway      = '192.168.0.1'      
        DnsServers   = @('192.168.0.250') 
    }

    AD = @{
        OUName      = 'CitizenTech'
        GrupoAdmins = 'GG_CitizenTech_Admins'
        GrupoUsuarios = 'GG_CitizenTech_Usuarios'
        Usuarios = @(
            @{ Nome = 'Ana Souza';   Sam = 'ana.souza';   Grupo = 'GG_CitizenTech_Admins' }
            @{ Nome = 'Bruno Teste'; Sam = 'bruno.teste'; Grupo = 'GG_CitizenTech_Usuarios' }
        )
    }

    IIS = @{
        SiteName   = 'CitizenTech'
        PoolName   = 'CitizenTechPool'
        SitePath   = 'C:\inetpub\citizentech'
        Porta      = 80
        ManagedRuntimeVersion = ''
        UrlTeste   = 'http://localhost/'
        UrlHealth  = 'http://localhost/health.txt'
    }

    Share = @{
        Nome = 'CitizenTech'
        Path = 'C:\Shares\CitizenTech'
    }

    DFS = @{
        NamespaceName = 'CitizenTechDFS'
        RootPath      = 'C:\DFSRoots\CitizenTechDFS'
        PastaDFS      = 'Arquivos'
    }

    GPO = @{
        Nome = 'GPO_CitizenTech_Usuarios'
    }

    ScriptsDir = 'C:\Scripts'
    LogsDir    = 'C:\Scripts\logs'

    Monitor = @{
        DcsNome          = 'CitizenTech_Monitor'
        DcsPath          = 'C:\PerfLogs\CitizenTech'
        IntervaloAmostra = 15          
        LimiteCPU        = 80          
        LimiteRAM        = 500         
        LimiteDiscoGB    = 15          
        EventSource      = 'CitizenTechMonitor'
        TarefaNome       = 'CitizenTech_Monitor_Alertas'
        TarefaIntervaloMin = 5
    }

    Recuperacao = @{
        TarefaNome         = 'CitizenTech_Recuperacao'
        TarefaIntervaloMin = 2
        ResetSegundos      = 86400
        AcoesMs            = @(5000, 10000, 30000)
    }
}
