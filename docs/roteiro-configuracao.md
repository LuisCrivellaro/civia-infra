Configuração da infraestrutura da Civia
Este arquivo reúne a configuração do Windows Server usado na parte de Operating Systems do projeto Civia. A aplicação publicada nessa VM é uma página estática de demonstração. O foco aqui é a infraestrutura: rede, domínio, hospedagem no IIS, permissões, monitoramento e recuperação de falhas.

A VM foi criada no computador principal com Hyper-V. A maior parte da configuração do servidor foi feita pelo PowerShell, com uma conta administrativa. As seções entre parênteses indicam a parte correspondente do roteiro da atividade.
0. Preparação do ambiente
Máquina virtual (seção 3.1)
Utilizei o Hyper-V do Windows 11 Pro, que já estava disponível no computador. A imagem escolhida foi SERVER_EVAL_x64FRE_en-us.iso, do Windows Server 2022 Standard Evaluation, com a opção Desktop Experience. O sistema ficou em inglês e o teclado foi configurado como Portuguese (Brazil ABNT2).

A criação da VM partiu do script Criar-VM-HyperV.ps1, executado no computador principal:
cd 'C:\Projetos\OS GS\scripts\host'
Set-ExecutionPolicy -Scope Process Bypass
.\Criar-VM-HyperV.ps1 -IsoPath "$env:USERPROFILE\Downloads\SERVER_EVAL_x64FRE_en-us.iso"
Start-VM -Name SRV-CITIZENTECH
vmconnect.exe localhost SRV-CITIZENTECH
O script cria o switch externo Civia-Externo, conectado à rede local, e uma VM de geração 2 com 4 GB de RAM, 2 processadores virtuais e disco de 60 GB. A criação do switch pode interromper a conexão de rede do computador por alguns segundos.

A instalação foi feita pelo boot da ISO, na opção Custom: Install Microsoft Server Operating System only, usando o disco virtual de 60 GB. A senha do Administrator ficou fora do repositório. O mesmo cuidado foi adotado com a senha DSRM e com as senhas das contas de teste.

A versão do Windows Server foi registrada com winver, na evidência evidencias/01-rede/00-winver.png.
Arquivos do projeto na VM
O repositório foi levado para a VM como ZIP, baixado do GitHub e extraído em C:\civia-infra. Essa cópia aconteceu antes da configuração do IP fixo, enquanto a internet ainda funcionava pelo DHCP.
Set-ExecutionPolicy -Scope Process Bypass
cd C:\civia-infra\scripts
Get-ChildItem -Recurse | Unblock-File
O Unblock-File retira a marca de bloqueio dos arquivos baixados. Depois da mudança do DNS para o próprio servidor, a resolução de sites externos pode ficar indisponível até a configuração do serviço DNS.

Como o Windows Server está em inglês, alguns nomes encontrados nas telas são: Event Viewer (Visualizador de Eventos), Security (Segurança), System (Sistema), Task Scheduler (Agendador de Tarefas), World Wide Web Publishing Service (serviço W3SVC), Recovery (Recuperação), Performance Monitor (Monitor de Desempenho) e Data Collector Sets > User Defined (Conjuntos de Coletores de Dados > Definido pelo Usuário).
1. Verificação inicial da rede (seção 3.2)
O primeiro script de rede faz somente a leitura da configuração existente. Ele mostra os adaptadores disponíveis, o ifIndex da interface, o IP recebido, o gateway e os servidores DNS.
.\Configurar-Rede.ps1
Esses dados serviram de referência para o arquivo config\CitizenTech.config.psd1, que concentra Rede.IPAddress, PrefixLength, Gateway e DnsServers. O IP escolhido precisa pertencer à mesma sub-rede do gateway e não pode entrar em conflito com os endereços distribuídos pelo roteador. O DNS foi definido para apontar para o próprio servidor.
2. Nome do servidor (seção 3.2)
O hostname usado no projeto é SRV-CITIZENTECH. A alteração foi organizada no mesmo script de rede, com reinicialização ao final.
.\Configurar-Rede.ps1 -Acao Renomear -Reiniciar
Depois que o Windows reinicia, o comando hostname permite confirmar o nome configurado.
3. Endereço IP fixo (seção 3.2)
Com o índice da interface identificado na primeira etapa, o script de rede aplica o IP estático. O parâmetro <ifIndex> representa o índice correspondente à placa de rede da VM.
.\Configurar-Rede.ps1 -Acao IPFixo -InterfaceIndex <ifIndex>
ipconfig /all
Antes de aplicar os valores, a rotina verifica se o endereço já está sendo utilizado. Em seguida, desativa o DHCP e configura IP, máscara, gateway e DNS. O registro completo da rede ficou na pasta evidencias/01-rede/, incluindo a saída de ipconfig /all.

