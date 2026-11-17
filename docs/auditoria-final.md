# Auditoria final

Revisão feita em 16/11/2026 antes da entrega. Comparamos os dois PDFs oficiais (`Roteiro-Atividade-Citizentech-GS-OperatingSystem.pdf`, 11 páginas, e o slide de Operating Systems do `GS CitizenTech - 3ES Ago- FIAP 2026 (2).pdf`) com os scripts, os documentos e as evidências do repositório. Nesta revisão nenhum script foi executado de novo na VM e nenhuma evidência foi substituída.

## A. Resumo executivo

A infraestrutura pedida está configurada e comprovada na VM `SRV-CITIZENTECH`:
- a validação automática passou nos 49 itens;
- a recuperação automática foi provada em dois modos;
- o alerta de CPU disparou de verdade;
- a GPO foi testada com um usuário comum;
- o vídeo está publicado.

Os três prints que faltavam na primeira versão desta auditoria (conexão RDP, compartilhamento acessado de um cliente e aba Segurança) foram tirados na mesma noite e estão nas evidências.

Fica uma decisão de escopo: **a aplicação hospedada é uma página de demonstração.** O roteiro pede a "aplicação WEB CitizenTech desenvolvida em outra disciplina", e o repositório publica uma página estática com os dados da Civia. Isso está declarado no README e na própria página, mas pode custar pontos em "Aplicação hospedada no IIS" e "Funcionamento completo".

Os 49/49 do validador cobrem a configuração do servidor. Eles não cobrem os prints manuais, o conteúdo do vídeo nem o envio no Teams.

## B. Matriz de requisitos

| Critério (pontos) | Requisito do roteiro | Arquivo | Evidência | Estado | Correção necessária |
|---|---|---|---|---|---|
| Rede e identidade (2,0) | Windows Server em VM, `winver` | `scripts/host/Criar-VM-HyperV.ps1` | `01-rede/00-winver.png`, `02-winver-versao.txt` | Validado | - |
| | hostname `SRV-CITIZENTECH`, IP fixo | `Configurar-Rede.ps1` | `01-rede/01-hostname.txt`, `03-ipconfig-all.txt` (192.168.0.250/24, DHCP desligado, gateway 192.168.0.1) | Validado | - |
| | AD DS, domínio, DNS | `Configurar-AD.ps1` | `02-ad-dns/01-get-addomain.txt`, `02-nslookup.txt`, `03-get-dnsserverzone.txt` | Validado | - |
| | OU, grupos, usuários | `Configurar-AD.ps1` | `02-ad-dns/04-usuarios.txt`, `05-grupos.txt` | Validado | - |
| Aplicação no IIS (2,0) | IIS instalado | `Configurar-IIS.ps1` | `03-iis/01-windowsfeature-web.txt` | Validado | - |
| | Caminho A, site e pool sem runtime | `Configurar-IIS.ps1`, `app/` | `03-iis/02-get-website.txt`, `03-get-webapppoolstate.txt`, `04-invoke-webrequest.txt` (200), `06-navegador-site-pelo-ip.jpg` | Validado, com ressalva | a página é de demonstração; trocar pela aplicação web da equipe, se ela existir a tempo |
| | NTFS da pasta do site | `Configurar-IIS.ps1` | `03-iis/05-get-acl-site.txt`, `07-aba-seguranca-site.png` | Validado | - |
| | File Server e compartilhamento | `Configurar-Infraestrutura.ps1` | `04-ntfs-gpo/01-get-smbshare.txt`, `02-get-acl-share.txt`, `11-share-acessado-do-host.png` | Validado | - |
| Monitoramento (2,0) | Data Collector Set com CPU, memória e disco | `Configurar-Monitoramento.ps1` | `05-monitoramento/01-logman-query.txt`, `02-perflogs.txt`, `09-perfmon-grafico-3-contadores.png` | Validado | - |
| | script de alerta por limiar | `Monitor-Recursos.ps1` | `04-execucao-monitor.txt`, `07-alertas.txt` (CPU 100 %, evento 9001), `08-alertas-perfmon.txt` (evento 2031) | Validado | - |
| | verificação agendada | `Configurar-Monitoramento.ps1` | `05-tarefa-agendada.txt`, `10-agendador-historico.png` | Validado | - |
| Tolerância a falhas (1,0) | recuperação do pool e do W3SVC | `Configurar-Recuperacao.ps1` | `06-teste-falha/01-sc-qfailure.txt`, `02-pool-recuperacao.txt`, `06-services-recovery-w3svc.png` | Validado | - |
| | teste de falha com indisponibilidade | `Teste-Falha.ps1` | `teste-falha-Crash-20261116-011951.log`, `teste-falha-Parada-20261116-012034.log` (timeout no passo 4) | Validado | - |
| | recuperação automática, separada da manual | `Teste-Falha.ps1`, `Recupera-Site.ps1` | `03-teste-falha-resumo.txt` (Crash 15,7 s pelo SCM; Parada 60,7 s pela tarefa), `05-eventos-scm.txt` (7031), `04-recuperacao-log.txt` | Validado | - |
| Auditoria e logs (1,0) | `auditpol` Logon e File System | `Configurar-Infraestrutura.ps1` | `07-logs/01-auditpol.txt` | Validado | - |
| | SACL, eventos 4624 e 4663 | `Configurar-Infraestrutura.ps1` | `05-sacl-site.txt`, `03-logon-4624-4625.txt`, `04-acesso-arquivo-4663.txt`, `07-event-viewer-security.png` | Validado | - |
| | logs do IIS | - | `06-logs-iis.txt`, `u_ex261116.log`, `08-pasta-logs-iis.png` | Validado | - |
| Funcionamento completo (2,0) | bloco de validação 8.1 com `Test-NetConnection` | `Coletar-Evidencias.ps1`, `Validar-Ambiente.ps1` | `00-validacao/00-ficha-infraestrutura.txt` (`TcpTestSucceeded : True`), `validacao-20261116-123441.txt` (49/49), prints `01-` e `02-validacao-final-49-de-49-parte*.png` | Validado | o validador ocupa duas telas, então são dois prints |
| | GPO visível e verificável | `Configurar-Infraestrutura.ps1` | `04-ntfs-gpo/03-get-gpo-all.txt`, `07-gpo-painel-bloqueado-bruno.png`, `08-gpresult-bruno.txt`, `09-relatorio-gpo.html` | Validado | - |
| | acesso remoto RDP | `Configurar-Infraestrutura.ps1` | `04-ntfs-gpo/05-rdp.txt`, validação (NLA, firewall `LocalSubnet`), `10-rdp-conexao-hostname.png` | Validado | - |
| | DFS (opcional) | `Configurar-Infraestrutura.ps1 -Componentes DFS` | `04-ntfs-gpo/06-get-dfsnroot.txt` | Validado | - |
| | README com ficha e rastreabilidade (8.3) | `README.md`, `docs/ficha-citizentech.md` | ficha, IP, hostname, domínio, credenciais de teste sem senha, tabela de critérios | Validado | - |
| | estrutura do repositório (8.2) | `README.md` | pastas `docs/`, `scripts/`, `evidencias/01-rede` a `07-logs` | Validado | - |
| | vídeo de até 7 minutos | `docs/roteiro-video.md`, `scripts/Demo-Video.ps1` | https://www.youtube.com/watch?v=CGmx1JJHYeI (6:04, público) | Validado | - |
| | `prompts.md` (regra geral da GS) | `prompts.md` | registro dos pedidos e da divisão de tarefas | Validado | - |
| Entrega | link no Teams, um integrante, até 19/11 às 23h55 | - | - | Pendente | envio (D.5) |

