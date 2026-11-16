# Registro de uso de IA

O documento geral da GS permite IA "como copiloto" e pede o registro dos prompts neste arquivo. Abaixo estão os pedidos feitos, a ferramenta usada, o que a IA fez e o que ficou com a equipe.

Ferramenta: Claude Code (modelo Claude Opus 5.5), no aplicativo desktop, em uma única sessão continuada de 14/11 a 16/11/2026. A sessão foi resumida automaticamente algumas vezes por limite de contexto e continuou do mesmo ponto.

## Prompts

### Prompt 1: missão da entrega de Operating Systems (14/11)

Resumo do pedido. O texto integral foi colado na sessão; ele pode ser mostrado ao professor se for pedido.

- Atuar como engenheiro de infraestrutura Windows Server e como revisor de português.
- Ler os dois PDFs; o roteiro de Operating Systems é a fonte principal, o documento geral serve de contexto.
- Desenvolver scripts PowerShell, documentação e processo de validação para os seis critérios (rede e identidade, IIS, monitoramento, recuperação, auditoria, funcionamento completo).
- Conferir a rede real antes de definir IP; não expor o controlador de domínio; não guardar senhas no repositório.
- Corrigir comandos do PDF que não funcionem, mantendo o objetivo do roteiro.
- Separar recuperação automática comprovada de recuperação manual.
- Nunca inventar prints, saídas, logs, resultados, integrantes ou dados da solução.
- Revisar os textos com quatro skills de escrita (humanizer, humanizer-pt-br, no-ai-slop, avoid-ai-writing), dando prioridade ao humanizer-pt-br.
- Não fazer commit, push ou envio sem autorização.

### Prompt 2: continuação (14/11)

Continuar do ponto em que parou, sem recomeçar; revisar o que já existia; executar tudo o que fosse possível no ambiente; registrar pendências que dependem da VM; criar `docs/AI_HANDOFF.md` como ponto de retomada; não declarar sucesso de teste não executado.

### Pedidos seguintes (14/11 a 16/11)

| Pedido do aluno (resumo) | O que a IA fez |
|---|---|
| Nome do repositório para o projeto Civia | sugeriu `civia-infra` |
| O que falta para terminar, separado entre IA e equipe | listou as etapas e quem faz cada uma |
| "Faça a etapa 0", com autorização para Hyper-V, download da ISO e repositório público | ativou o Hyper-V, baixou a ISO oficial do Evaluation Center, conferiu o tamanho e o SHA256, criou o repositório público no GitHub com o `gh` |
| Instalar o Windows Server na VM ("pode continuar a instalação") | criou a VM com `scripts/host/Criar-VM-HyperV.ps1` e conduziu o instalador pelo teclado e mouse virtuais do Hyper-V; o termo de licença só foi aceito depois de o aluno responder "Sim, aceite e continue" |
| Configurar o servidor | rodou os scripts de `scripts/` dentro da VM pelo PowerShell Direct, etapa por etapa, corrigindo os erros encontrados |
| Autorização para os testes de falha ("Sim, rode os dois modos") | rodou `Teste-Falha.ps1` nos modos Crash e Parada |
| Teste da GPO com usuário comum ("Sim, prepare", "Sim, vou logar") | liberou temporariamente o logon local para o grupo de usuários, digitou o nome `bruno.teste` na tela de logon, abriu o Painel de Controle (Win+R, `control`), capturou a tela e depois desfez a liberação |
| Guardar os dados da equipe ASTRO e da apresentação da Civia | registrou integrantes, RMs e dados da solução na memória do Claude Code e na ficha |
| Cidade, ODS e indicador de impacto | a equipe definiu os três; a IA só passou para a ficha e o README |
| Como gravar o vídeo e qual roteiro seguir | escreveu `docs/roteiro-video.md` e `scripts/Demo-Video.ps1`, testou o script na VM e abriu o Edge e o PowerShell na sessão do aluno |
| Ajustes no script do vídeo (gravar por partes, tirar avisos da tela, abrir o print e o relatório da GPO) | fez cada ajuste e testou no modo de ensaio |
| Link do vídeo publicado | colocou o link no README e no checklist |
| Auditoria final antes da entrega | revisou documentos, scripts e evidências contra os PDFs e escreveu `docs/auditoria-final.md` |

## Quem fez o quê

| Atividade | IA | Aluno / equipe |
|---|---|---|
| Scripts PowerShell, página `app/` e documentos em `docs/` | escreveu, testou e corrigiu | revisou e aprovou cada etapa |
| Preparação do PC host (Hyper-V, ISO, VM) | executou com autorização | instalou a atualização pendente do Windows e reiniciou o PC |
| Senhas (Administrator, DSRM, contas de teste) | nunca viu nem gravou | digitou em janelas do Windows (`Get-Credential` e tela de logon) |
| Configuração da VM e testes | executou pelo PowerShell Direct, a partir de um processo elevado que o aluno aprovou no UAC | autorizou cada etapa; autorizou os testes de falha e a mudança temporária na política dos controladores de domínio |
| Evidências de texto | geradas por `Coletar-Evidencias.ps1` e `Validar-Ambiente.ps1` na VM | - |
| Prints de tela | capturados pela IA: tela da VM pelo Hyper-V, janelas dentro da VM e o navegador do PC host abrindo o site | fez logon com o `bruno.teste` para o teste da GPO |
| Dados da solução (Civia, equipe, RMs, cidade, ODS, indicador) | só transcreveu | definiu todos |
| Vídeo | escreveu o roteiro e o script de demonstração | gravou, narrou, editou e publicou no YouTube |
| Commits e push | fez, depois da autorização do aluno para publicar o repositório | - |
| Envio no Teams | não faz | um integrante envia |

## Revisão de texto com as skills

As regras das quatro skills foram lidas nos arquivos `SKILL.md` e aplicadas pela própria IA ao escrever e revisar os `.md` deste repositório. Não houve ferramenta automática de reescrita. As skills foram instaladas copiando só os `SKILL.md` e os arquivos de referência (licença MIT), sem executar scripts dos repositórios de origem.

| Skill | Como foi usada |
|---|---|
| humanizer-pt-br | referência principal: títulos só com a primeira maiúscula, sem travessão de efeito, sem conectivos de preenchimento ("além disso", "cabe ressaltar"), sem gerúndio de análise rasa, aspas retas |
| humanizer (blader) | busca de padrões estruturais: contraste "não é X, é Y", frases de fechamento, tríades forçadas, afirmações infladas |
| no-ai-slop | corte de metacomentário sobre o próprio documento e de frases que serviriam para qualquer projeto |
| avoid-ai-writing | checagem de afirmações sem fonte e de exagero; a skill avisa que as regras foram calibradas para inglês, então foi usada como apoio |

A revisão não alterou comandos, nomes de serviços, caminhos nem parâmetros.

## O que a IA não fez

- Não digitou, leu nem guardou senhas.
- Não inventou saídas, prints ou resultados de teste. Testes que falharam ou ficaram inconclusivos estão registrados em `docs/testes-realizados.md`.
- Não definiu a solução CitizenTech, a cidade, os ODS, o indicador nem os integrantes.
- Não gravou nem narrou o vídeo.
- Não fez envio no Teams ou no portal.

## Revisão humana

Cada integrante deve ler os scripts e saber explicar cada linha, como pede o documento geral. Anote aqui ajustes feitos pela equipe depois da geração:

| Data | Quem | O que mudou |
|---|---|---|
| | | |
