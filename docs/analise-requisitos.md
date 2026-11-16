# Análise dos requisitos

Fonte principal: `Roteiro-Atividade-Citizentech-GS-OperatingSystem.pdf` (11 páginas). Fonte de contexto: `GS CitizenTech - 3ES Ago- FIAP 2026 (2).pdf`, slide de Operating Systems e regras gerais da GS.

## Dados da entrega

- Entrega: link do repositório GitHub na tarefa do Teams, enviado por um único integrante, até 19/11/2026 às 23h55.
- Ambiente: Windows Server 2019 ou 2022 em VM (VirtualBox, VMware, Hyper-V ou Azure), 4 GB de RAM, 2 vCPUs, 60 GB de disco. Testes pelo terminal PowerShell.
- Nota de 0 a 10 em seis critérios. O documento geral fala em "4 pilares" (configuração e evidências, monitoramento e serviço, logs de auditoria, teste de falha); os seis critérios do roteiro detalham esses pilares e foram usados como base.
- Regras gerais da GS que valem aqui: `prompts.md` com os prompts de IA, nada de dados pessoais reais, README claro, cada integrante sabe explicar o projeto inteiro.

## Matriz de requisitos

| # | Requisito do roteiro | Seção | Critério | Onde é atendido | Evidência pedida |
|---|---|---|---|---|---|
| 1 | VM com Windows Server, Desktop Experience | 3.1 | Rede e identidade | manual (hipervisor) | print do `winver` |
| 2 | Hostname SRV-CITIZENTECH | 3.2 | Rede e identidade | `Configurar-Rede.ps1 -Acao Renomear` | `ipconfig /all` |
| 3 | IP fixo, gateway e DNS apontando para o próprio servidor | 3.2 | Rede e identidade | `Configurar-Rede.ps1 -Acao IPFixo` | `ipconfig /all` |
| 4 | AD DS e floresta citizentech.local com DNS | 3.3 | Rede e identidade | `Configurar-AD.ps1 -Etapa InstalarRecurso/PromoverDominio` | `Get-ADDomain` |
| 5 | Validação de DNS e domínio | 3.4 | Rede e identidade | `Validar-Ambiente.ps1`, `Coletar-Evidencias.ps1` | `Get-ADDomain`, `nslookup`, `Get-DnsServerZone` |
| 6 | OU, grupo, usuário e associação | 3.5 | Rede e identidade | `Configurar-AD.ps1 -Etapa CriarObjetos` | `Get-ADUser`, `Get-ADGroupMember` |
| 7 | IIS instalado | 4.1 | Aplicação no IIS | `Configurar-IIS.ps1` | `Get-WindowsFeature Web-*` |
| 8 | Caminho A ou B, documentado no README | 4.2/4.3 | Aplicação no IIS | Caminho A, `app/` | `Get-Website`, navegador |
| 9 | Pool com runtime correto | 4.2 | Aplicação no IIS | `Configurar-IIS.ps1` | `Get-WebAppPoolState` |
| 10 | Permissões NTFS da pasta do site | 4.4 | Aplicação no IIS | `Configurar-IIS.ps1` | `Get-Acl`, aba Segurança |
| 11 | File Server e compartilhamento | 4.5 | Aplicação no IIS / funcionamento | `Configurar-Infraestrutura.ps1` | `Get-SmbShare`, acesso de um cliente |
| 12 | GPO visível e verificável | 5.1 | Funcionamento completo | `Configurar-Infraestrutura.ps1` | `Get-GPO -All`, usuário sem Painel de Controle |
| 13 | Acesso remoto (RDP) | 5.2 | Funcionamento completo | `Configurar-Infraestrutura.ps1` | conexão RDP de outra máquina |
| 14 | DFS (opcional) | 5.3 | extra | `Configurar-Infraestrutura.ps1 -Componentes DFS` | `Get-DfsnRoot` |
| 15 | Auditoria de logon e de arquivos, SACL na pasta do site | 5.4 | Auditoria e logs | `Configurar-Infraestrutura.ps1` | `auditpol /get`, Visualizador de Eventos, logs do IIS |
| 16 | Data Collector Set com CPU, memória e disco | 6.1 | Monitoramento | `Configurar-Monitoramento.ps1` | Monitor de Desempenho com os 3 contadores |
| 17 | Script de alerta por limiar | 6.2 | Monitoramento | `Monitor-Recursos.ps1` | execução no terminal |
| 18 | Verificação agendada | 6.3 | Monitoramento | `Configurar-Monitoramento.ps1` | Agendador com histórico |
| 19 | Recuperação automática do pool e do W3SVC | 7.1 | Tolerância a falhas | `Configurar-Recuperacao.ps1` | `sc.exe qfailure W3SVC`, aba Recuperação |
| 20 | Script de teste de falha | 7.2 | Tolerância a falhas | `Teste-Falha.ps1` | as etapas no terminal, navegador voltando |
| 21 | Script de recuperação agendado | 7.3 | Tolerância a falhas | `Recupera-Site.ps1`, `Configurar-Recuperacao.ps1` | `recuperacao.log` |
| 22 | Bloco de validação final | 8.1 | Funcionamento completo | `Coletar-Evidencias.ps1 -Etapas ficha`, `Validar-Ambiente.ps1` | print do bloco inteiro |
| 23 | Estrutura do repositório | 8.2 | Funcionamento completo | este repositório | - |
| 24 | README com ficha, IP, hostname, domínio, credenciais de teste e tabela de critérios | 8.3 | Funcionamento completo | `README.md` | - |
| 25 | Vídeo de até 7 minutos | 10 | Funcionamento completo | `docs/roteiro-video.md` | vídeo gravado |

