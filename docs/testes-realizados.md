# Testes realizados

Registro do que foi testado, onde e com qual resultado. Testes feitos fora da VM não valem como evidência da infraestrutura; servem para mostrar que os scripts foram verificados antes de ir para o servidor.

## 14/11/2026, máquina de desenvolvimento

Ambiente: Windows 11 Pro em português (pt-BR), Windows PowerShell 5.1.26100, sessão sem privilégio de administrador. Não é Windows Server, não tem AD, IIS nem DNS.

| Teste | Resultado | Observação |
|---|---|---|
| Parser do PowerShell 5.1 em todos os `.ps1`, `.psm1` e `.psd1` | Passou | 0 erros de sintaxe nos 13 arquivos |
| Arquivos só com caracteres ASCII | Passou | evita problema de codificação no 5.1, que lê `.ps1` sem BOM como ANSI |
| `Get-Counter "\Processor(_Total)\% Processor Time"` (comando do roteiro) | Falhou | "O objeto especificado não foi encontrado no computador". Confirma que o nome em inglês não funciona em Windows pt-BR |
| Tradução dos contadores (`Get-CTCounterPath`) | Passou, após correção | primeira versão lia `HKLM:\...\Perflib\009`, que não existe como chave comum, e caía no fallback. A versão final lê pelo `Registry::PerformanceData` e devolveu `\Processador(_Total)\% tempo de processador`, `\Memória\MBytes disponíveis`, `\LogicalDisk(C:)\% de espaço livre` e `\LogicalDisk(C:)\Megabytes livres`; os quatro leram valores com `Get-Counter` |
| `Monitor-Recursos.ps1` normal (logs no scratchpad, sem log de eventos) | Passou | linha verde com CPU, RAM e disco; `monitor.log` gravado com `fontes CPU=Get-Counter RAM=Get-Counter` |
| `Monitor-Recursos.ps1 -ModoTeste` | Passou | alerta marcado `[TESTE]` em `alertas-teste.log`, sem tocar no `alertas.log` |
| `Monitor-Recursos.ps1 -LimiteCPU 0` | Passou | alerta real de CPU gravado em `alertas.log` (feito com a versão anterior, que usava o fallback CIM) |
| `Teste-Falha.ps1 -Confirmar` fora do Windows Server | Passou | abortou com "este teste so roda no Windows Server da VM", código 3, sem tocar em nada |
| `Configurar-AD.ps1` e `Configurar-IIS.ps1` sem administrador | Passou | abortaram antes de qualquer alteração |
| `Configurar-IIS.ps1` (primeira execução) | Falhou, corrigido | `$PSScriptRoot` vem vazio no valor padrão de parâmetro no PowerShell 5.1. Corrigido nos três scripts que usavam isso |
| `Configurar-Rede.ps1` (modo diagnóstico) | Passou | só leitura; listou adaptadores, IPs, gateway, DNS e DHCP |
| `Validar-Ambiente.ps1` fora do servidor | Passou | rodou os 49 itens sem interromper; 3 PASSOU, 14 FALHOU, 32 ERRO (esperado sem AD/IIS/admin); TXT e CSV gravados |
| Página `app/` servida por HTTP local (`python -m http.server`) | Passou | `index.html` e `health.txt` com HTTP 200; o status da página mostrou "HTTP 200 (no ar)" |

Não testado fora da VM, por depender de Windows Server, AD, IIS ou administrador: promoção do domínio, criação de OU/grupos/usuários, IIS, NTFS, compartilhamento, GPO, RDP, auditoria, Data Collector Sets, tarefas agendadas, `sc.exe failure`, `Teste-Falha.ps1` e `Coletar-Evidencias.ps1`.

## 15/11/2026, preparação do host

| Teste / ação | Resultado | Observação |
|---|---|---|
| Rede do host | Lido | Ethernet `192.168.0.17/24`, gateway `192.168.0.1` |
| IPs candidatos ao servidor (`.250`, `.240`, `.230`) | Livres | não responderam ao ping e não estavam na tabela ARP; escolhido `192.168.0.250` |
| Virtualização da CPU | Ativa | `HypervisorPresent = True` (segurança baseada em virtualização em execução) |
| Ativação do Hyper-V (`Enable-WindowsOptionalFeature Microsoft-Hyper-V-All`) | Passou | `State: Enabled`, `RestartNeeded: True` |
| Parser no `scripts/host/Criar-VM-HyperV.ps1` | Passou | 0 erros; script ainda não executado (precisa do reinício) |
| Download da ISO `SERVER_EVAL_x64FRE_en-us.iso` | Passou | link oficial do Evaluation Center; 5.044.094.976 bytes, igual ao tamanho informado pelo servidor; SHA256 `3E4FA6D8507B554856FC9CA6079CC402DF11A8B79344871669F0251535255325` |

## Na VM

VM `SRV-CITIZENTECH` no Hyper-V do PC de desenvolvimento, Windows Server 2022 Standard Evaluation (inglês), build 20348. Os scripts foram executados pelo PowerShell Direct (o host roda o comando dentro da VM e recebe a saída), em sessão de administrador. As senhas (Administrator, DSRM e contas de teste) foram digitadas pelo aluno em janelas do Windows e não ficaram gravadas em arquivo.

