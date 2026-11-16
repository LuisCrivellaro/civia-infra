# Civia: infraestrutura Windows Server

Entrega da disciplina Operating Systems da Global Solution 2026 (Engenharia de Software, FIAP). Civia é a CitizenTech da equipe ASTRO.

**Vídeo de demonstração:** https://www.youtube.com/watch?v=CGmx1JJHYeI

O objetivo é montar em uma VM um Windows Server que hospede a aplicação web da Civia, com domínio, DNS, IIS, permissões NTFS, compartilhamento de arquivos, GPO, acesso remoto, monitoramento com alertas, auditoria e recuperação automática depois de uma falha provocada.

> Situação em 16/11/2026: a infraestrutura foi configurada na VM `SRV-CITIZENTECH` (Hyper-V) e `Validar-Ambiente.ps1` terminou com 49 de 49 itens aprovados ([resultado](evidencias/00-validacao/validacao-20261116-123441.txt)). A recuperação automática foi comprovada em dois testes de falha. A GPO foi demonstrada com um usuário comum. O vídeo de demonstração foi gravado na mesma VM e está no link acima. Ainda faltam três prints pedidos no roteiro (conexão RDP, acesso ao compartilhamento a partir de um cliente e aba Segurança da pasta do site). O status de cada item está em [docs/checklist-entrega.md](docs/checklist-entrega.md) e a revisão final em [docs/auditoria-final.md](docs/auditoria-final.md).

## Ficha da CitizenTech

| Campo | Valor |
|---|---|
| Nome da solução | Civia: óculos inteligentes e aplicativo de acessibilidade urbana ("a cidade se adapta a você") |
| Problema que resolve | avisos de mobilidade urbana (placas, painéis, comunicados sonoros) não chegam a pessoas com deficiência visual ou auditiva |
| Cidadão beneficiado | pessoas com deficiência visual ou auditiva |
| Cidade | São Paulo (SP), em toda a rede de metrô, trem e ônibus, começando pelas estações da Avenida Paulista, que a equipe usa no caminho até a FIAP |
| ODS | 10 (Redução das desigualdades) e 11 (Cidades e comunidades sustentáveis, meta 11.2) |
| Indicador de impacto | percentual de trajetos que o usuário conclui sem precisar pedir ajuda a outra pessoa |
| Virtualização | Hyper-V do Windows 11 Pro, VM geração 2 (4 GB de RAM, 2 vCPUs, 60 GB), switch externo (equivalente ao Bridge) |
| Tecnologias da infraestrutura | Windows Server 2022 Standard Evaluation (inglês), AD DS, DNS, IIS 10, File Server, GPO, RDP, Performance Monitor (PLA), Agendador de Tarefas, PowerShell 5.1 |
| Hospedagem | Caminho A (site estático HTML, CSS e JavaScript), pool sem código gerenciado |
| Hostname | `SRV-CITIZENTECH` |
| Domínio | `citizentech.local` (NetBIOS `CITIZENTECH`) |
| IP do servidor | `192.168.0.250/24`, gateway `192.168.0.1` |
| Credenciais de teste | contas fictícias `ana.souza` (grupo GG_CitizenTech_Admins) e `bruno.teste` (GG_CitizenTech_Usuarios). Senhas definidas na hora, fora do repositório |
| Equipe | ASTRO |
| Integrantes | Ana Luiza Santana da Rocha (RM561194); Evandro Yuji Kaibara de Oliveira (RM559274); Guilherme Rodrigues Leite (RM560131); Luís Filipe Crivellaro (RM560877); Pedro Henrique Batista Bergamin (RM559443) |
| Repositório | https://github.com/LuisCrivellaro/civia-infra |

A ficha completa, com ODS e indicador de impacto, fica em [docs/ficha-citizentech.md](docs/ficha-citizentech.md).

Sobre a aplicação: o roteiro pede a aplicação web desenvolvida em outra disciplina, mas ela não estava disponível para este repositório. A pasta [app/](app/) tem uma página estática de demonstração com os dados da Civia, marcada como tal na própria tela, que serve para provar a hospedagem no IIS. Ela não é a aplicação final da equipe. Quando a aplicação real estiver pronta, basta trocar o conteúdo de `app/` e rodar `Configurar-IIS.ps1` de novo. Se ela tiver backend (Node.js, Python ou .NET), o caminho passa a ser o B do roteiro e o pool precisa de outro runtime.

## Arquitetura

