# Roteiro de configuração na VM

Ordem de execução, o que cada passo faz e o que conferir antes de seguir. Os números de seção entre parênteses são do roteiro do professor.

Tudo é feito no console da VM, em um PowerShell aberto como Administrador. Mudanças de rede podem derrubar uma sessão remota, então não use RDP até o passo 9.

## 0. Antes de começar

Anote em um lugar fora do repositório: IP escolhido, gateway, senha do Administrator, senha DSRM e senha das contas de teste. Nenhuma senha vai para o Git.

### Criar a VM (3.1)

Usamos o Hyper-V do Windows 11 Pro, que está na lista de hipervisores aceitos pelo roteiro (VirtualBox, VMware, Hyper-V ou Azure). No computador usado, a segurança baseada em virtualização do Windows já ocupa o hipervisor, e o VirtualBox rodaria mais lento.

ISO: `SERVER_EVAL_x64FRE_en-us.iso`, avaliação de 180 dias do Microsoft Evaluation Center. Não há ISO em português; o sistema fica em inglês, e os scripts funcionam igual (nomes de grupos, contadores e auditoria são resolvidos independentemente do idioma).

No host, em um PowerShell como Administrador, depois de ativar o Hyper-V e reiniciar:

```powershell
cd C:\Projetos\OS GS\scripts\host
Set-ExecutionPolicy -Scope Process Bypass
.\Criar-VM-HyperV.ps1 -IsoPath "$env:USERPROFILE\Downloads\SERVER_EVAL_x64FRE_en-us.iso"
Start-VM -Name SRV-CITIZENTECH
vmconnect.exe localhost SRV-CITIZENTECH
```

O script cria o switch externo `Civia-Externo` (equivalente ao modo Bridge: a VM recebe um IP da rede de casa; a rede do host cai por alguns segundos na criação), e a VM geração 2 com 4 GB de RAM fixa, 2 vCPUs e disco de 60 GB, dando boot pela ISO.

Instalação:
1. Na janela da VM, aperte uma tecla quando aparecer "Press any key to boot from CD or DVD". Se passar do tempo, desligue e ligue a VM de novo.
2. Idioma: English. Em "Keyboard or input method", escolha **Portuguese (Brazil ABNT2)** para o teclado funcionar certo nas senhas.
3. Edição: **Windows Server 2022 Standard Evaluation (Desktop Experience)**.
4. "Custom: Install Microsoft Server Operating System only", disco de 60 GB, avançar.
5. Defina a senha do Administrator. Para fazer login na janela do Hyper-V, use o botão Ctrl+Alt+Del da barra da janela.
6. Print: área de trabalho com `winver` aberto. Salve como `evidencias/01-rede/00-winver.png`.

### Levar o repositório para a VM

Na VM, abra o Edge, baixe o ZIP de `https://github.com/LuisCrivellaro/civia-infra` (Code > Download ZIP) e extraia em `C:\civia-infra`. Faça isso antes do passo 3, enquanto a VM ainda tem internet pelo DHCP.

```powershell
Set-ExecutionPolicy -Scope Process Bypass
cd C:\civia-infra\scripts
Get-ChildItem -Recurse | Unblock-File      # tira a marca de "baixado da internet"
```

Sistema em inglês: onde este roteiro cita telas em português, o nome em inglês é: Visualizador de Eventos = Event Viewer, log Segurança = Security, log Sistema = System, Agendador de Tarefas = Task Scheduler, "Serviço de Publicação na World Wide Web" = World Wide Web Publishing Service, aba Recuperação = Recovery, Monitor de Desempenho = Performance Monitor, Conjuntos de Coletores de Dados > Definido pelo Usuário = Data Collector Sets > User Defined, aba Segurança = Security.

## 1. Rede: diagnóstico (3.2)

```powershell
.\Configurar-Rede.ps1
```

Só lê. Mostra os adaptadores, o `ifIndex`, o IP atual, gateway e DNS. Com isso, ajuste em `config\CitizenTech.config.psd1` os campos `Rede.IPAddress`, `PrefixLength`, `Gateway` e `DnsServers` (DNS = o próprio IP). O IP precisa estar na mesma sub-rede do gateway e fora da faixa do DHCP do roteador.