Nesse ponto da configuração, o DNS já pode estar apontando para a VM mesmo sem o serviço instalado. Por isso, a resolução de nomes externos pode parar temporariamente. Essa parte é resolvida na etapa de Active Directory e DNS.
4. Active Directory e DNS (seção 3.3)
A instalação do Active Directory e a promoção do servidor foram separadas em duas chamadas do script Configurar-AD.ps1.
.\Configurar-AD.ps1 -Etapa InstalarRecurso
.\Configurar-AD.ps1 -Etapa PromoverDominio
A rotina verifica o hostname e o IP, utiliza Test-ADDSForestInstallation antes da promoção e solicita a senha DSRM. O domínio adotado foi citizentech.local, com nome NetBIOS CITIZENTECH. Depois da promoção, o Windows reinicia e passa a aceitar o login de domínio CITIZENTECH\Administrator.

O encaminhamento de consultas DNS externas ficou como ajuste opcional. Quando necessário, o comando previsto é:
Add-DnsServerForwarder -IPAddress <gateway>
Nesse caso, <gateway> corresponde a um endereço que efetivamente ofereça resolução DNS. O encaminhador não interfere na zona interna citizentech.local.
5. Domínio, usuários e grupos (seções 3.4 e 3.5)
Depois da promoção, a configuração continua com os objetos do Active Directory. A rotina cria a unidade organizacional CitizenTech, os grupos GG_CitizenTech_Admins e GG_CitizenTech_Usuarios e as contas de teste ana.souza e bruno.teste.
.\Configurar-AD.ps1 -Etapa CriarObjetos
Get-ADDomain | Select-Object Name, DNSRoot, DomainMode
nslookup srv-citizentech.citizentech.local
Get-DnsServerZone
A senha inicial das contas segue a política de complexidade do domínio e não foi colocada no GitHub. O script também verifica a existência dos objetos para evitar duplicações em novas execuções.

As consultas confirmam os dados do domínio, a resolução do nome do servidor e a zona DNS criada. Os registros de domínio, usuários e grupos estão organizados em evidencias/02-ad-dns/.
6. Publicação da aplicação no IIS (seções 4.1, 4.2 e 4.4)
A Civia foi hospedada pelo Caminho A do roteiro: uma aplicação estática no IIS, sem runtime de backend. A página utilizada está na pasta app/ e serve para demonstrar a hospedagem da solução, não sendo a aplicação final de todas as disciplinas.
.\Configurar-IIS.ps1
Esse script instala o IIS, copia os arquivos da aplicação para C:\inetpub\citizentech e interrompe o Default Web Site para liberar a porta 80. Depois cria o site CitizenTech e o pool CitizenTechPool, sem código gerenciado.

Também são aplicadas as permissões NTFS: IIS_IUSRS com acesso de leitura e os administradores do projeto com permissão para modificar os arquivos. A regra HTTP é liberada no firewall e a resposta local do site é conferida em http://localhost/.

A pasta evidencias/03-iis/ reúne o estado do site e do pool (Get-Website e Get-WebAppPoolState), a página aberta pelo endereço IP e as permissões da pasta, inclusive a saída de Get-Acl C:\inetpub\citizentech | Format-List.
7. Compartilhamento, GPO, acesso remoto e auditoria (seções 4.5, 5.1, 5.2 e 5.4)
A configuração desses recursos foi reunida em Configurar-Infraestrutura.ps1. Os componentes são tratados separadamente, para que uma falha em um deles não impeça a configuração dos demais. O script também aceita a execução de um componente específico.
.\Configurar-Infraestrutura.ps1
.\Configurar-Infraestrutura.ps1 -Componentes GPO
Compartilhamento de arquivos
O compartilhamento da Civia utiliza o caminho \\SRV-CITIZENTECH\CitizenTech. O grupo GG_CitizenTech_Admins recebe controle total, enquanto Domain Users fica com acesso de leitura. Essas permissões são consideradas tanto no compartilhamento quanto no NTFS.

A verificação envolve a saída de Get-SmbShare e o acesso à pasta pelo Explorador de Arquivos, a partir de uma máquina da rede ou do próprio servidor. Os registros ficaram junto às evidências de infraestrutura, em evidencias/04-ntfs-gpo/.
Política de grupo
A política criada para os usuários é GPO_CitizenTech_Usuarios. Ela fica vinculada à unidade organizacional CitizenTech e utiliza a configuração NoControlPanel = 1, que bloqueia o Painel de Controle para os usuários atingidos pela política. O relatório HTML é gerado em C:\Scripts\logs\GPO_Report.html.

