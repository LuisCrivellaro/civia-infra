# Roteiro do vídeo (até 7 minutos)

Segue a divisão de tempo do roteiro do professor (seção 10). Todos os comandos rodam pelo script `C:\Scripts\Demo-Video.ps1`, que mostra cada comando antes de executar e espera ENTER entre as partes. Assim ninguém precisa digitar durante a gravação.

As falas abaixo são uma base para falar com as próprias palavras, não um texto para decorar. Os valores citados são os da VM da equipe; confira se continuam iguais na tela na hora de gravar.

## Antes de gravar (10 minutos)

1. Feche o navegador, Discord, Steam e outros apps pesados. A VM precisa de 4 GB livres para ligar.
2. Ligue a VM, se estiver desligada: abra o Gerenciador do Hyper-V, clique com o botão direito em `SRV-CITIZENTECH` e escolha Iniciar. Espere uns 3 minutos.
3. Conecte por **Área de Trabalho Remota**, que já mostra o acesso remoto funcionando e deixa a tela maior que a janela do Hyper-V:
   - Win+R > `mstsc` > Computador: `192.168.0.250` > Mostrar opções > Exibição: tela inteira > Conectar;
   - usuário `CITIZENTECH\Administrator` e a senha.
4. Dentro da VM, abra o Edge em `http://srv-citizentech.citizentech.local` e deixe a janela à direita. Ele vai mostrar a página da Civia caindo e voltando no teste de falha.
5. Abra o PowerShell como Administrador à esquerda e aumente a fonte: clique no ícone da janela > Properties > Font > 20.
6. Ensaie uma vez com `C:\Scripts\Demo-Video.ps1 -Testar`, que roda tudo sem pausas e sem derrubar o IIS.

## Como gravar

Use uma destas opções:
- **Barra de Jogo do Windows:** com a janela da Área de Trabalho Remota em foco, aperte **Win+Alt+R** para começar e de novo para parar. O vídeo fica em Vídeos > Capturas. Ela grava só a janela em foco, então tudo precisa estar dentro da Área de Trabalho Remota em tela cheia.
- **OBS Studio** (gratuito): Fontes > + > Captura de tela > Iniciar gravação. Grava a tela inteira e o microfone.
- O **Medal**, que já está instalado no PC, também grava a tela, se preferirem.

Ligue o microfone, grave uma parte de teste de 10 segundos e confira o áudio. Se o tempo estourar, corte as pausas na edição (o Clipchamp, que vem no Windows, serve).

Para começar, no PowerShell da VM:

```powershell
C:\Scripts\Demo-Video.ps1
```

Se precisar regravar só uma parte: `C:\Scripts\Demo-Video.ps1 -ComecarNaParte 6`.

### Gravando em trechos

Também dá para gravar uma parte por vez e juntar depois. `-SoParte` roda só a parte pedida e para no fim, sem esperar ENTER:

```powershell
cls; C:\Scripts\Demo-Video.ps1 -SoParte 1
```

Para cada trecho: inicie a gravação, rode o comando com o número da parte, fale e pare a gravação. Na parte 6 o script ainda espera um ENTER para provocar a falha. Nas partes 4, 5 e 7 a janela que abre fica aberta; feche antes do próximo trecho. Para juntar os arquivos, o Clipchamp (vem no Windows) basta: arraste os trechos na ordem para a linha do tempo e exporte em 1080p.

## 0:00 a 0:40 · Parte 1: servidor, IP e domínio

Na tela: `hostname`, IPv4/máscara/DHCP, gateway, DNS, origem do IP (Manual) e `Get-ADDomain`.

> Somos a equipe ASTRO e esta é a infraestrutura de Operating Systems da Civia, nossos óculos inteligentes com aplicativo de acessibilidade urbana. O servidor é um Windows Server 2022 rodando no Hyper-V. O nome é SRV-CITIZENTECH e o IP é fixo: 192.168.0.250, com DHCP desligado e gateway 192.168.0.1. O DNS aponta para o próprio servidor, porque ele é o controlador do domínio citizentech.local. A conexão que vocês estão vendo é pela Área de Trabalho Remota.

## 0:40 a 1:30 · Parte 2: Active Directory e DNS

Na tela: `nslookup`, zonas DNS, usuários da OU e membros dos grupos.

> O nslookup resolve o nome do servidor para 192.168.0.250, e a zona citizentech.local é primária e integrada ao Active Directory. Criamos a OU CitizenTech com dois grupos: GG_CitizenTech_Admins, para quem administra o projeto, e GG_CitizenTech_Usuarios, para usuários comuns. A ana.souza e o bruno.teste são contas fictícias de teste. As permissões que vêm a seguir são dadas aos grupos, não às pessoas.

