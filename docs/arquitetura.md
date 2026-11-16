# Arquitetura e decisões

Um único servidor, `SRV-CITIZENTECH`, faz o papel de controlador de domínio, DNS, servidor web e servidor de arquivos. Em produção essas funções ficariam separadas. Aqui ficam juntas porque o roteiro pede uma VM e porque o foco é mostrar cada serviço funcionando.

## Componentes

| Componente | O que faz no projeto | Como foi configurado |
|---|---|---|
| Rede | dá ao servidor um endereço que não muda | IP fixo, DNS apontando para o próprio servidor |
| AD DS | guarda usuários, grupos e computadores do domínio | floresta `citizentech.local`, OU `CitizenTech` |
| DNS | traduz `srv-citizentech.citizentech.local` para o IP | zona primária integrada ao AD, criada na promoção |
| IIS | entrega a aplicação web | site `CitizenTech` na porta 80, pool `CitizenTechPool` |
| NTFS | define quem lê e quem altera os arquivos | `IIS_IUSRS` leitura no site, admins do projeto modificam |
| File Server | pasta de arquivos do projeto na rede | `\\SRV-CITIZENTECH\CitizenTech` |
| GPO | aplica regra a todos os usuários da OU | `GPO_CitizenTech_Usuarios` bloqueia o Painel de Controle |
| RDP | administração remota | NLA, só sub-rede local |
| Monitoramento | mede CPU, memória e disco e avisa quando passam do limite | dois Data Collector Sets e um script agendado |
| Recuperação | põe o site de volta no ar sozinho | recuperação do serviço no SCM e tarefa de vigilância |
| Auditoria | registra logons e acesso a arquivos | `auditpol`, SACL nas pastas, logs do IIS |

## Por que cada configuração

### IP fixo e DNS apontando para si mesmo

O controlador de domínio precisa de um endereço estável porque os clientes o encontram pelo DNS. Se o IP mudasse pelo DHCP, o registro no DNS ficaria errado. O servidor aponta o DNS para ele mesmo porque é ele quem responde pela zona `citizentech.local`; se apontasse para o roteador, não acharia os registros do domínio.

### AD DS, OU e grupos

O domínio centraliza contas: o usuário é criado uma vez e vale em qualquer máquina do domínio. A OU `CitizenTech` agrupa as contas do projeto e é onde a GPO é vinculada. As permissões são dadas a grupos, não a usuários: para dar acesso a alguém novo basta colocá-lo no grupo. O prefixo `GG_` indica grupo global, o escopo usado para reunir usuários do mesmo domínio.

### IIS, pool e Caminho A

O IIS recebe a requisição HTTP e entrega os arquivos. O pool de aplicativos é o processo (`w3wp.exe`) que atende o site; um pool separado isola o site de outros e pode ser reiniciado sozinho. Como a página é estática, o pool fica sem código gerenciado (`managedRuntimeVersion` vazio). Com runtime .NET configurado sem necessidade, o IIS tentaria carregar o .NET e o roteiro avisa que isso pode dar erro 500.19.

O Default Web Site foi parado porque também usa a porta 80. Dois sites no mesmo IP e porta, sem nome de host, não sobem juntos.

### NTFS do site

`IIS_IUSRS` é o grupo local de onde vêm as identidades dos pools. Ele precisa só de leitura e execução, porque o site não grava nada na própria pasta. Se o processo do site for comprometido, a identidade do pool não tem permissão para alterar os arquivos. O grupo `GG_CitizenTech_Admins` recebe "modificar" para quem publica o conteúdo.

### Compartilhamento

Existem duas camadas de permissão: a do compartilhamento (vale para quem acessa pela rede) e a do NTFS (vale sempre). O acesso efetivo é a mais restritiva das duas. As duas foram configuradas iguais: admins do projeto com controle total ou modificar, usuários do domínio com leitura. A enumeração baseada em acesso esconde as pastas que o usuário não pode abrir. O acesso "Everyone" foi retirado.

### GPO

