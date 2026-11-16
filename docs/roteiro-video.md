# Roteiro do vídeo (até 7 minutos)

O vídeo segue a divisão de tempo do roteiro do professor (seção 10) e é gravado em 8 trechos, um por parte. Cada trecho é um comando no PowerShell da VM. O script mostra o resultado na tela e você fala olhando para ele.

Em cada parte, a tabela diz o que aparece na tela e o que falar enquanto aquilo está aparecendo. Passe o mouse em cima do que estiver explicando, porque ajuda quem assiste. As falas são uma base, então pode trocar as palavras. Os números são os da nossa VM.

## Palavras difíceis

Na fala, prefira o nome em português. A sigla aparece na tela e não precisa ser lida letra por letra toda vez.

| Na tela | Como falar | O que é |
|---|---|---|
| IIS | "í-í-ésse" ou "o servidor web da Microsoft" | o programa que publica o site |
| pool (CitizenTechPool) | "pul" ou "pool de aplicativos" | o processo separado que roda o site |
| AD / Active Directory | "ácti-diréctori" | o cadastro de usuários e computadores do domínio |
| OU | "unidade organizacional" | uma pasta dentro do AD onde ficam nossos usuários e grupos |
| DNS | "dê-ene-ésse" | traduz nome em endereço IP |
| DHCP | "dê-agá-cê-pê" | entrega IP automático (no servidor está desligado) |
| gateway | "gueitwei" | o roteador, a saída para a internet |
| GPO | "política de grupo" | uma regra aplicada nos usuários (a nossa bloqueia o Painel de Controle) |
| NTFS | "permissões da pasta" | quem pode ler ou alterar os arquivos |
| HTTP 200 / StatusCode 200 | "código duzentos" | a página abriu normalmente |
| RDP | "Área de Trabalho Remota" | o acesso remoto que estamos usando para gravar |
| Data Collector Set | "conjunto coletor de dados" | o que o Monitor de Desempenho usa para gravar e alertar |
| Running / Started | "rodando" / "iniciado" | está ligado |
| W3SVC | "serviço do IIS" | o serviço do Windows que mantém o IIS no ar |
| Service Control Manager | "gerenciador de serviços do Windows" | quem religa o serviço sozinho |
| auditpol | "a configuração de auditoria" | o que o Windows registra no log de segurança |
| 4624, 4663, 7031 | "evento quatro-seis-dois-quatro" etc. | números dos eventos no Visualizador de Eventos |

## Como gravar cada trecho

1. No OBS, clique em **Iniciar gravação** e volte para a Área de Trabalho Remota.
2. No PowerShell da VM, rode o comando da parte, por exemplo `cls; C:\Scripts\Demo-Video.ps1 -SoParte 1`.
3. Espere o resultado aparecer e fale seguindo a tabela, de cima para baixo. Se a tela ficar cheia, role com a rodinha do mouse.
4. Minimize a Área de Trabalho Remota pela barrinha do topo e clique em **Parar gravação** no OBS.

Antes de começar, faça um ensaio com `C:\Scripts\Demo-Video.ps1 -Testar`, que roda tudo sem pausas e sem derrubar o site.

---

## Parte 1 (0:00 a 0:40): servidor, IP fixo e domínio

```powershell
cls; C:\Scripts\Demo-Video.ps1 -SoParte 1
```

| Na tela | Fale |
|---|---|
| (antes do resultado, ou no comecinho) | "Somos a equipe ASTRO e este é o servidor da Civia, nossos óculos inteligentes com aplicativo de acessibilidade urbana. É um Windows Server 2022 rodando no Hyper-V, e estou conectado nele pela Área de Trabalho Remota." |
| `hostname` → `SRV-CITIZENTECH` | "O nome do servidor é SRV-CITIZENTECH." |
| linhas do `ipconfig`: `DHCP Enabled: No`, `IPv4 Address 192.168.0.250`, `Subnet Mask 255.255.255.0` | "O IP é fixo, 192.168.0.250, com máscara 255.255.255.0. O DHCP está desligado." |
| `Get-NetRoute` → `NextHop 192.168.0.1` | "O gateway, que é o nosso roteador, é o 192.168.0.1." |
| `Get-DnsClientServerAddress` → `192.168.0.250` | "O DNS aponta para o próprio servidor, porque ele mesmo é o servidor de DNS do domínio." |
| `Get-NetIPAddress` → `PrefixOrigin Manual` | "Aqui aparece Manual, ou seja, o IP foi configurado à mão." |
| `Get-ADDomain` → `citizentech.local` | "E o domínio é o citizentech.local, criado com o Active Directory." |

## Parte 2 (0:40 a 1:30): Active Directory e DNS

```powershell
cls; C:\Scripts\Demo-Video.ps1 -SoParte 2
```