A verificação do bloqueio foi planejada para a conta bruno.teste. O cenário mais adequado é uma VM cliente Windows 10/11 ingressada no domínio, com o DNS apontando para o servidor. Nesse cliente, o ingresso no domínio pode ser feito com Add-Computer -DomainName citizentech.local -Restart. Após o login como CITIZENTECH\bruno.teste, o gpupdate /force atualiza as políticas e a tentativa de abrir o Painel de Controle mostra o efeito da GPO.

Também existe uma alternativa restrita ao laboratório, quando não há uma segunda VM. Ela utiliza temporariamente a opção Allow log on locally na Default Domain Controllers Policy, em Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > User Rights Assignment, com o grupo GG_CitizenTech_Usuarios. Essa alteração precisa ser desfeita depois do teste, pois não é apropriada como configuração permanente do controlador de domínio. Caso tenha sido usada, o procedimento deve constar no README.

As consultas utilizadas na conferência da GPO são:
Get-GPO -All
Get-GPInheritance -Target "OU=CitizenTech,DC=citizentech,DC=local"
gpresult /r
O resultado de gpresult /r corresponde à sessão do usuário em que o comando foi executado.
Acesso remoto
O acesso remoto utiliza RDP com autenticação em nível de rede (NLA). As regras de firewall ficam limitadas à rede local, sem redirecionamento da porta 3389 no roteador.

A conexão é identificada pelo comando mstsc /v:<IP> em outra máquina. Dentro da sessão remota, hostname mostra o nome do servidor conectado. O registro dessa conexão está associado às evidências de infraestrutura.
Auditoria
A auditoria acompanha sucessos e falhas de logon e de acesso a arquivos. Foram previstas regras SACL de leitura e escrita para Everyone nas pastas C:\inetpub\citizentech e C:\Shares\CitizenTech.

O acesso ao site e aos arquivos compartilhados permite gerar eventos para consulta no Visualizador de Eventos. Como a VM é um controlador de domínio, as definições de auditoria também podem ser afetadas pela Default Domain Controllers Policy após a atualização das políticas. A verificação foi feita com:
auditpol /get /category:*
Se uma subcategoria de auditoria for desativada pela política de domínio, a configuração correspondente fica na seção Advanced Audit Policy Configuration da GPO.
DFS (opcional)
O DFS foi tratado como recurso adicional, separado dos itens principais. A configuração utiliza o mesmo script de infraestrutura, com o componente DFS.
.\Configurar-Infraestrutura.ps1 -Componentes DFS
Get-DfsnRoot
A saída de Get-DfsnRoot serve para verificar se o namespace DFS foi publicado. Essa etapa é opcional no roteiro da atividade.
8. Monitoramento de recursos (seções 6.1 a 6.3)
O monitoramento foi organizado para acompanhar CPU, memória e espaço em disco, com coleta de desempenho e geração de alertas.
.\Configurar-Monitoramento.ps1
O script configura o conjunto CitizenTech_Monitor com três contadores, coleta a cada 15 segundos e registros .blg em C:\PerfLogs\CitizenTech. Também configura CitizenTech_Alertas, a fonte de eventos CitizenTechMonitor e a tarefa agendada CitizenTech_Monitor_Alertas, executada a cada cinco minutos. Os scripts usados nessa parte são copiados para C:\Scripts.

Os registros em evidencias/05-monitoramento/ mostram os coletores no Performance Monitor, o gráfico dos três recursos, a execução do Monitor-Recursos.ps1 e o histórico da tarefa no Agendador de Tarefas.
Verificação dos alertas
O script de monitoramento tem um modo de teste que mantém as medições reais, mas altera temporariamente os limites de disparo. Dessa forma, o registro pode ser gerado sem depender de CPU ou memória realmente sobrecarregadas.
C:\Scripts\Monitor-Recursos.ps1 -ModoTeste
Esse tipo de execução fica identificado como [TESTE] no arquivo alertas-teste.log e no evento 9100. Portanto, o alerta simulado não é apresentado como se fosse um pico real de utilização.

O projeto também prevê um teste curto de carga de CPU, limitado à VM de laboratório, para observar a geração de um alerta real quando o limiar é atingido:
$fim = (Get-Date).AddSeconds(90)
1..([Environment]::ProcessorCount) | ForEach-Object { Start-Job { param($f) while ((Get-Date) -lt $f) { } } -ArgumentList $fim } | Out-Null
C:\Scripts\Monitor-Recursos.ps1
Get-Job | Remove-Job -Force
O resultado desse teste depende da leitura efetiva dos contadores e do registro no log. A existência da carga, por si só, não comprova que um alerta foi disparado.
9. Recuperação automática do IIS (seções 7.1 e 7.3)
A recuperação automática foi configurada tanto no pool da aplicação quanto nos serviços envolvidos na publicação do site.
.\Configurar-Recuperacao.ps1
sc.exe qfailure W3SVC
No pool CitizenTechPool, a configuração utiliza rapidFailProtection=false e autoStart=true. Nos serviços W3SVC e WAS, as tentativas de reinício são previstas após 5, 10 e 30 segundos, com reinicialização do contador de falhas a cada 24 horas.