A GPO é a forma de aplicar a mesma configuração a muitos usuários sem tocar em cada máquina. A política escolhida (bloqueio do Painel de Controle) é a sugerida no roteiro e tem efeito fácil de ver. Ela está em Configuração do Usuário (`HKCU`), então vale para os usuários dentro da OU, em qualquer computador do domínio em que fizerem logon. A conta Administrator fica no contêiner `Users`, fora da OU, e não é afetada.

### RDP

O RDP dá acesso completo ao servidor. Por isso fica com NLA (autentica antes de abrir a sessão) e só aceita conexões da sub-rede local. A função RDS não foi instalada: ela serve para várias sessões de usuários e não é recomendada em controlador de domínio.

### Monitoramento

São três camadas, cada uma com um papel:
- `CitizenTech_Monitor` grava os três contadores a cada 15 s em `.blg`. É o histórico, que abre como gráfico no Monitor de Desempenho.
- `CitizenTech_Alertas` é o alerta nativo do Monitor de Desempenho. Quando um limite é ultrapassado, gera o evento 2031.
- `Monitor-Recursos.ps1`, a cada 5 min pela tarefa agendada, mede, compara, grava uma linha em `monitor.log` e, se houver alerta, escreve em `alertas.log` e no log Application (evento 9001).

Contadores usados: `% Processor Time` (uso de CPU), `Available MBytes` (memória livre) e `% Free Space` / espaço livre em C:. Os limites (80 %, 500 MB, 15 GB) são os do roteiro. Para a VM de 60 GB, 15 GB livres corresponde a 25 % do disco.

### Recuperação automática

Dois mecanismos, porque cada um cobre um tipo de falha:
- Ações de recuperação do Service Control Manager (`sc.exe failure`). Se o processo do W3SVC morre sem avisar, o Windows o reinicia em 5 s, depois em 10 s e depois em 30 s, e zera a contagem depois de um dia. Isso não age se alguém para o serviço de propósito com `Stop-Service`; o Windows entende que a parada foi intencional.
- A tarefa `CitizenTech_Recuperacao` roda `Recupera-Site.ps1` a cada 2 minutos como SYSTEM. Ela confere W3SVC, pool, site e a resposta HTTP, e religa o que estiver parado. Cobre a parada limpa e o pool parado.

No pool, `rapidFailProtection` desligado evita que o IIS desative o pool depois de várias falhas seguidas do `w3wp.exe`, e `autoStart` faz o pool subir junto com o serviço.

O `Teste-Falha.ps1` não religa nada por conta própria. Ele só provoca a falha, mede e observa. Se o site voltar, procura a prova de quem o religou: o evento 7031 do SCM ou uma linha nova `AGENDADA` no `recuperacao.log`.

### Auditoria

`auditpol` liga a auditoria das subcategorias Logon (eventos 4624 sucesso e 4625 falha) e File System. A auditoria de arquivos só gera eventos nas pastas que têm SACL (lista de auditoria). Por isso a SACL foi colocada na pasta do site e no compartilhamento. Os logs do IIS ficam em `C:\inetpub\logs\LogFiles\W3SVC<id>`, um arquivo por dia, com cada requisição recebida.

## Fluxo de uma requisição

1. O navegador pede `http://srv-citizentech.citizentech.local/` (ou o IP).
2. O DNS do servidor responde com o IP.
3. O `http.sys` recebe na porta 80 e passa para o pool `CitizenTechPool`.
4. O `w3wp.exe` lê `C:\inetpub\citizentech\index.html` com a permissão de `IIS_IUSRS` e responde 200.
5. O IIS grava a linha no log do dia; se a SACL estiver ativa, o acesso ao arquivo também gera evento 4663.

## Segurança do laboratório

- Senhas nunca entram no repositório; os scripts pedem com `Read-Host -AsSecureString` ou recebem um `SecureString` por parâmetro (usado no PowerShell Direct).
- As contas de teste são fictícias.
- O servidor fica só na rede local (switch externo do Hyper-V), sem redirecionamento de portas no roteador.
- O teste de falha recusa rodar fora de Windows Server e pede confirmação.