```
 Cliente da rede local (navegador, RDP, \\SRV-CITIZENTECH)
                    |
  switch externo do Hyper-V (equivale ao Bridge)
                    |
 +---------------------------------------------------------------+
 | SRV-CITIZENTECH  (Windows Server 2022, IP fixo 192.168.0.250) |
 |  AD DS + DNS ...... citizentech.local, OU CitizenTech,        |
 |                     grupos GG_CitizenTech_Admins/_Usuarios    |
 |  IIS .............. site CitizenTech :80 -> pool              |
 |                     CitizenTechPool -> C:\inetpub\citizentech |
 |  File Server ...... \\SRV-CITIZENTECH\CitizenTech             |
 |  GPO .............. GPO_CitizenTech_Usuarios (OU CitizenTech) |
 |  Monitoramento .... DCS CitizenTech_Monitor e _Alertas,       |
 |                     tarefa Monitor-Recursos.ps1 (5 min)       |
 |  Recuperação ...... sc failure W3SVC/WAS + tarefa             |
 |                     Recupera-Site.ps1 (2 min)                 |
 |  Auditoria ........ auditpol Logon/File System, SACL, logs IIS|
 +---------------------------------------------------------------+
```

Detalhes e o motivo de cada decisão: [docs/arquitetura.md](docs/arquitetura.md).

## Estrutura do repositório

```
README.md                  este arquivo
prompts.md                 registro do uso de IA (exigência da GS)
app/                       página estática de demonstração (Caminho A)
docs/
  roteiro-configuracao.md  passo a passo na VM, na ordem certa
  ficha-citizentech.md     ficha da solução e da parte de Operating Systems
  arquitetura.md           desenho, decisões e conceitos para a apresentação
  analise-requisitos.md    requisitos do roteiro e ajustes nos comandos do PDF
  checklist-entrega.md     status real de cada item
  roteiro-video.md         roteiro do vídeo de até 7 minutos
  testes-realizados.md     o que já foi testado, onde e com qual resultado
  auditoria-final.md       revisão final contra os PDFs, riscos e pendências
  AI_HANDOFF.md            ponto de retomada do trabalho
  referencias/             PDFs da atividade (fora do Git, ver .gitignore)
scripts/
  config/CitizenTech.config.psd1   valores do ambiente (hostname, IP, nomes, limites)
  lib/CitizenTech.Common.psm1      funções compartilhadas
  host/Criar-VM-HyperV.ps1         cria a VM no Hyper-V do computador host
  Configurar-Rede.ps1              etapa 1: diagnóstico, hostname, IP fixo
  Configurar-AD.ps1                etapa 1: AD DS, domínio, OU, grupos, usuários
  Configurar-IIS.ps1               etapa 2: IIS, pool, site, NTFS
  Configurar-Infraestrutura.ps1    etapa 3: File Server, GPO, RDP, auditoria, DFS
  Configurar-Monitoramento.ps1     etapa 4: Data Collector Sets e tarefa agendada
  Monitor-Recursos.ps1             etapa 4: script de alerta por limiar
  Configurar-Recuperacao.ps1       etapa 5: sc failure, pool, tarefa de recuperação
  Recupera-Site.ps1                etapa 5: verifica e recupera W3SVC, pool, site
  Teste-Falha.ps1                  etapa 5: falha controlada e prova da recuperação
  Validar-Ambiente.ps1             verifica todos os critérios (só leitura)
  Coletar-Evidencias.ps1           salva a saída real dos comandos em evidencias/
  Demo-Video.ps1                   roda a demonstração do vídeo em 8 partes, com pausa entre elas
evidencias/                prints e saídas reais, uma pasta por etapa
```

## Como executar

Tudo roda na VM, em um PowerShell aberto como Administrador, a partir da pasta do repositório copiada para o servidor (por exemplo `C:\civia-infra`). O passo a passo completo, com o que conferir em cada etapa, está em [docs/roteiro-configuracao.md](docs/roteiro-configuracao.md). Resumo:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
cd C:\civia-infra\scripts

