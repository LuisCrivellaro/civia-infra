
# Civia — Infraestrutura Windows Server

Este repositório reúne a parte de Operating Systems da Global Solution 2026, do curso de Engenharia de Software da FIAP. O projeto da nossa equipe, ASTRO, se chama **Civia** e tem como proposta tornar os deslocamentos pela cidade mais acessíveis para pessoas com deficiência visual ou auditiva.

Nesta etapa, trabalhamos na infraestrutura de um servidor Windows para hospedar uma demonstração web da Civia. O ambiente inclui domínio, DNS, IIS, controle de acesso, compartilhamento de arquivos, monitoramento, auditoria e recuperação de serviços.

## Links do projeto

- [Página da Civia](https://civiaglass.vercel.app/)
- [Vídeo de apresentação da Civia](https://youtu.be/1Sq9_qKbIO8)
- [Demonstração de Operating Systems](https://www.youtube.com/watch?v=CGmx1JJHYeI)

## Sobre a Civia

A Civia combina óculos inteligentes e um aplicativo para ajudar na identificação de informações durante o trajeto. A ideia é captar avisos e elementos do ambiente com câmera e microfone e apresentar essas informações por áudio, legendas ou vibração.

O projeto foi pensado para a mobilidade urbana de São Paulo, especialmente metrô, trem e ônibus. A proposta inicial considera as estações da Avenida Paulista, por fazerem parte do deslocamento da equipe até a FIAP.

| Informação | Dados do projeto |
|---|---|
| Solução | Civia — óculos inteligentes e aplicativo de acessibilidade urbana |
| Público | Pessoas com deficiência visual ou auditiva |
| Problema | Dificuldade de acesso a avisos visuais e sonoros durante o deslocamento |
| Cidade | São Paulo (SP) |
| ODS | 10 — Redução das Desigualdades; 11 — Cidades e Comunidades Sustentáveis (meta 11.2) |
| Indicador de impacto | Percentual de trajetos concluídos sem acionar a função de pedir ajuda |
| Equipe | ASTRO |

A descrição da solução e os dados da equipe também estão em [docs/ficha-citizentech.md](docs/ficha-citizentech.md).

### Integrantes

| Nome | RM |
|---|---|
| Ana Luiza Santana da Rocha | RM561194 |
| Evandro Yuji Kaibara de Oliveira | RM559274 |
| Guilherme Rodrigues Leite | RM560131 |
| Luís Filipe Crivellaro | RM560877 |
| Pedro Henrique Batista Bergamin | RM559443 |

## Ambiente utilizado

Montamos a máquina virtual no Hyper-V do Windows 11 Pro, com um switch externo para permitir o acesso pela rede local. O servidor utiliza Windows Server 2022 Standard Evaluation, em inglês.

| Item | Configuração |
|---|---|
| Virtualização | Hyper-V, VM geração 2 |
| Recursos da VM | 4 GB de RAM, 2 vCPUs e disco de 60 GB |
| Sistema operacional | Windows Server 2022 Standard Evaluation |
| Hostname | `SRV-CITIZENTECH` |
| IP fixo | `192.168.0.250/24` |
| Gateway | `192.168.0.1` |
| Domínio | `citizentech.local` |
| NetBIOS | `CITIZENTECH` |
| Recursos | AD DS, DNS, IIS 10, File Server, GPO, RDP e Performance Monitor |
| Automação | PowerShell 5.1 e Agendador de Tarefas |
| Hospedagem | Caminho A — site estático em HTML, CSS e JavaScript |
| Contas de teste | `ana.souza` e `bruno.teste` |

As contas são fictícias. As senhas não foram incluídas no repositório.

### Aplicação no IIS

Como a aplicação web final da equipe não fazia parte desta entrega, usamos a página estática que está em [`app/`](app/). Ela apresenta a Civia e permite verificar a hospedagem no IIS, mas não substitui o aplicativo completo.

O site foi publicado em `C:\inetpub\citizentech`, na porta 80, com o nome `CitizenTech` e o pool `CitizenTechPool`, configurado sem código gerenciado. Essa configuração corresponde ao Caminho A. Uma futura aplicação com backend exigiria a instalação do runtime correspondente e outra configuração de hospedagem.

Endereços utilizados na rede local:

- `http://192.168.0.250`
- `http://srv-citizentech.citizentech.local` (para máquinas que utilizam o DNS do servidor)

## Estrutura do repositório

```text
civia-infra/
├── README.md
├── app/
│   ├── index.html
│   ├── style.css
│   └── app.js
├── docs/
│   ├── ficha-citizentech.md
│   └── roteiro-configuracao.md
├── scripts/
│   ├── config/CitizenTech.config.psd1
│   ├── lib/CitizenTech.Common.psm1
│   ├── host/Criar-VM-HyperV.ps1
│   ├── Configurar-Rede.ps1
│   ├── Configurar-AD.ps1
│   ├── Configurar-IIS.ps1
│   ├── Configurar-Infraestrutura.ps1
│   ├── Configurar-Monitoramento.ps1
│   ├── Monitor-Recursos.ps1
│   ├── Configurar-Recuperacao.ps1
│   ├── Recupera-Site.ps1
│   ├── Teste-Falha.ps1
│   ├── Validar-Ambiente.ps1
│   ├── Coletar-Evidencias.ps1
│   └── Demo-Video.ps1
└── evidencias/
    ├── 00-validacao/
    ├── 01-rede/
    ├── 02-ad-dns/
    ├── 03-iis/
    ├── 04-ntfs-gpo/
    ├── 05-monitoramento/
    ├── 06-teste-falha/
    └── 07-logs/
```

A pasta `docs/` reúne a ficha do projeto e o registro da configuração. Os scripts ficam separados por função, e `evidencias/` contém as capturas e saídas dos testes. A árvore acima mostra os arquivos principais; arquivos adicionais de log podem aparecer nas pastas de evidências.

## Configuração do servidor

A configuração foi feita pelo PowerShell, com privilégios de administrador na VM. Os parâmetros usados pelos scripts foram centralizados em `scripts/config/CitizenTech.config.psd1`, incluindo IP, nomes do ambiente e limites de monitoramento.

Esta foi a sequência de comandos de configuração e validação:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
cd C:\civia-infra\scripts

.\Configurar-Rede.ps1
.\Configurar-Rede.ps1 -Acao Renomear -Reiniciar
.\Configurar-Rede.ps1 -Acao IPFixo -InterfaceIndex <ifIndex>
.\Configurar-AD.ps1 -Etapa InstalarRecurso
.\Configurar-AD.ps1 -Etapa PromoverDominio
.\Configurar-AD.ps1 -Etapa CriarObjetos
.\Configurar-IIS.ps1
.\Configurar-Infraestrutura.ps1
.\Configurar-Monitoramento.ps1
.\Configurar-Recuperacao.ps1
C:\Scripts\Teste-Falha.ps1
.\Validar-Ambiente.ps1
.\Coletar-Evidencias.ps1
```

O índice da interface de rede depende da configuração de cada VM. A sequência detalhada, incluindo reinicializações, testes e registros, ficou em [docs/roteiro-configuracao.md](docs/roteiro-configuracao.md).

### Serviços e permissões

| Componente | Configuração aplicada |
|---|---|
| Active Directory | OU `CitizenTech`, com os grupos `GG_CitizenTech_Admins` e `GG_CitizenTech_Usuarios` |
| DNS | Zona `citizentech.local` e resolução do hostname do servidor |
| IIS | Site `CitizenTech`, porta 80, pool `CitizenTechPool` |
| NTFS do site | `IIS_IUSRS` com leitura e execução; administradores do projeto com permissão de modificação |
| Compartilhamento | `\\SRV-CITIZENTECH\CitizenTech`, em `C:\Shares\CitizenTech` |
| Acesso ao compartilhamento | Administradores com controle total; `Domain Users` com leitura |
| GPO | `GPO_CitizenTech_Usuarios`, vinculada à OU, com `NoControlPanel=1` |
| RDP | Acesso habilitado com NLA e firewall limitado à rede local |
| Auditoria | Logon e File System, com registros no Event Viewer e nos logs do IIS |

### Monitoramento

Criamos os conjuntos `CitizenTech_Monitor` e `CitizenTech_Alertas` no Monitor de Desempenho. O primeiro coleta informações sobre CPU, memória e disco, enquanto o segundo está ligado aos alertas definidos para o ambiente.

Os limites utilizados foram CPU acima de 80%, memória disponível abaixo de 500 MB e espaço livre na unidade C: abaixo de 15 GB. A tarefa `CitizenTech_Monitor_Alertas` executa o script de verificação a cada cinco minutos. Os registros ficam em `C:\Scripts\logs\` e as coletas de desempenho em `C:\PerfLogs\CitizenTech\`.

Também foi configurada a tarefa `CitizenTech_DCS_Inicio` para iniciar a coleta com o sistema.

### Recuperação dos serviços

No IIS, o pool ficou com inicialização automática. Para os serviços W3SVC e WAS, configuramos as ações de recuperação do Windows com tentativas de reinício. A tarefa `CitizenTech_Recuperacao` também faz uma verificação a cada dois minutos, usando `Recupera-Site.ps1`.

Foram utilizados dois tipos de teste:

- **Crash:** interrupção inesperada, com recuperação pelo Service Control Manager (SCM).
- **Parada:** parada controlada, com recuperação pela tarefa agendada.

Essa separação foi necessária porque uma parada normal por `Stop-Service` não aciona as mesmas ações do Windows previstas para uma falha inesperada. No teste de Crash, também foi necessário interromper o processo do pool para que o site realmente ficasse indisponível.

## Ajustes feitos durante a configuração

Algumas partes precisaram de ajustes durante a montagem do ambiente:

- Os contadores do `Get-Counter` podem mudar de nome conforme o idioma do Windows. Os scripts tratam essa diferença.
- Grupos, regras de firewall e categorias de auditoria que dependem do idioma foram tratados por SID ou GUID.
- O `Default Web Site` foi interrompido para liberar a porta 80 para a Civia.
- O DFS Namespace foi configurado usando um compartilhamento de rede como destino. O DFS Replication não foi utilizado, pois o ambiente possui apenas um servidor.
- Os testes de falha foram separados para identificar quando a recuperação ocorreu automaticamente e quando seria necessária uma ação manual.

## Observações do ambiente

A VM ficou no Hyper-V de um computador da equipe e foi conectada à rede local por um switch externo. O endereço `192.168.0.250` é dessa rede, então o site não fica disponível publicamente por esse IP.

Para verificar a política de bloqueio do Painel de Controle, a conta `bruno.teste` foi utilizada em um teste de logon no controlador de domínio. A permissão temporária de logon local foi retirada após o teste, e a configuração foi conferida com `secedit`. Em um ambiente com mais máquinas, esse teste poderia ser feito em uma VM cliente ingressada no domínio.

O DFS Namespace foi configurado em `\\citizentech.local\CitizenTechDFS`, mas não houve replicação entre servidores. Os PDFs de referência ficaram fora do Git, e os endereços IPv6 públicos identificados nas evidências foram ocultados antes da publicação.

A página hospedada nesta entrega continua sendo uma demonstração estática da Civia, não o aplicativo final da equipe.