## 2. Hostname (3.2)

```powershell
.\Configurar-Rede.ps1 -Acao Renomear -Reiniciar
```

Pede confirmação e reinicia. Depois do reboot, `hostname` deve mostrar `SRV-CITIZENTECH`.

## 3. IP fixo (3.2)

```powershell
.\Configurar-Rede.ps1 -Acao IPFixo -InterfaceIndex <ifIndex>
ipconfig /all
```

O script testa se o IP já está em uso, desliga o DHCP, aplica IP, máscara, gateway e DNS. Print do `ipconfig /all` em `evidencias/01-rede/`.

Antes da promoção do domínio o DNS aponta para um servidor que ainda não existe, então a VM fica sem resolver nomes da internet. É esperado. Se precisar da internet nesse meio-tempo (para baixar o repositório, por exemplo), faça isso antes deste passo.

## 4. Active Directory e DNS (3.3)

```powershell
.\Configurar-AD.ps1 -Etapa InstalarRecurso
.\Configurar-AD.ps1 -Etapa PromoverDominio
```

A promoção confere hostname e IP fixo, roda `Test-ADDSForestInstallation`, pede a senha DSRM e reinicia a VM sozinha. Depois do reboot, faça logon como `CITIZENTECH\Administrator`.

Opcional: para a VM voltar a resolver nomes da internet, adicione um encaminhador no DNS com o gateway ou um DNS público: `Add-DnsServerForwarder -IPAddress <gateway>`.

## 5. Validar domínio e DNS (3.4) e criar OU, grupos e usuários (3.5)

```powershell
.\Configurar-AD.ps1 -Etapa CriarObjetos
Get-ADDomain | Select-Object Name, DNSRoot, DomainMode
nslookup srv-citizentech.citizentech.local
Get-DnsServerZone
```

O script cria a OU `CitizenTech`, os grupos `GG_CitizenTech_Admins` e `GG_CitizenTech_Usuarios` e as contas fictícias `ana.souza` e `bruno.teste`. Pede uma senha inicial (precisa atender à complexidade padrão: 7+ caracteres com maiúscula, minúscula, número ou símbolo). No fim mostra as duas validações do roteiro. Rodar de novo não duplica nada.

Prints: `Get-ADDomain`, `nslookup`, `Get-DnsServerZone`, usuários e grupos em `evidencias/02-ad-dns/`.

## 6. IIS e aplicação (4.1, 4.2, 4.4)

```powershell
.\Configurar-IIS.ps1
```

Instala IIS e ferramentas, copia `app\` para `C:\inetpub\citizentech`, para o Default Web Site (ele ocupa a porta 80), cria o pool `CitizenTechPool` sem código gerenciado e o site `CitizenTech`, aplica NTFS (`IIS_IUSRS` leitura, admins do projeto modificar), libera a regra HTTP do firewall e testa `http://localhost/`.

Prints em `evidencias/03-iis/`:
- `Get-Website` e `Get-WebAppPoolState` (o script mostra os dois);
- navegador de outra máquina (ou do host) em `http://<IP do servidor>` com a página carregada;
- `Get-Acl C:\inetpub\citizentech | Format-List` e a aba Segurança da pasta.

## 7. File Server, GPO, RDP e auditoria (4.5, 5.1, 5.2, 5.4)

```powershell
.\Configurar-Infraestrutura.ps1
```

Cada componente roda separado; se um falhar, os outros continuam e o erro aparece no fim. Para rodar só um: `-Componentes GPO`.

### Compartilhamento

Cria `\\SRV-CITIZENTECH\CitizenTech` com controle total para `GG_CitizenTech_Admins` e leitura para `Domain Users`, nas permissões de compartilhamento e no NTFS. Print do `Get-SmbShare` e do acesso a `\\SRV-CITIZENTECH\CitizenTech` pelo Explorador de Arquivos de um cliente (ou pelo próprio servidor, se não houver cliente).

