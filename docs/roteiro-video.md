# Roteiro do vídeo (até 7 minutos)

Segue a divisão de tempo do roteiro do professor (seção 10). A fala é uma sugestão para ler em voz alta e adaptar; não precisa decorar. Onde aparece `[preencher]`, use o valor que apareceu de verdade na tela. Não fale de resultado que não foi mostrado.

Antes de gravar:
- rode `Validar-Ambiente.ps1` e confirme que está tudo `PASSOU`;
- deixe abertos: PowerShell como Administrador (fonte grande, janela maximizada), navegador em `http://<IP>`, `services.msc`, `perfmon`, Agendador de Tarefas, Visualizador de Eventos;
- confira se a tarefa de monitoramento já rodou algumas vezes (histórico com execuções);
- feche janelas com dados pessoais.

## 0:00 a 0:40 · servidor, hostname, IP e domínio

Tela: PowerShell.

```powershell
hostname
ipconfig /all
Get-ADDomain | Select-Object Name, DNSRoot, DomainMode
```

Fala:
> Esta é a infraestrutura de Operating Systems da nossa CitizenTech, [nome da solução]. O servidor é um Windows Server 2022 rodando em [hipervisor]. O nome é SRV-CITIZENTECH, com IP fixo [IP], e o DNS aponta para ele mesmo, porque ele é o controlador do domínio citizentech.local.

## 0:40 a 1:30 · Active Directory e DNS

```powershell
nslookup srv-citizentech.citizentech.local
Get-DnsServerZone
Get-ADUser -Filter * -SearchBase "OU=CitizenTech,DC=citizentech,DC=local" | Select-Object Name, SamAccountName, Enabled
Get-ADGroupMember GG_CitizenTech_Admins
Get-ADGroupMember GG_CitizenTech_Usuarios
```

Fala:
> O nslookup resolve o nome do servidor para [IP], e a zona citizentech.local aparece como primária. Criamos uma OU chamada CitizenTech com dois grupos: um de administradores do projeto e um de usuários. As contas ana.souza e bruno.teste são fictícias, só para teste. As permissões que vêm depois são dadas para esses grupos, não para pessoas.

## 1:30 a 2:40 · IIS, site, pool e NTFS

```powershell
Get-Website -Name CitizenTech | Format-List Name, State, PhysicalPath, ApplicationPool
Get-WebAppPoolState -Name CitizenTechPool
Get-ItemProperty IIS:\AppPools\CitizenTechPool | Select-Object managedRuntimeVersion, autoStart
Invoke-WebRequest http://localhost -UseBasicParsing | Select-Object StatusCode
(Get-Acl C:\inetpub\citizentech).Access | Format-Table IdentityReference, FileSystemRights, AccessControlType
```

Mostrar também o navegador com a página e a aba Segurança da pasta.

Fala:
> A aplicação está no IIS, no site CitizenTech, com um pool próprio. Usamos o caminho A do roteiro, site estático, então o pool fica sem código gerenciado. O site está Started e responde HTTP [código]. Na pasta, o grupo IIS_IUSRS só tem leitura e execução, porque o site não precisa gravar nada ali. Quem publica conteúdo é o grupo de administradores do projeto.

Se ainda for a página de demonstração, diga isso: "por enquanto está publicada uma página de demonstração; a aplicação da equipe entra na mesma pasta".

## 2:40 a 3:30 · GPO e File Server

```powershell
Get-GPO -All | Select-Object DisplayName, GpoStatus
Get-GPInheritance -Target "OU=CitizenTech,DC=citizentech,DC=local"
Get-SmbShare -Name CitizenTech
Get-SmbShareAccess -Name CitizenTech
```

Mostrar a sessão do usuário `bruno.teste` tentando abrir o Painel de Controle e o Explorador acessando `\\SRV-CITIZENTECH\CitizenTech`.

Fala:
> A GPO_CitizenTech_Usuarios está vinculada à OU e bloqueia o Painel de Controle. Aqui está o bruno.teste tentando abrir e recebendo o bloqueio. O compartilhamento CitizenTech dá controle total ao grupo de administradores e só leitura aos usuários do domínio.

Se o RDP foi testado, mostre a conexão em poucos segundos aqui mesmo.

## 3:30 a 4:30 · monitoramento

Tela: `perfmon` com `CitizenTech_Monitor` e `CitizenTech_Alertas` em execução, gráfico com os três contadores. Depois o PowerShell:

```powershell
C:\Scripts\Monitor-Recursos.ps1
Get-Content C:\Scripts\logs\monitor.log -Tail 5
Get-ScheduledTask CitizenTech_Monitor_Alertas | Get-ScheduledTaskInfo
```

Fala:
> O Data Collector Set grava CPU, memória disponível e espaço livre do disco a cada 15 segundos. O segundo conjunto é o alerta do próprio Monitor de Desempenho, com os limites do roteiro: CPU acima de 80 %, menos de 500 MB de memória e menos de 15 GB livres. O script Monitor-Recursos faz a mesma verificação, roda a cada 5 minutos pelo Agendador e grava cada medição no log. Agora ele mostrou [resultado da tela].

Se mostrar o `-ModoTeste`, diga que os limites foram forçados para demonstrar o alerta e que as medições são reais.

## 4:30 a 5:40 · teste de falha e recuperação

Tela dividida: PowerShell e navegador na página do site.

```powershell
sc.exe qfailure W3SVC
C:\Scripts\Teste-Falha.ps1
```

Fala:
> O serviço W3SVC está configurado para reiniciar sozinho se cair: 5 segundos na primeira falha, 10 na segunda, 30 na terceira. O teste derruba o processo do serviço de propósito. [Passo 4] O site ficou fora do ar, a página mostra sem resposta. Agora o script só espera, ele não religa nada. [Passo 5] O serviço voltou em [tempo] segundos e o resultado diz [mecanismo]. O evento 7031 no log do sistema confirma que foi o Windows que reiniciou.

Se houver tempo, mostrar `Get-Content C:\Scripts\logs\recuperacao.log -Tail 5` e explicar que a tarefa a cada 2 minutos cobre o caso em que alguém para o serviço manualmente.

## 5:40 a 6:40 · auditoria e logs

```powershell
auditpol /get /category:* | Select-String "Logon|Sistema de Arquivos|File System"
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4624,4663} -MaxEvents 5 | Select-Object TimeCreated, Id
Get-ChildItem C:\inetpub\logs\LogFiles -Recurse
```

Mostrar o Visualizador de Eventos no log Segurança e a pasta de logs do IIS.

Fala:
> A auditoria registra logons e acesso a arquivos, com sucesso e falha. A pasta do site e o compartilhamento têm lista de auditoria, então cada leitura gera um evento 4663. O IIS grava cada requisição no log do dia, nesta pasta.

## 6:40 a 7:00 · aplicação e encerramento

Tela: navegador com a página da CitizenTech.

Fala:
> A aplicação segue no ar depois do teste. Os scripts, o roteiro de configuração e as evidências estão no repositório do GitHub. Obrigado.

## Depois de gravar

- Confira a duração (máximo 7:00).
- Suba o vídeo (YouTube não listado ou o local que o professor indicar) e coloque o link no README.