## Ajustes nos comandos do PDF

Cada ajuste mantém o objetivo do roteiro. O motivo vem logo depois.

### Recuperação automática (7.1 e 7.2)

1. `$pool.failure.autoStart = $true`: `autoStart` é propriedade do pool, não do elemento `failure`. Usamos `Set-ItemProperty IIS:\AppPools\CitizenTechPool -Name autoStart -Value $true` e `-Name failure.rapidFailProtection -Value $false`.
2. `Stop-Service W3SVC` não dispara o `sc.exe failure`. O Service Control Manager só executa as ações de recuperação quando o processo do serviço termina sem avisar (crash). Numa parada limpa o serviço fica parado. No script do PDF, depois dos 30 segundos, o bloco `catch` faz `Start-Service W3SVC`, e o site volta por causa desse comando manual. A saída do teste parece de sucesso, mas não prova a recuperação automática.
   - Solução: `Teste-Falha.ps1 -Modo Crash` encerra à força o processo `svchost` que hospeda W3SVC/WAS (o script confere antes que nenhum outro serviço roda no mesmo processo). O SCM registra o evento 7031 e reinicia o serviço em 5 s.
   - `Teste-Falha.ps1 -Modo Parada` repete o teste do PDF, mas espera até 180 s pela tarefa `CitizenTech_Recuperacao` (roda a cada 2 min) e confere no `recuperacao.log` uma linha nova marcada `AGENDADA`.
   - O fallback manual só roda com `-PermitirFallbackManual` e, se usado, o resultado é registrado como `RECUPERACAO MANUAL (NAO AUTOMATICA)`.
3. Também configuramos `sc.exe failureflag W3SVC 1` para a recuperação valer quando o serviço para com código de erro, e a mesma política no WAS, de que o W3SVC depende.

### Monitoramento (6.1 e 6.2)

4. Nomes de contadores dependem do idioma. Em um Windows em português, `Get-Counter "\Processor(_Total)\% Processor Time"` retorna "O objeto especificado não foi encontrado no computador" (testado em 14/11/2026, ver `testes-realizados.md`). Os scripts procuram o índice do contador na lista em inglês e pegam o nome com o mesmo índice na lista do idioma instalado (`\Processador(_Total)\% tempo de processador`). Em Windows em inglês nada muda.
5. No PDF os contadores do Data Collector Set estão escritos com `\\` (`"\\Processor(_Total)\\% Processor Time"`). Em PowerShell a barra invertida não é escape, então o caminho fica com barras duplicadas e vira um nome de computador inválido.
6. O coletor de contadores do PLA (`IPerformanceCounterDataCollector`) não tem método `AddCounter`. A lista é atribuída na propriedade `PerformanceCounters`.
7. O PDF pede "alertas de CPU, disco e memória no Monitor de Desempenho". Além do script, criamos um Data Collector Set de alerta (`CitizenTech_Alertas`) com os três limites; cada disparo gera o evento 2031 no log `Microsoft-Windows-Diagnosis-PLA/Operational`.
8. `Write-EventLog` não existe no PowerShell 7. O script usa `[System.Diagnostics.EventLog]::WriteEntry`, que funciona no 5.1 e no 7.
9. Um Data Collector Set não volta sozinho depois de reiniciar o servidor. A tarefa `CitizenTech_DCS_Inicio` roda `logman start` no boot.