### GPO

Cria `GPO_CitizenTech_Usuarios`, vincula à OU e define `NoControlPanel = 1`. O relatório HTML fica em `C:\Scripts\logs\GPO_Report.html`.

Para o print do usuário sem Painel de Controle é preciso fazer logon com `bruno.teste`:
- Caminho recomendado: uma VM cliente Windows 10/11 na mesma rede, com DNS apontando para o servidor, ingressada no domínio (`Add-Computer -DomainName citizentech.local -Restart`). Logon como `CITIZENTECH\bruno.teste`, `gpupdate /force`, tentar abrir o Painel de Controle.
- Alternativa só de laboratório, sem segunda VM: no servidor, abra o Gerenciamento de Política de Grupo, edite a `Default Domain Controllers Policy` em Configuração do Computador > Políticas > Configurações do Windows > Configurações de Segurança > Políticas Locais > Atribuição de Direitos de Usuário > "Permitir logon local" (em inglês: Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > User Rights Assignment > "Allow log on locally"), e adicione `GG_CitizenTech_Usuarios` (mantendo os grupos que já estão lá). `gpupdate /force`, troque de usuário e entre como `bruno.teste`. Depois da gravação, desfaça a mudança. Isso não é configuração de produção; registre no README se usar.

Evidência por comando: `Get-GPO -All`, `Get-GPInheritance -Target "OU=CitizenTech,DC=citizentech,DC=local"` e `gpresult /r` na sessão do usuário.

### RDP

Liga o RDP com NLA e limita as regras de firewall à sub-rede local. Não abra a porta 3389 no roteador. Print: conexão RDP de outra máquina (`mstsc /v:<IP>`) com `hostname` digitado no terminal remoto.

### Auditoria

Liga sucesso e falha para Logon e File System (por GUID) e coloca SACL de leitura e escrita para Everyone em `C:\inetpub\citizentech` e `C:\Shares\CitizenTech`. Para gerar eventos de acesso a arquivo, abra o site no navegador e um arquivo do compartilhamento.

Em controlador de domínio a `Default Domain Controllers Policy` é reaplicada periodicamente. Depois de um `gpupdate /force`, confira com `auditpol /get /category:*` se as duas subcategorias continuam com sucesso e falha. Se uma voltar para "Sem auditoria", configure a mesma coisa em Configuração Avançada de Política de Auditoria dentro dessa GPO.

### DFS (opcional)

Só depois que o resto estiver validado:

```powershell
.\Configurar-Infraestrutura.ps1 -Componentes DFS
Get-DfsnRoot
```

## 8. Monitoramento (6.1 a 6.3)

```powershell
.\Configurar-Monitoramento.ps1
```

Cria os Data Collector Sets `CitizenTech_Monitor` (3 contadores, a cada 15 s, arquivos `.blg` em `C:\PerfLogs\CitizenTech`) e `CitizenTech_Alertas` (limites de CPU, memória e disco), a fonte de eventos `CitizenTechMonitor`, copia os scripts para `C:\Scripts` e registra a tarefa `CitizenTech_Monitor_Alertas` a cada 5 minutos. No fim roda o script de alerta uma vez.

Prints em `evidencias/05-monitoramento/`:
- `perfmon` > Conjuntos de Coletores de Dados > Definido pelo Usuário, com os dois conjuntos em execução;
- o gráfico com os três contadores (Monitor de Desempenho > adicionar os contadores, ou abrir o `.blg`);
- execução de `powershell -ExecutionPolicy Bypass -File C:\Scripts\Monitor-Recursos.ps1`;
- Agendador de Tarefas com a tarefa e a aba Histórico, depois de pelo menos 10 minutos.

Para mostrar o caminho do alerta sem estressar a VM: `C:\Scripts\Monitor-Recursos.ps1 -ModoTeste`. As medições continuam reais, mas os limites são trocados por valores que sempre disparam, e tudo fica marcado como `[TESTE]` em `alertas-teste.log` e no evento 9100. Diga isso no vídeo.