O prazo de 19/11 às 23h55 aparece igual nos dois PDFs: na página 1 e no final do roteiro, e nas páginas 23 e 32 do documento geral.

## C. Correções executadas

| Arquivo | Problema | Alteração |
|---|---|---|
| `prompts.md` | dizia que a IA "não acessou nenhuma VM" e "não gerou evidências", o que deixou de ser verdade depois de 14/11 | cronologia dos pedidos até 16/11 e tabela de quem fez o quê (IA, aluno, equipe), sem atribuir à IA o que foi humano (senhas, logon, narração e edição do vídeo, dados da solução) |
| `docs/ficha-citizentech.md` | "a preencher" e "IP a confirmar" | IP, gateway e DNS confirmados pela evidência; "o que cada parte faz" limitado à parte de OS, sem inventar as outras disciplinas; aplicação descrita como página de demonstração |
| `docs/checklist-entrega.md` | itens com print faltando marcados como Validado; envio no Teams sem linha própria | RDP e compartilhamento como "Executado, falta print"; aba Segurança como pendência; ressalva da página de demonstração; linha do envio no Teams; quatro problemas corrigidos citados |
| `README.md` | aviso de situação sem os prints faltantes; diagrama com "bridge ou host-only"; "(preencher)" na estrutura; status sem ressalvas | aviso atualizado, diagrama com o switch externo e o IP, rastreabilidade com ressalvas, seções de uso de IA e de entrega |
| `docs/roteiro-video.md` | dizia que o DNS do servidor é `192.168.0.250` | a evidência mostra `127.0.0.1` e `::1`, ajustados pela promoção do AD |
| `docs/AI_HANDOFF.md` | data de 14/11, "pastas vazias com .gitkeep", risco do PLA "não testado" | estado de 16/11, pendências atuais, riscos já conferidos na VM |
| `docs/analise-requisitos.md` | numeração repetida (dois itens 4); seção de ação humana desatualizada; tempo do SCM simplificado | itens renumerados de 1 a 21; o que dependeu do aluno e o que ainda falta; atrasos de 5, 10 e 30 s |
| `docs/arquitetura.md` | rede "local ou host-only"; senha só por `Read-Host` | switch externo; `SecureString` por parâmetro no PowerShell Direct |
| `docs/testes-realizados.md` | linha do `Coletar-Evidencias.ps1` fora de ordem; "dia seguinte" para o mesmo dia; faltavam o relatório da GPO, a gravação e o link | linha movida; texto corrigido; três linhas novas, com horários tirados dos commits |
| `evidencias/README.md` | exemplo apontando para arquivo inexistente; lista de prints incompleta | exemplo real, lista completa e as três pendências |