| Data/hora | Teste | Resultado | Evidência |
|---|---|---|---|
| 16/11 01:05 | `Configurar-Rede.ps1` diagnóstico e `-Acao Renomear` | Passou | hostname `SRV-CITIZENTECH` após reinício |
| 16/11 01:06 | `Configurar-Rede.ps1 -Acao IPFixo` | Passou com erro no fim, corrigido | IP aplicado; o teste do gateway deu "Generic failure" porque o IP ainda estava em verificação (Tentative). O script passou a esperar o estado Preferred |
| 16/11 01:06 | DNS IPv6 | Corrigido | o roteador entregava DNS IPv6 da operadora; o script passou a configurar `::1` |
| 16/11 01:07 | `Configurar-AD.ps1 -Etapa InstalarRecurso` | Passou | AD-Domain-Services e RSAT-AD-PowerShell Installed |
| 16/11 01:10 | `Configurar-AD.ps1 -Etapa PromoverDominio` | Passou | "Operation completed successfully"; `02-ad-dns/01-get-addomain.txt` |
| 16/11 01:14 | `Configurar-AD.ps1 -Etapa CriarObjetos` | Passou | `02-ad-dns/04-usuarios.txt`, `05-grupos.txt` |
| 16/11 01:15 | `Configurar-IIS.ps1` | Passou | site Started, pool Started, HTTP 200; página aberta do PC host pelo IP (`03-iis/06-navegador-site-pelo-ip.jpg`) |
| 16/11 01:15 | `Configurar-Infraestrutura.ps1` (FileServer, GPO, RDP, Auditoria) | Passou, com bug no RDP | o validador mostrou as regras de firewall do RDP desligadas; corrigido (ver abaixo) |
| 16/11 01:16 | `Configurar-Monitoramento.ps1` | Passou | os dois Data Collector Sets em Running, tarefa Ready |
| 16/11 01:16 | `Configurar-Recuperacao.ps1` | Passou | `06-teste-falha/01-sc-qfailure.txt` |
| 16/11 01:18 | `Teste-Falha.ps1 -Modo Crash` (1ª versão) | Inconclusivo | o site continuou respondendo 200 depois de encerrar o svchost do W3SVC/WAS: o `w3wp.exe` do pool seguiu atendendo. O script corretamente não declarou recuperação |
| 16/11 01:19 | `Teste-Falha.ps1 -Modo Crash` (encerra também o `w3wp.exe`) | Passou | site fora do ar (timeout), voltou em 15,7 s sem ação do script; evento 7031 do Service Control Manager |
| 16/11 01:20 | `Teste-Falha.ps1 -Modo Parada` | Passou | `Stop-Service W3SVC`; a tarefa `CitizenTech_Recuperacao` religou em 60,7 s; linha `AGENDADA` no `recuperacao.log` |
| 16/11 01:22 | Auditoria após `gpupdate /force` | Passou | Logon e File System continuam com Success and Failure; eventos 4663 do site e do compartilhamento |
| 16/11 01:22 | Carga de CPU por 90 s | Passou | alerta real "CPU alta: 100%" no `alertas.log`, evento 9001 e evento 2031 do Monitor de Desempenho |
| 16/11 01:24 | `Configurar-Infraestrutura.ps1 -Componentes DFS` | Passou | `\\citizentech.local\CitizenTechDFS` Online, pasta acessível |
| 16/11 01:24 | `Validar-Ambiente.ps1` | 48 PASSOU, 1 FALHOU | regras de firewall do RDP desligadas: o `Set-NetFirewallRule` regravava o objeto lido antes do `Enable`. Script corrigido e componente rodado de novo |
| 16/11 01:25 | Porta 3389 a partir do PC host | Passou | `Test-NetConnection 192.168.0.250 -Port 3389` = True |
| 16/11 01:25 | `Validar-Ambiente.ps1` | 49 PASSOU | primeira validação completa (substituída pela de 12:34) |
| 16/11 01:31-01:39 | Prints das telas gráficas | Feito | Monitor de Desempenho com os 3 contadores, Agendador com histórico, aba Recovery, Event Viewer, pasta de logs do IIS |
| 16/11 ~01:45 | Liberação temporária de logon local | Aplicada | "Allow log on locally" para `GG_CitizenTech_Usuarios` na Default Domain Controllers Policy, com backup do arquivo original |
| 16/11 12:21 | VM religada no dia seguinte | Passou | depois de liberar RAM no host (a VM não iniciava com 5 GB livres); os dois Data Collector Sets voltaram sozinhos pela tarefa `CitizenTech_DCS_Inicio` |
| 16/11 12:33 | GPO com usuário comum | Passou | `bruno.teste` recebeu "This operation has been cancelled due to restrictions" ao abrir o Painel de Controle; `gpresult` mostra `GPO_CitizenTech_Usuarios` aplicada |
| 16/11 12:34 | Liberação de logon local desfeita | Passou | arquivo original restaurado, versão da GPO 6; `secedit` mostra o direito sem o grupo |
| 16/11 12:34 | `Validar-Ambiente.ps1` | 49 PASSOU | `00-validacao/validacao-20261116-123441.txt` |
| 16/11 12:41 | `Demo-Video.ps1 -Testar` | Passou | as 8 partes rodaram sem erro na VM; ajustados a exibição do gateway/DNS e o `nslookup` só em IPv4 para não mostrar o IPv6 público no vídeo |
| 16/11 18:17 | `Demo-Video.ps1 -Testar -SoParte 3` e `-SoParte 8` | Passou | cada um rodou só a parte pedida e terminou com código 0 |
| 16/11 01:25 | `Coletar-Evidencias.ps1` | Passou | 40 saídas sem erro em `evidencias/` |

Nas evidências, os endereços IPv6 públicos da conexão de internet (prefixo da operadora) foram trocados por `[IPv6-publico-removido]`, porque o repositório é público. Nenhum outro conteúdo foi alterado.