.\Configurar-Rede.ps1                                  # só mostra a rede; ajuste a config
.\Configurar-Rede.ps1 -Acao Renomear -Reiniciar
.\Configurar-Rede.ps1 -Acao IPFixo -InterfaceIndex <n>
.\Configurar-AD.ps1 -Etapa InstalarRecurso
.\Configurar-AD.ps1 -Etapa PromoverDominio             # reinicia a VM
.\Configurar-AD.ps1 -Etapa CriarObjetos
.\Configurar-IIS.ps1
.\Configurar-Infraestrutura.ps1                        # -Componentes DFS é opcional
.\Configurar-Monitoramento.ps1
.\Configurar-Recuperacao.ps1
C:\Scripts\Teste-Falha.ps1                             # só na VM; pede confirmação
.\Validar-Ambiente.ps1
.\Coletar-Evidencias.ps1
```

Os valores do ambiente ficam todos em `scripts/config/CitizenTech.config.psd1`. Antes de começar, confira IP, máscara e gateway com `Configurar-Rede.ps1` (sem parâmetros ele só lê) e ajuste o arquivo.

## Configurações principais

| Item | Valor |
|---|---|
| OU | `OU=CitizenTech,DC=citizentech,DC=local` |
| Grupos | `GG_CitizenTech_Admins`, `GG_CitizenTech_Usuarios` (globais, segurança) |
| Site IIS | `CitizenTech`, porta 80, `C:\inetpub\citizentech` |
| Pool | `CitizenTechPool`, sem código gerenciado, `autoStart` ligado, rapid fail protection desligado |
| NTFS do site | `IIS_IUSRS` leitura e execução; `GG_CitizenTech_Admins` modificar |
| Compartilhamento | `\\SRV-CITIZENTECH\CitizenTech` em `C:\Shares\CitizenTech`: admins controle total, Domain Users leitura, enumeração baseada em acesso |
| GPO | `GPO_CitizenTech_Usuarios`, vinculada à OU, bloqueia o Painel de Controle (`NoControlPanel=1`) |
| RDP | habilitado com NLA, firewall restrito à sub-rede local, sem a função RDS |
| Limites de alerta | CPU acima de 80 %, memória disponível abaixo de 500 MB, disco C: abaixo de 15 GB livres |
| Recuperação W3SVC/WAS | `reset= 86400 actions= restart/5000/restart/10000/restart/30000` |
| Tarefas agendadas | `CitizenTech_Monitor_Alertas` (5 min), `CitizenTech_Recuperacao` (2 min), `CitizenTech_DCS_Inicio` (no boot) |
| Logs | `C:\Scripts\logs` (monitor, alertas, recuperação, teste de falha), `C:\PerfLogs\CitizenTech` (.blg), `C:\inetpub\logs\LogFiles` (IIS) |

## Ajustes em relação aos comandos do roteiro

Seguimos o roteiro do professor, mas alguns comandos do PDF não funcionam como estão ou não provam o que o critério pede. Os principais:

- Recuperação automática: o PDF para o W3SVC com `Stop-Service` e espera a recuperação do `sc.exe failure`. O Windows só aplica essas ações quando o serviço termina inesperadamente, não numa parada limpa. No teste do PDF, quem religa o serviço acaba sendo o `Start-Service` manual do próprio script. Por isso o `Teste-Falha.ps1` tem o modo `Crash` (encerra o processo do serviço, o SCM recupera) e o modo `Parada` (a tarefa `CitizenTech_Recuperacao` recupera), e só declara recuperação automática quando nenhuma ação do script foi necessária.
- Contadores: em um Windows em português, `Get-Counter "\Processor(_Total)\% Processor Time"` falha (testamos: "O objeto especificado não foi encontrado no computador"). Os scripts traduzem o nome para o idioma do sistema. No Data Collector Set o PDF ainda usa `\\` (que em PowerShell fica duplicado) e um método `AddCounter` que o coletor do PLA não tem.
- Nomes que mudam com o idioma (`Domain Users`, `Everyone`, grupo de firewall "Área de Trabalho Remota", subcategorias do `auditpol`) são tratados por SID ou GUID.
- O site novo na porta 80 conflita com o Default Web Site, que é parado.
- `New-DfsnRoot` no PDF recebe um caminho local como destino; o correto é um compartilhamento UNC.

A lista completa, com o motivo de cada ajuste, está em [docs/analise-requisitos.md](docs/analise-requisitos.md).

## Validação

`Validar-Ambiente.ps1` confere 49 itens ligados aos seis critérios e grava o resultado em `evidencias/00-validacao/` (TXT e CSV), com `PASSOU`, `FALHOU` ou `ERRO` em cada linha. Ele não altera nada no servidor.

`Coletar-Evidencias.ps1` roda os comandos que o roteiro pede para printar e salva a saída real em `evidencias/<etapa>/`. Os prints de tela (navegador, `services.msc`, Monitor de Desempenho, Visualizador de Eventos, logon de usuário com a GPO) são manuais; a lista de cada pasta está em [evidencias/README.md](evidencias/README.md).

## Rastreabilidade

| Critério (pontos) | Requisito | Script | Validação | Evidência | Status |
|---|---|---|---|---|---|
| Rede e identidade (2,0) | hostname, IP fixo, DNS, domínio no AD, usuários e grupos | `Configurar-Rede.ps1`, `Configurar-AD.ps1` | `ipconfig /all`, `nslookup`, `Get-ADDomain`, `Get-DnsServerZone`, `Get-ADUser`, `Get-ADGroupMember` | [evidencias/01-rede](evidencias/01-rede), [evidencias/02-ad-dns](evidencias/02-ad-dns) | Validado |
| Aplicação no IIS (2,0) | site, pool, dependências, pasta, NTFS, File Server | `Configurar-IIS.ps1`, `Configurar-Infraestrutura.ps1` | `Get-Website`, `Get-WebAppPoolState`, `Invoke-WebRequest`, `Get-Acl`, `Get-SmbShare` | [evidencias/03-iis](evidencias/03-iis), [evidencias/04-ntfs-gpo](evidencias/04-ntfs-gpo) | Validado; faltam os prints da aba Segurança e do acesso ao compartilhamento por um cliente |
| Monitoramento (2,0) | contadores de CPU, memória e disco, alertas, agendamento | `Configurar-Monitoramento.ps1`, `Monitor-Recursos.ps1` | `logman query`, `Get-Counter`, execução do script, `Get-ScheduledTaskInfo` | [evidencias/05-monitoramento](evidencias/05-monitoramento) | Validado (alerta real com CPU em 100 %, gráfico no Monitor de Desempenho) |
| Tolerância a falhas (1,0) | recuperação configurada, falha provocada, recuperação automática | `Configurar-Recuperacao.ps1`, `Teste-Falha.ps1`, `Recupera-Site.ps1` | `sc.exe qfailure W3SVC`, saída do teste, `recuperacao.log` | [evidencias/06-teste-falha](evidencias/06-teste-falha) | Validado (Crash: SCM em 15,7 s; Parada: tarefa em 60,7 s) |
| Auditoria e logs (1,0) | auditpol, SACL, eventos, logs do IIS | `Configurar-Infraestrutura.ps1` | `auditpol /get`, `Get-WinEvent`, logs do IIS | [evidencias/07-logs](evidencias/07-logs) | Validado |
| Funcionamento completo (2,0) | tudo funcionando junto, GPO, RDP, documentação, vídeo | `Validar-Ambiente.ps1`, `Coletar-Evidencias.ps1`, `Configurar-Infraestrutura.ps1` | bloco de validação final (roteiro 8.1), `Get-GPO -All`, logon do `bruno.teste` | [evidencias/00-validacao](evidencias/00-validacao), [evidencias/04-ntfs-gpo](evidencias/04-ntfs-gpo), [vídeo](https://www.youtube.com/watch?v=CGmx1JJHYeI) | Validado (49/49, GPO com usuário comum, vídeo gravado); falta o print da conexão RDP |

Os status seguem a escala: Pendente, Preparado, Executado, Validado, Falhou. Só mudam depois de rodar na VM e ter a evidência salva.

## Limitações

- A VM foi configurada no Hyper-V do computador de desenvolvimento, em rede de casa (switch externo). O sistema está em inglês porque o Evaluation Center não oferece ISO em português. O registro de cada execução, inclusive as que falharam, está em [docs/testes-realizados.md](docs/testes-realizados.md).
- No modo Crash, encerrar só o serviço W3SVC não derruba o site: o processo do pool (`w3wp.exe`) continua atendendo. O teste derruba os dois para simular a queda real.
- Para mostrar a GPO, o `bruno.teste` precisou fazer logon no próprio controlador de domínio. Isso exigiu liberar "Allow log on locally" para o grupo `GG_CitizenTech_Usuarios` na Default Domain Controllers Policy só durante o teste; a mudança foi desfeita logo depois e conferida com `secedit` (ver [docs/testes-realizados.md](docs/testes-realizados.md)). Usuários comuns não fazem logon local em um controlador de domínio, então o ideal é uma segunda VM cliente no domínio. O roteiro de configuração explica a alternativa.
- DFS Replication não foi configurado porque precisa de um segundo servidor. O DFS Namespace (opcional) foi configurado: `\\citizentech.local\CitizenTechDFS`.
- Os PDFs da atividade ficam fora do Git para não publicar material da FIAP.
- Nas evidências, os endereços IPv6 públicos da conexão de internet foram trocados por `[IPv6-publico-removido]`.

## Uso de IA

O desenvolvimento teve apoio do Claude Code, que escreveu os scripts e documentos e executou a configuração e os testes na VM com autorização do aluno. Os prompts, a cronologia e a divisão entre o que a IA fez e o que a equipe fez estão em [prompts.md](prompts.md).

## Entrega

Link do repositório na tarefa de Operating Systems do Teams, enviado por um único integrante, até 19/11/2026 às 23h55 (prazo do roteiro e do documento geral da GS).