Nenhum script `.ps1` foi alterado nesta auditoria e os arquivos de `app/` também ficaram iguais. A página publicada na VM continua igual à do repositório.

## D. Pendências humanas

1. **Prints da conexão RDP, do compartilhamento e da aba Segurança:** feitos em 16/11, entre 20:14 e 20:20. A IA conduziu a Área de Trabalho Remota e o Explorador; o aluno digitou a senha para conectar ao compartilhamento.
   - `evidencias/04-ntfs-gpo/10-rdp-conexao-hostname.png`
   - `evidencias/04-ntfs-gpo/11-share-acessado-do-host.png`
   - `evidencias/03-iis/07-aba-seguranca-site.png`
2. **Vídeo:** conferido em 16/11 pela página do YouTube: 6:04 de duração, visibilidade pública, abre sem login.
3. **Envio:** um integrante envia `https://github.com/LuisCrivellaro/civia-infra` na tarefa de Operating Systems do Teams até 19/11 às 23h55 e confere se ficou como entregue.
4. **Aplicação real (opcional, decisão da equipe):** se a aplicação web da Civia de outra disciplina estiver pronta, troque o conteúdo de `app/`, rode `Configurar-IIS.ps1` de novo e tire um print novo do navegador. Se ela tiver backend, o caminho passa a ser o B.
5. **Publicação:** feita depois da revisão do aluno.


## E. Riscos restantes

| Risco | Gravidade | Motivo |
|---|---|---|
| Aplicação hospedada é uma página de demonstração | Alto | o roteiro e o documento geral pedem a aplicação web da equipe; afeta dois critérios que somam 4 pontos |
| Envio no Teams não feito | Crítico até ser feito | sem envio não há nota; depende só da equipe |
| GPO testada com logon no controlador de domínio | Baixo | exigiu uma liberação temporária, documentada e desfeita; o ideal seria uma VM cliente |
| Teste de falha do vídeo sem transcript no repositório | Baixo | os três testes anteriores estão salvos; o do vídeo aparece na gravação |

## F. Checklist final

**Concluído e comprovado:**
- rede e identidade;
- IIS, pool e NTFS em texto;
- monitoramento com alerta real;
- recuperação automática nos modos Crash e Parada;
- auditoria e logs;
- GPO com usuário comum;
- prints da conexão RDP, do compartilhamento a partir do PC host e da aba Segurança;
- DFS Namespace;
- README e ficha;
- rastreabilidade;
- `prompts.md`;
- vídeo publicado, com 6:04.

**Impede a entrega:**
- só o envio no Teams.

Nenhuma pendência técnica impede o envio.

### Testes desta auditoria

| Teste | Resultado |
|---|---|
| Parser do PowerShell 5.1 nos 15 arquivos de `scripts/` | 0 erros |
| Arquivos de script só com ASCII | 15 de 15 |
| Busca por senhas, tokens e `-AsPlainText` | nada encontrado |
| Sintaxe exclusiva do PowerShell 7 (`??`, `?.`, `&&`, `-Parallel`) | nada encontrado |
| Links Markdown internos | nenhum quebrado |
| Referências a arquivos de evidência nos `.md` | todas existem; só `alertas-teste.log` é citado como arquivo da VM, gerado no modo de teste |
| IPs nas evidências | só `192.168.0.250` (servidor), `192.168.0.1` (gateway) e `192.168.0.17` (PC host, nos logs do IIS); IPv6 público já trocado |
| Link do vídeo | o oEmbed do YouTube devolveu o título do vídeo, então ele abre sem login; a página informa 364 segundos (6:04) e `isUnlisted: false` |
| PSScriptAnalyzer | não executado: o módulo não está instalado no PC |
| Leitura de dados atuais da VM | não feita: o processo que acessava a VM tinha sido fechado, e nenhum dado novo foi necessário |

## G. Parecer de entrega

**PRONTO COM RESSALVAS.**

- **Os quatro pilares têm evidência real.** O documento geral fala em configuração e evidências, monitoramento e serviço, logs de auditoria e teste de falha. Os critérios de monitoramento (2,0), tolerância a falhas (1,0) e auditoria (1,0) estão completos.
- **Rede e identidade (2,0)** está completo.
- **A ressalva fica em "Aplicação hospedada no IIS" e em "Funcionamento completo":** a página publicada é de demonstração. Os prints pedidos no roteiro estão completos.

A ressalva não impede o envio. Este parecer não prevê nota.