## 1:30 a 2:40 · Parte 3: IIS, pool e NTFS

Na tela: site Started em `C:\inetpub\citizentech`, pool `CitizenTechPool` sem código gerenciado, HTTP 200 e permissões da pasta. Mostre o Edge com a página.

> A Civia está publicada no IIS, no site CitizenTech, com um pool de aplicativos só dela. Seguimos o caminho A do roteiro, de site estático, por isso o pool não carrega o .NET. O site está Started e responde HTTP 200. Na pasta do site, o IIS_IUSRS tem só leitura e execução, porque o site não precisa gravar nada ali, e o grupo de administradores do projeto pode modificar para publicar o conteúdo. Esta é a página no navegador, ainda uma versão de demonstração da Civia.

## 2:40 a 3:30 · Parte 4: GPO e compartilhamento

Na tela: GPOs, link na OU, `NoControlPanel = 1`, compartilhamento e permissões. O Explorador abre `\\SRV-CITIZENTECH\CitizenTech`. Mostre também o print `evidencias/04-ntfs-gpo/07-gpo-painel-bloqueado-bruno.png`.

> A GPO_CitizenTech_Usuarios está vinculada à OU e bloqueia o Painel de Controle. Testamos com o bruno.teste: quando ele tentou abrir o Painel, o Windows mostrou a mensagem de restrição, que está neste print. O compartilhamento CitizenTech dá controle total ao grupo de administradores e só leitura aos usuários do domínio.

## 3:30 a 4:30 · Parte 5: monitoramento

Na tela: os dois Data Collector Sets em Running, execução do script, `monitor.log`, `alertas.log` e a tarefa agendada. O Monitor de Desempenho abre: clique em Data Collector Sets > User Defined para mostrar os dois conjuntos. Se der tempo, mostre o print `evidencias/05-monitoramento/09-perfmon-grafico-3-contadores.png`.

> O conjunto CitizenTech_Monitor grava CPU, memória disponível e espaço livre do disco a cada 15 segundos. O CitizenTech_Alertas é o alerta do próprio Monitor de Desempenho, com os limites do roteiro: CPU acima de 80 %, menos de 500 MB de memória e menos de 15 GB livres no disco. O script Monitor-Recursos faz a mesma verificação a cada 5 minutos pelo Agendador de Tarefas e grava cada medição. Para testar, colocamos a CPU em 100 % e o alerta foi registrado: está aqui no alertas.log e no gráfico, que mostra o pico.

## 4:30 a 5:40 · Parte 6: teste de falha e recuperação

Na tela: `sc.exe qfailure W3SVC`. Aperte ENTER para provocar a falha e olhe para o Edge.

> O serviço do IIS está configurado para reiniciar sozinho se cair: 5 segundos na primeira falha, 10 na segunda e 30 na terceira. Agora o script encerra à força o processo do serviço e também o processo que atende o site; se só o serviço cair, o site continua respondendo, então precisamos derrubar os dois. Olhem o passo 4: o site ficou fora do ar. O script não religa nada, só espera. Pronto, voltou em [tempo da tela] segundos, e o resultado diz "recuperação automática comprovada" pelo Service Control Manager. O evento 7031 no log do sistema confirma que foi o Windows que reiniciou o serviço. Também temos uma tarefa a cada 2 minutos que religa o site se alguém parar o serviço manualmente.

## 5:40 a 6:40 · Parte 7: auditoria e logs

Na tela: `auditpol` com Success and Failure, eventos 4663 e 4624 e a pasta de logs do IIS. O Visualizador de Eventos abre no log Security.

> A auditoria registra logons e acesso a arquivos, com sucesso e falha. A pasta do site e o compartilhamento têm lista de auditoria, então cada leitura gera um evento 4663; aqui aparecem o index.html e o style.css lidos pelo IIS. Os eventos 4624 são os logons. O IIS também grava cada requisição no log do dia, nesta pasta.

## 6:40 a 7:00 · Parte 8: encerramento

Na tela: HTTP 200 pelo nome do servidor e o Edge com a página.

> Depois do teste, a Civia segue no ar. Os scripts, o roteiro de configuração e todas as evidências estão no repositório civia-infra no GitHub. Obrigado!

## Depois de gravar

1. Confira a duração: no máximo 7:00.
2. Suba no YouTube como "Não listado" e copie o link.
3. Me mande o link: eu coloco uma linha "Vídeo:" no topo do README e publico no GitHub.
4. Desconecte a Área de Trabalho Remota. A VM pode ficar ligada ou ser desligada pelo Gerenciador do Hyper-V.