| Na tela | Fale |
|---|---|
| `nslookup` → `Name: srv-citizentech.citizentech.local`, `Address: 192.168.0.250` | "O nslookup pergunta ao DNS qual é o IP do servidor, e ele responde 192.168.0.250. Então o DNS está funcionando." |
| `Get-DnsServerZone` → `citizentech.local`, `Primary`, `True` | "Esta é a zona do domínio, citizentech.local. Ela é primária, e o True quer dizer que fica guardada dentro do Active Directory." |
| `Get-ADUser` → `ana.souza` e `bruno.teste` | "Criamos uma unidade organizacional chamada CitizenTech com dois usuários de teste, a ana.souza e o bruno.teste. São contas fictícias." |
| `Get-ADGroupMember` → `GG_CitizenTech_Admins` com ana.souza, `GG_CitizenTech_Usuarios` com bruno.teste | "E dois grupos: o de administradores do projeto, onde está a Ana, e o de usuários comuns, onde está o Bruno. As permissões que vou mostrar são dadas aos grupos, não a cada pessoa." |

## Parte 3 (1:30 a 2:40): o site no IIS e as permissões

```powershell
cls; C:\Scripts\Demo-Video.ps1 -SoParte 3
```

| Na tela | Fale |
|---|---|
| `Get-Website` → `CitizenTech`, `Started`, `C:\inetpub\citizentech`, `CitizenTechPool` | "A página da Civia está publicada no IIS, que é o servidor web do Windows. O site se chama CitizenTech, está iniciado e os arquivos ficam nesta pasta." |
| bloco do pool → `Estado: Started`, `Runtime: '' (sem codigo gerenciado)`, `AutoStart: True` | "O site roda num pool de aplicativos só dele, o CitizenTechPool. Como a página é estática, só HTML, CSS e JavaScript, o pool não carrega o .NET. E o AutoStart faz ele ligar sozinho." |
| `Invoke-WebRequest` → `StatusCode 200` | "Testando o acesso, o servidor responde código 200, que quer dizer que a página abriu." |
| `Get-Acl` → `IIS_IUSRS ReadAndExecute` e `GG_CitizenTech_Admins Modify` | "Nas permissões da pasta, o IIS só pode ler os arquivos, porque o site não precisa gravar nada. O grupo de administradores pode modificar, para conseguir atualizar a página." |
| aponte para o **Edge** com a página | "E esta é a página no navegador, ainda uma versão de demonstração da Civia." |

## Parte 4 (2:40 a 3:30): política de grupo e pasta compartilhada

```powershell
cls; C:\Scripts\Demo-Video.ps1 -SoParte 4
```

O Explorador abre sozinho no fim. Fale primeiro sobre o PowerShell e depois mostre a janela.

| Na tela | Fale |
|---|---|
| `Get-GPO` → `GPO_CitizenTech_Usuarios` | "Criamos uma política de grupo, a GPO_CitizenTech_Usuarios." |
| `Get-GPInheritance` → `Enabled True` na OU CitizenTech | "Ela está ligada à nossa unidade organizacional, então vale para os usuários do projeto." |
| `NoControlPanel` → `Value 1` | "A regra dela é esta: bloqueia o Painel de Controle. O 1 quer dizer ligado." |
| (opcional) o print `evidencias/04-ntfs-gpo/07-gpo-painel-bloqueado-bruno.png` | "Testamos entrando com o bruno.teste. Ele tentou abrir o Painel de Controle e o Windows bloqueou, como aparece neste print." |
| `Get-SmbShare` → `CitizenTech`, `C:\Shares\CitizenTech` e as permissões | "Também criamos a pasta compartilhada CitizenTech. O grupo de administradores tem controle total e os usuários do domínio só podem ler." |
| janela do **Explorador** em `\\SRV-CITIZENTECH\CitizenTech` | "E aqui ela aberta pela rede, pelo caminho do servidor." |

Feche o Explorador depois de parar a gravação.

## Parte 5 (3:30 a 4:30): monitoramento

```powershell
cls; C:\Scripts\Demo-Video.ps1 -SoParte 5
```

O Monitor de Desempenho abre sozinho no fim. A saída é longa: comece rolando para cima.

