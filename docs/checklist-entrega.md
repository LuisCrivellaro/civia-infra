# Checklist da entrega

Status possíveis: Pendente, Preparado (script ou documento pronto, não executado na VM), Executado (rodou na VM), Validado (rodou e a evidência está salva), Falhou.

Um item só vira Validado com o arquivo de evidência correspondente em `evidencias/`.

Última atualização: 16/11/2026, depois da configuração completa da VM. `Validar-Ambiente.ps1` terminou com 49 de 49 itens PASSOU (`evidencias/00-validacao/validacao-20261116-012533.txt`).

## Infraestrutura (2 pontos)

| Item | Status | Evidência |
|---|---|---|
| Windows Server instalado | Validado | `evidencias/01-rede/00-winver.png`, `01-rede/02-winver-versao.txt` |
| Hostname configurado | Validado | `01-rede/01-hostname.txt` |
| IP fixo configurado | Validado | `01-rede/03-ipconfig-all.txt` (192.168.0.250/24, DHCP desligado) |
| DNS funcionando | Validado | `02-ad-dns/02-nslookup.txt`, `02-ad-dns/03-get-dnsserverzone.txt` |
| Active Directory instalado | Validado | `00-validacao/00-ficha-infraestrutura.txt` (AD-Domain-Services Installed) |
| Domínio criado | Validado | `02-ad-dns/01-get-addomain.txt` |
| Usuários e grupos cadastrados | Validado | `02-ad-dns/04-usuarios.txt`, `02-ad-dns/05-grupos.txt` |
| Evidências capturadas | Validado (texto) | prints de tela do terminal ainda opcionais |

## IIS (2 pontos)

| Item | Status | Evidência |
|---|---|---|
| IIS instalado | Validado | `03-iis/01-windowsfeature-web.txt` |
| Aplicação CitizenTech disponível | Validado | página de demonstração da Civia; `03-iis/06-navegador-site-pelo-ip.jpg` (aberta do PC host pelo IP) |
| Application pool configurado | Validado | `03-iis/03-get-webapppoolstate.txt` |
| Permissões NTFS aplicadas | Validado | `03-iis/05-get-acl-site.txt`, `04-ntfs-gpo/02-get-acl-share.txt` |
| Site responde HTTP | Validado | `03-iis/04-invoke-webrequest.txt` (200) |
| Evidências capturadas | Validado | falta só o print opcional da aba Segurança |

## Monitoramento (2 pontos)

| Item | Status | Evidência |
|---|---|---|
| Contador de CPU | Validado | `05-monitoramento/01-logman-query.txt` |
| Contador de memória | Validado | idem |
| Contador de disco | Validado | idem |
| Data Collector Set | Validado | `CitizenTech_Monitor` e `CitizenTech_Alertas` em Running; `05-monitoramento/02-perflogs.txt` |
| Script de alerta | Validado | alerta real com CPU em 100 %: `05-monitoramento/07-alertas.txt` (evento 9001) |
| Agendamento | Validado | `05-monitoramento/05-tarefa-agendada.txt` (resultado 0) |
| Logs | Validado | `07-logs/logs-scripts/monitor.log`, `alertas.log`, `05-monitoramento/08-alertas-perfmon.txt` (evento 2031) |
| Evidências capturadas | Executado | falta o print do Monitor de Desempenho com o gráfico e do Agendador com histórico |

## Recuperação (1 ponto)

| Item | Status | Evidência |
|---|---|---|
| Recuperação configurada | Validado | `06-teste-falha/01-sc-qfailure.txt`, `02-pool-recuperacao.txt` |
| Falha controlada executada | Validado | `06-teste-falha/teste-falha-*.log` (3 execuções) |
| Indisponibilidade comprovada | Validado | passo [4] com timeout nos testes Crash 01:19:51 e Parada 01:20:34 |
| Recuperação automática comprovada | Validado | Crash: SCM, evento 7031, 15,7 s. Parada: tarefa agendada, 60,7 s (`03-teste-falha-resumo.txt`) |
| Aplicação novamente disponível | Validado | passo [7] HTTP 200 nos dois testes |
| Evidências capturadas | Executado | falta o print da aba Recuperação no `services.msc` e do navegador caindo e voltando |

## Auditoria (1 ponto)

| Item | Status | Evidência |
|---|---|---|
| Auditoria configurada | Validado | `07-logs/01-auditpol.txt` (Logon e File System com Success and Failure, mantido após `gpupdate /force`) |
| Eventos disponíveis | Validado | `07-logs/03-logon-4624-4625.txt`, `07-logs/04-acesso-arquivo-4663.txt` |
| Logs do IIS | Validado | `07-logs/u_ex261116.log`, `07-logs/06-logs-iis.txt` |
| Evidências capturadas | Executado | falta o print do Visualizador de Eventos |

## Funcionamento completo (2 pontos)

| Item | Status | Evidência |
|---|---|---|
| Aplicação funcionando | Validado | `03-iis/06-navegador-site-pelo-ip.jpg` |
| Serviços validados | Validado | `00-validacao/validacao-20261116-012533.txt` (49/49) |
| Scripts testados | Validado | todos rodaram na VM; dois bugs encontrados e corrigidos (ver `docs/testes-realizados.md`) |
| README completo | Executado | faltam descrição da Civia, ODS e integrantes |
| Repositório organizado | Validado | https://github.com/LuisCrivellaro/civia-infra |
| Ficha CitizenTech | Pendente | campos da equipe em `docs/ficha-citizentech.md` |
| Evidências associadas aos critérios | Validado | tabela de rastreabilidade no README |
| Vídeo demonstrativo de até sete minutos | Pendente | roteiro pronto em `docs/roteiro-video.md`; vídeo não gravado |
| Link de entrega preparado | Executado | link pronto; envio no Teams não feito |

## Extras

| Item | Status | Evidência |
|---|---|---|
| GPO aplicada e verificada com usuário | Executado | GPO vinculada e com `NoControlPanel=1` (`04-ntfs-gpo/04-gpo-link-valor.txt`); falta o logon do `bruno.teste` |
| Acesso remoto validado | Executado | RDP ativo, firewall só na rede local, porta 3389 aberta a partir do PC host; falta a conexão RDP com print |
| Compartilhamento acessado | Validado | `04-ntfs-gpo/01-get-smbshare.txt`; acesso pelo namespace DFS testado |
| DFS Namespace | Validado | `04-ntfs-gpo/06-get-dfsnroot.txt` (`\\citizentech.local\CitizenTechDFS` Online) |