Além disso, a tarefa CitizenTech_Recuperacao faz verificações a cada dois minutos. As evidências dessa etapa incluem a saída de sc.exe qfailure W3SVC e a aba Recovery do serviço no services.msc, em evidencias/06-teste-falha/.
10. Teste de falha e recuperação (seção 7.2)
O teste de falha foi separado da configuração para permitir observar o comportamento do site antes, durante e depois da interrupção do serviço. Essa verificação ocorre somente na VM de laboratório, com a página da Civia aberta no navegador.
C:\Scripts\Teste-Falha.ps1
C:\Scripts\Teste-Falha.ps1 -Modo Parada
Get-Content C:\Scripts\logs\recuperacao.log -Tail 10
Get-Content C:\Scripts\logs\teste-falha-resumo.log
O primeiro modo testa uma falha do tipo Crash, cuja recuperação depende do Service Control Manager. O segundo utiliza uma parada controlada do serviço e verifica a atuação da tarefa agendada, que pode levar até dois minutos para executar.

O script solicita a confirmação SIM, registra as etapas do teste e apresenta um resultado final:
- RECUPERACAO AUTOMATICA COMPROVADA: retorno do serviço sem intervenção manual, com indicação do mecanismo e do tempo de recuperação.
- INCONCLUSIVO: não foi possível confirmar a indisponibilidade durante a verificação.
- FALHA: o serviço não retornou no período observado.
A opção -PermitirFallbackManual existe apenas para restabelecer o serviço caso a recuperação automática falhe. Quando ela é usada, o resultado fica identificado como recuperação manual, não automática.

As evidências em evidencias/06-teste-falha/ incluem o registro do terminal, a indisponibilidade e o retorno da página, o arquivo recuperacao.log e os eventos do sistema relacionados ao serviço, como o evento 7031 quando gerado.
11. Logs do Windows e do IIS (seção 5.4)
Os registros do Windows foram consultados no log de Segurança, e os acessos à aplicação ficaram disponíveis nos arquivos de log do IIS.
auditpol /get /category:*
Get-WinEvent -LogName Security -MaxEvents 20 | Select-Object TimeCreated, Id, Message
Get-ChildItem "C:\inetpub\logs\LogFiles" -Recurse | Select-Object FullName, Length
A pasta evidencias/07-logs/ reúne a configuração de auditoria, os registros do Event Viewer e os arquivos de log do IIS. Entre os eventos de interesse estão o 4624, relacionado a logon, e o 4663, relacionado a acesso a objeto, quando presentes.
12. Validação geral e organização das evidências (seção 8.1)
Ao final da configuração, os scripts de validação e coleta centralizam os resultados do ambiente.
cd C:\civia-infra\scripts
.\Validar-Ambiente.ps1
.\Coletar-Evidencias.ps1
O Validar-Ambiente.ps1 identifica cada verificação com os estados PASSOU, FALHOU ou ERRO, registrando os resultados em arquivos TXT e CSV na pasta evidencias/00-validacao/. O Coletar-Evidencias.ps1 reúne as saídas dos comandos nas pastas correspondentes. A ficha geral da infraestrutura é registrada em evidencias/00-validacao/00-ficha-infraestrutura.txt.

A validação da seção 8.1 também conta com uma captura da saída completa dos comandos no PowerShell. O TXT permanece como registro complementar, junto aos prints e demais arquivos de evidência.

Os arquivos publicados no GitHub não incluem as senhas administrativas, a senha DSRM ou as senhas das contas usadas nos testes.
13. Fechamento do projeto
A entrega reúne os scripts de configuração, a página de demonstração da Civia, a documentação e as evidências coletadas na VM. A pasta evidencias/ fica no repositório principal, enquanto o README.md apresenta o ambiente e relaciona cada critério de avaliação aos respectivos registros.

A identificação da solução e dos integrantes está em docs/ficha-citizentech.md. O vídeo de apresentação, com duração máxima de sete minutos, cobre a rede e o domínio, o IIS, as permissões e a GPO, o compartilhamento de arquivos, o monitoramento, o teste de recuperação e os logs, encerrando com a página da Civia acessível no navegador.

A entrega da disciplina é feita pelo link do repositório GitHub no Teams.