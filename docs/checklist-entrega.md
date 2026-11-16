# Checklist da entrega

Status possíveis: Pendente, Preparado (script ou documento pronto, não executado na VM), Executado (rodou na VM), Validado (rodou e a evidência está salva), Falhou.

Um item só vira Validado com o arquivo de evidência correspondente em `evidencias/`. Ter o script pronto não basta.

Última atualização: 14/11/2026. Nada foi executado na VM até esta data.

## Infraestrutura (2 pontos)

| Item | Status | Script / evidência |
|---|---|---|
| Windows Server instalado | Pendente | manual; `evidencias/01-rede/00-winver.png` |
| Hostname configurado | Preparado | `Configurar-Rede.ps1 -Acao Renomear` |
| IP fixo configurado | Preparado | `Configurar-Rede.ps1 -Acao IPFixo` |
| DNS funcionando | Preparado | `Configurar-AD.ps1 -Etapa PromoverDominio`; `nslookup` |
| Active Directory instalado | Preparado | `Configurar-AD.ps1 -Etapa InstalarRecurso` |
| Domínio criado | Preparado | `Configurar-AD.ps1 -Etapa PromoverDominio`; `Get-ADDomain` |
| Usuários e grupos cadastrados | Preparado | `Configurar-AD.ps1 -Etapa CriarObjetos` |
| Evidências capturadas | Pendente | `evidencias/01-rede`, `evidencias/02-ad-dns` |

## IIS (2 pontos)

| Item | Status | Script / evidência |
|---|---|---|
| IIS instalado | Preparado | `Configurar-IIS.ps1` |
| Aplicação CitizenTech disponível | Preparado | página de demonstração em `app/` (testada localmente; a aplicação da equipe não foi fornecida) |
| Application pool configurado | Preparado | `Configurar-IIS.ps1`, `Configurar-Recuperacao.ps1` |
| Permissões NTFS aplicadas | Preparado | `Configurar-IIS.ps1`, `Configurar-Infraestrutura.ps1` |
| Site responde HTTP | Pendente | `Invoke-WebRequest`; navegador |
| Evidências capturadas | Pendente | `evidencias/03-iis`, `evidencias/04-ntfs-gpo` |

## Monitoramento (2 pontos)

| Item | Status | Script / evidência |
|---|---|---|
| Contador de CPU | Preparado | `Configurar-Monitoramento.ps1` |
| Contador de memória | Preparado | `Configurar-Monitoramento.ps1` |
| Contador de disco | Preparado | `Configurar-Monitoramento.ps1` |
| Data Collector Set | Preparado | `CitizenTech_Monitor` e `CitizenTech_Alertas` |
| Script de alerta | Preparado | `Monitor-Recursos.ps1` testado no Windows 11 local (não vale como evidência da VM) |
| Agendamento | Preparado | tarefa `CitizenTech_Monitor_Alertas` |
| Logs | Preparado | `C:\Scripts\logs\monitor.log`, `alertas.log`, evento 9001 |
| Evidências capturadas | Pendente | `evidencias/05-monitoramento` |

## Recuperação (1 ponto)

| Item | Status | Script / evidência |
|---|---|---|
| Recuperação configurada | Preparado | `Configurar-Recuperacao.ps1` |
| Falha controlada executada | Pendente | `Teste-Falha.ps1` |
| Indisponibilidade comprovada | Pendente | passo [4] do teste; navegador |
| Recuperação automática comprovada | Pendente | linha `RECUPERACAO AUTOMATICA COMPROVADA` + evento 7031 ou linha `AGENDADA` |
| Aplicação novamente disponível | Pendente | passo [7] do teste |
| Evidências capturadas | Pendente | `evidencias/06-teste-falha` |

## Auditoria (1 ponto)

| Item | Status | Script / evidência |
|---|---|---|
| Auditoria configurada | Preparado | `Configurar-Infraestrutura.ps1 -Componentes Auditoria` |
| Eventos disponíveis | Pendente | eventos 4624, 4625, 4663 |
| Logs do IIS | Pendente | `C:\inetpub\logs\LogFiles` |
| Evidências capturadas | Pendente | `evidencias/07-logs` |

## Funcionamento completo (2 pontos)

| Item | Status | Script / evidência |
|---|---|---|
| Aplicação funcionando | Pendente | navegador acessando o servidor |
| Serviços validados | Pendente | `Validar-Ambiente.ps1` |
| Scripts testados | Preparado | parser do PowerShell 5.1 sem erros em todos; partes de leitura testadas fora da VM (`docs/testes-realizados.md`) |
| README completo | Preparado | faltam ficha da solução, integrantes, IP real e link |
| Repositório organizado | Preparado | estrutura pronta; ainda não publicado no GitHub |
| Ficha CitizenTech | Pendente | `docs/ficha-citizentech.md` (campos da equipe) |
| Evidências associadas aos critérios | Pendente | tabela de rastreabilidade no README |
| Vídeo demonstrativo de até sete minutos | Pendente | roteiro pronto em `docs/roteiro-video.md`; vídeo não gravado |
| Link de entrega preparado | Pendente | repositório GitHub ainda não criado |

## Extras

| Item | Status | Observação |
|---|---|---|
| GPO aplicada e verificada com usuário | Pendente | precisa de logon com `bruno.teste` |
| Acesso remoto validado | Pendente | RDP de outra máquina |
| Compartilhamento acessado de um cliente | Pendente | `\\SRV-CITIZENTECH\CitizenTech` |
| DFS Namespace | Preparado (opcional) | `-Componentes DFS` |