| Na tela | Fale |
|---|---|
| `logman query CitizenTech_Monitor` → `Status: Running` e os contadores de processador, memória e disco | "Para monitorar o servidor usamos o Monitor de Desempenho. Este conjunto, o CitizenTech_Monitor, está rodando e grava o uso de CPU, a memória livre e o espaço livre do disco a cada 15 segundos." |
| `logman query CitizenTech_Alertas` → `Running` e os limites | "Este outro é o de alertas. Ele avisa se a CPU passar de 80 %, se a memória livre ficar abaixo de 500 MB ou se o disco tiver menos de 15 GB livres." |
| linha verde do `Monitor-Recursos.ps1` | "Também fizemos um script em PowerShell que faz a mesma verificação. Rodando agora, ele mostra que está tudo normal." |
| `monitor.log` | "Cada verificação fica gravada neste arquivo de log." |
| `alertas.log` → linhas com `CPU alta: 100%` | "Para testar o alerta, deixamos a CPU em 100 % de propósito, e o alerta foi registrado aqui." |
| `Get-ScheduledTaskInfo` → `LastRunTime`, `LastTaskResult 0`, `NextRunTime` | "O script roda sozinho a cada 5 minutos pelo Agendador de Tarefas. Dá para ver a última execução, o resultado zero, que quer dizer sem erro, e a próxima." |
| janela do **Monitor de Desempenho**: clique em Data Collector Sets > User Defined | "E aqui estão os dois conjuntos no Monitor de Desempenho." |

Feche o Monitor de Desempenho depois de parar a gravação.

## Parte 6 (4:30 a 5:40): teste de falha

```powershell
cls; C:\Scripts\Demo-Video.ps1 -SoParte 6
```

Antes de gravar, deixe o Edge visível ao lado do PowerShell. Esta parte espera um ENTER para provocar a falha.

| Na tela | Fale |
|---|---|
| `sc.exe qfailure W3SVC` → três linhas `RESTART -- Delay = 5000`, `10000` e `30000 milliseconds` | "Agora o teste de falha. O serviço do IIS está configurado para reiniciar sozinho se cair: depois de 5 segundos na primeira falha, 10 na segunda e 30 na terceira." |
| aperte **ENTER** | "Vou derrubar o serviço à força, como se ele tivesse travado." |
| `[3] Provocando a falha` → linhas vermelhas `encerrado a forca` | "O script encerrou o processo do IIS e também o processo que atende o site. Só derrubar o serviço não basta, porque o site continua respondendo pelo outro processo." |
| `[4]` → `Site indisponivel` | "Aqui o site saiu do ar." Aponte para o **Edge**, que mostra "sem resposta". |
| `[5] Aguardando recuperacao automatica` | "Agora o script só espera, sem religar nada." |
| `RESULTADO: RECUPERACAO AUTOMATICA COMPROVADA` e `Tempo ate voltar` | "Voltou sozinho em [leia o número da tela] segundos. Quem religou foi o gerenciador de serviços do Windows." Aponte para o Edge, que volta a mostrar "HTTP 200 (no ar)". |
| eventos `7031` | "O evento 7031 no log do sistema confirma que o serviço caiu e que o Windows mandou reiniciar. Também temos uma tarefa agendada que religa o site a cada 2 minutos, caso alguém pare o serviço manualmente." |

## Parte 7 (5:40 a 6:40): auditoria e logs

```powershell
cls; C:\Scripts\Demo-Video.ps1 -SoParte 7
```

O Visualizador de Eventos abre sozinho no fim, no log Security.

| Na tela | Fale |
|---|---|
| `auditpol` → `Logon` e `File System` com `Success and Failure` | "Ligamos a auditoria do Windows para registrar logons e acesso a arquivos, tanto os que deram certo quanto os que falharam." |
| tabela com `4663` e nomes de arquivos | "O evento 4663 é o acesso a arquivo. A pasta do site e a pasta compartilhada estão sendo auditadas, então cada arquivo lido aparece aqui." |
| `4624` | "E o 4624 é o registro de cada logon." |
| lista dos arquivos em `C:\inetpub\logs\LogFiles` | "O IIS também guarda um log por dia com cada acesso ao site, nesta pasta." |
| janela do **Visualizador de Eventos** | "E aqui os mesmos eventos no Visualizador de Eventos, no log de segurança." |

Feche o Visualizador de Eventos depois de parar a gravação.

## Parte 8 (6:40 a 7:00): encerramento

```powershell
cls; C:\Scripts\Demo-Video.ps1 -SoParte 8
```

| Na tela | Fale |
|---|---|
| `StatusCode 200` pelo nome `srv-citizentech.citizentech.local` | "Depois do teste, a Civia continua no ar, agora acessada pelo nome do servidor." |
| `Fim da demonstracao` e o Edge | "Os scripts, o passo a passo da configuração e todas as evidências estão no nosso repositório civia-infra no GitHub. Obrigado!" |

---

## Juntar e enviar

1. Abra o Clipchamp (vem no Windows), arraste os 8 trechos na ordem para a linha do tempo e corte os começos e fins sobrando.
2. Confira a duração total: no máximo 7:00.
3. Exporte em 1080p, suba no YouTube como "Não listado" e copie o link.
4. Mande o link para colocar no README.