Para um alerta real de CPU, dá para gerar carga por um minuto e deixar a tarefa ou o Data Collector Set de alerta pegar:

```powershell
$fim = (Get-Date).AddSeconds(90)
1..([Environment]::ProcessorCount) | ForEach-Object { Start-Job { param($f) while ((Get-Date) -lt $f) { } } -ArgumentList $fim } | Out-Null
C:\Scripts\Monitor-Recursos.ps1      # deve mostrar "CPU alta" em amarelo
Get-Job | Remove-Job -Force
```

## 9. Recuperação automática (7.1 e 7.3)

```powershell
.\Configurar-Recuperacao.ps1
sc.exe qfailure W3SVC
```

Configura `rapidFailProtection=false` e `autoStart=true` no pool, `sc.exe failure` no W3SVC e no WAS (`restart/5000/restart/10000/restart/30000`, reset de 1 dia) e a tarefa `CitizenTech_Recuperacao` a cada 2 minutos.

Prints em `evidencias/06-teste-falha/`: `sc.exe qfailure W3SVC` e a aba Recuperação do serviço "Serviço de Publicação na World Wide Web" no `services.msc`.

## 10. Teste de falha (7.2)

Só na VM. Deixe o navegador aberto na página do site (ela consulta o servidor a cada 5 s e mostra quando cai e quando volta).

```powershell
C:\Scripts\Teste-Falha.ps1                 # modo Crash: SCM recupera
C:\Scripts\Teste-Falha.ps1 -Modo Parada    # Stop-Service: a tarefa recupera (até 2 min)
Get-Content C:\Scripts\logs\recuperacao.log -Tail 10
Get-Content C:\Scripts\logs\teste-falha-resumo.log
```

O script pede que você digite `SIM`. Ele mostra os passos [1] a [7] e termina com uma destas linhas:
- `RECUPERACAO AUTOMATICA COMPROVADA`, com o mecanismo (Service Control Manager ou tarefa agendada) e o tempo até voltar;
- `INCONCLUSIVO`, se a queda não foi observada;
- `FALHA`, se não voltou.

O resultado só conta para o critério se for o primeiro. Não use `-PermitirFallbackManual` na gravação; ele existe só para religar o serviço se algo der errado e marca o resultado como manual.

Prints: o terminal com os passos, o navegador fora do ar e voltando, o `recuperacao.log` e o evento 7031 no Visualizador de Eventos (log Sistema).

## 11. Logs e auditoria (5.4)

```powershell
auditpol /get /category:*
Get-WinEvent -LogName Security -MaxEvents 20 | Select-Object TimeCreated, Id, Message
Get-ChildItem "C:\inetpub\logs\LogFiles" -Recurse | Select-Object FullName, Length
```

Prints em `evidencias/07-logs/`: Visualizador de Eventos no log Segurança (filtre 4624 e 4663) e a pasta de logs do IIS aberta.

## 12. Validação final e coleta (8.1)

```powershell
cd C:\civia-infra\scripts
.\Validar-Ambiente.ps1
.\Coletar-Evidencias.ps1
```

`Validar-Ambiente.ps1` mostra `PASSOU`, `FALHOU` ou `ERRO` em cada item e salva TXT e CSV em `evidencias/00-validacao/`. Corrija o que falhou e rode de novo. `Coletar-Evidencias.ps1` salva a saída real dos comandos em cada pasta de `evidencias/`, inclusive o bloco de validação final do roteiro em `evidencias/00-validacao/00-ficha-infraestrutura.txt`.

O roteiro pede o print do bloco de validação final inteiro. Rode os comandos da seção 8.1 em uma janela maximizada e capture.

Antes de publicar, abra os `.txt` e confira se não há nada que não deva ir para o GitHub.

## 13. Fechamento

1. Copie a pasta `evidencias/` da VM para o repositório no computador principal.
2. Atualize os status no `README.md` e em `docs/checklist-entrega.md` com base no que a validação mostrou.
3. Preencha a ficha da CitizenTech e os integrantes.
4. Grave o vídeo seguindo `docs/roteiro-video.md`.