### IIS (4.2 e 4.4)

10. O Default Web Site já ocupa a porta 80. `New-Website -Port 80` cria o site CitizenTech, mas ele fica `Stopped`. O script para o Default Web Site e desliga o início automático dele.
11. O módulo `WebAdministration` usado pelos scripts de recuperação vem com `Web-Scripting-Tools`, instalado junto.

### Nomes localizados (4.5, 5.2, 5.4)

12. `Domain Users`, `Everyone` e o grupo de firewall "Área de Trabalho Remota" mudam conforme o idioma do Windows. Os scripts resolvem pelo SID (`<SID do domínio>-513`, `S-1-1-0`, `S-1-5-32-568` para IIS_IUSRS) e pelo identificador do grupo de firewall (`@FirewallAPI.dll,-28752`).
13. `auditpol /subcategory:"Logon"` também depende do idioma. Usamos os GUIDs: Logon `{0CCE9215-69AE-11D9-BED3-505054503030}` e File System `{0CCE921D-69AE-11D9-BED3-505054503030}`.

### Acesso remoto (5.2)

14. Usamos só o RDP administrativo. A função RDS Session Host em controlador de domínio não é recomendada pela Microsoft e pede licença depois de 120 dias. O roteiro diz que "para o escopo desta atividade, o RDP atende".
15. NLA ligado e regras de firewall limitadas à sub-rede local, para o RDP não ficar exposto fora da rede do laboratório.

### DFS (5.3)

16. `New-DfsnRoot -Path "\\SRV-CITIZENTECH\CitizenTechDFS" -TargetPath "C:\Shares\CitizenTech" -Type DomainV2` falha: o `TargetPath` precisa ser um caminho UNC de um compartilhamento da raiz, e um namespace de domínio é acessado por `\\citizentech.local\CitizenTechDFS`. O script cria `C:\DFSRoots\CitizenTechDFS`, compartilha, cria a raiz e publica `\\SRV-CITIZENTECH\CitizenTech` como a pasta `Arquivos`.
17. DFS Replication (`FS-DFS-Replication`) precisa de pelo menos dois servidores. Não foi configurado.

### Rede (3.2)

18. `New-NetIPAddress -DefaultGateway` falha se a interface já tem um gateway vindo do DHCP. O script desliga o DHCP e remove o IP e a rota padrão antigos antes.
19. O PDF sugere modo Bridge. Em casa isso coloca o controlador de domínio na mesma rede de outros aparelhos. Funciona, mas o IP fixo precisa estar fora da faixa do DHCP do roteador. O script testa se o IP já responde antes de aplicar. Se a equipe não precisar acessar a VM de outra máquina física, uma rede host-only isola melhor.

### GPO (5.1)

20. Para mostrar o usuário sem acesso ao Painel de Controle é preciso fazer logon com uma conta da OU. Em controlador de domínio, usuários comuns não têm o direito "Permitir logon local". O caminho limpo é uma VM cliente (Windows 10/11) no domínio. A alternativa, só para laboratório, está no roteiro de configuração.

## O que depende de ação humana

- Criar a VM e instalar o Windows Server.
- Escolher o IP de acordo com a rede real.
- Digitar as senhas (DSRM e contas de teste) quando os scripts pedirem.
- Prints de telas gráficas: `winver`, navegador, aba Segurança, `services.msc`, Monitor de Desempenho, Agendador de Tarefas, Visualizador de Eventos, RDP de outra máquina, usuário com a GPO aplicada.
- Gravar o vídeo e enviar o link no Teams.
