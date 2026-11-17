# Checklist da entrega

Status possíveis: Pendente, Preparado (script ou documento pronto, não executado na VM), Executado (rodou na VM), Validado (rodou e a evidência está salva), Falhou.

Um item só vira Validado com o arquivo de evidência correspondente em `evidencias/`.

Última atualização: 16/11/2026 às 22h05, depois da auditoria final (`docs/auditoria-final.md`) e dos prints de rede, AD e DNS, monitoramento e validação final. A execução de `Validar-Ambiente.ps1` às 22:03 terminou com 49 de 49 itens PASSOU (prints `evidencias/00-validacao/01-` e `02-validacao-final-49-de-49-parte*.png`; a de 12:34 está em texto em `validacao-20261116-123441.txt`). Esse resultado cobre a configuração do servidor; os prints manuais e o envio estão nas linhas abaixo.

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
| Evidências capturadas | Validado | saídas de comando em `01-rede/` e `02-ad-dns/`, `01-rede/00-winver.png`, `01-rede/05-ip-fixo-dominio-powershell.png`, `02-ad-dns/06-ad-dns-powershell.png` |

## IIS (2 pontos)

| Item | Status | Evidência |
|---|---|---|
| IIS instalado | Validado | `03-iis/01-windowsfeature-web.txt` |
| Aplicação CitizenTech disponível | Validado, com ressalva | a página publicada é a de demonstração em `app/`, não a aplicação web final da equipe; `03-iis/06-navegador-site-pelo-ip.jpg` (aberta do PC host pelo IP) |
| Application pool configurado | Validado | `03-iis/03-get-webapppoolstate.txt` |
| Permissões NTFS aplicadas | Validado | `03-iis/05-get-acl-site.txt`, `04-ntfs-gpo/02-get-acl-share.txt` |
| Site responde HTTP | Validado | `03-iis/04-invoke-webrequest.txt` (200) |
| Evidências capturadas | Validado | `03-iis/07-aba-seguranca-site.png` (aba Security com `IIS_IUSRS` em Read & execute) |

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
| Evidências capturadas | Validado | `05-monitoramento/09-perfmon-grafico-3-contadores.png` (pico de CPU do teste de carga), `10-agendador-historico.png`, `11-monitoramento-e-alertas-powershell.png` (limites do alerta e `alertas.log` com "CPU alta: 100%") |

## Recuperação (1 ponto)

| Item | Status | Evidência |
|---|---|---|
| Recuperação configurada | Validado | `06-teste-falha/01-sc-qfailure.txt`, `02-pool-recuperacao.txt` |
| Falha controlada executada | Validado | `06-teste-falha/teste-falha-*.log` (3 execuções) |
| Indisponibilidade comprovada | Validado | passo [4] com timeout nos testes Crash 01:19:51 e Parada 01:20:34 |
| Recuperação automática comprovada | Validado | Crash: SCM, evento 7031, 15,7 s. Parada: tarefa agendada, 60,7 s (`03-teste-falha-resumo.txt`) |
| Aplicação novamente disponível | Validado | passo [7] HTTP 200 nos dois testes |
| Evidências capturadas | Validado | `06-teste-falha/06-services-recovery-w3svc.png`; o navegador caindo e voltando fica para o vídeo |

## Auditoria (1 ponto)

| Item | Status | Evidência |
|---|---|---|
| Auditoria configurada | Validado | `07-logs/01-auditpol.txt` (Logon e File System com Success and Failure, mantido após `gpupdate /force`) |
| Eventos disponíveis | Validado | `07-logs/03-logon-4624-4625.txt`, `07-logs/04-acesso-arquivo-4663.txt` |
| Logs do IIS | Validado | `07-logs/u_ex261116.log`, `07-logs/06-logs-iis.txt` |
| Evidências capturadas | Validado | `07-logs/07-event-viewer-security.png`, `07-logs/08-pasta-logs-iis.png` |

## Funcionamento completo (2 pontos)

| Item | Status | Evidência |
|---|---|---|
| Aplicação funcionando | Validado | `03-iis/06-navegador-site-pelo-ip.jpg` |
| Serviços validados | Validado | `00-validacao/validacao-20261116-123441.txt` (49/49) e os prints `01-` e `02-validacao-final-49-de-49-parte*.png` da execução das 22:03 (49/49) |
| Scripts testados | Validado | todos rodaram na VM; quatro problemas encontrados e corrigidos (teste do gateway, DNS IPv6, regras de firewall do RDP e o `w3wp.exe` no modo Crash) (ver `docs/testes-realizados.md`) |
| README completo | Validado | ficha, integrantes, cidade, ODS, indicador, tecnologias, hospedagem, IP, domínio e rastreabilidade |
| Repositório organizado | Validado | https://github.com/LuisCrivellaro/civia-infra |
| Ficha CitizenTech | Validado | `docs/ficha-citizentech.md` completa |
| Evidências associadas aos critérios | Validado | tabela de rastreabilidade no README |
| Vídeo demonstrativo de até sete minutos | Validado | https://www.youtube.com/watch?v=CGmx1JJHYeI (YouTube, público, 6:04), gravado com `scripts/Demo-Video.ps1` seguindo `docs/roteiro-video.md` |
| Link de entrega preparado | Executado | link pronto: https://github.com/LuisCrivellaro/civia-infra |
| Envio no Teams | Pendente | um integrante envia até 19/11/2026 às 23h55 e confere se ficou como entregue |

## Extras

| Item | Status | Evidência |
|---|---|---|
| GPO aplicada e verificada com usuário | Validado | `04-ntfs-gpo/07-gpo-painel-bloqueado-bruno.png` (bruno.teste bloqueado no Painel de Controle), `08-gpresult-bruno.txt`, relatório HTML `09-relatorio-gpo.html` |
| Acesso remoto validado | Validado | RDP com NLA e firewall só na rede local (`04-ntfs-gpo/05-rdp.txt`); `04-ntfs-gpo/10-rdp-conexao-hostname.png`: conexão do PC host com `hostname` e `whoami` na tela |
| Compartilhamento acessado | Validado | `04-ntfs-gpo/01-get-smbshare.txt`; `04-ntfs-gpo/11-share-acessado-do-host.png`: `\\192.168.0.250\CitizenTech` aberto no Explorador do PC host, com `CITIZENTECH\Administrator` |
| DFS Namespace | Validado | `04-ntfs-gpo/06-get-dfsnroot.txt` (`\\citizentech.local\CitizenTechDFS` Online) |
