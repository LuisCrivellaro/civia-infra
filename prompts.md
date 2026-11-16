# Registro de uso de IA

O documento geral da GS permite IA "como copiloto" e pede o registro dos prompts neste arquivo. Abaixo está o que foi pedido, a ferramenta usada e o que saiu de cada pedido.

Ferramenta: Claude Code (modelo Claude Opus 5.5), no aplicativo desktop, em 14/11/2026.

## Prompt 1: missão da entrega de Operating Systems

Resumo do pedido (o texto integral foi colado na sessão; cole aqui se o professor pedir o texto completo):

- Atuar como engenheiro de infraestrutura Windows Server e como revisor de português.
- Ler os dois PDFs; o roteiro de Operating Systems é a fonte principal, o documento geral serve de contexto.
- Desenvolver scripts PowerShell, documentação e processo de validação para os seis critérios (rede e identidade, IIS, monitoramento, recuperação, auditoria, funcionamento completo).
- Conferir a rede real antes de definir IP; não expor o controlador de domínio; não guardar senhas no repositório.
- Corrigir comandos do PDF que não funcionem, mantendo o objetivo do roteiro.
- Separar recuperação automática comprovada de recuperação manual.
- Nunca inventar prints, saídas, logs, resultados, integrantes ou dados da solução.
- Revisar os textos com quatro skills de escrita (humanizer, humanizer-pt-br, no-ai-slop, avoid-ai-writing), dando prioridade ao humanizer-pt-br.
- Não fazer commit, push ou envio sem autorização.

## Prompt 2: continuação

Resumo: continuar do ponto em que parou, sem recomeçar; revisar o que já existia; executar tudo o que fosse possível no ambiente; registrar pendências que dependem da VM; criar `docs/AI_HANDOFF.md` como ponto de retomada; não declarar sucesso de teste não executado.

## O que a IA fez

- Leu o roteiro (11 páginas) e o documento geral da GS.
- Instalou as quatro skills de escrita copiando só os arquivos `SKILL.md` e de referência (licença MIT), sem executar scripts dos repositórios.
- Escreveu os scripts em `scripts/`, a página de demonstração em `app/` e os documentos em `docs/`.
- Testou no Windows 11 da máquina de desenvolvimento o que não dependia de servidor (sintaxe, leitura de contadores, script de alerta, travas de segurança, validador). Os resultados, inclusive os que falharam, estão em `docs/testes-realizados.md`.
- Encontrou e documentou diferenças entre os comandos do PDF e o comportamento real do Windows (`docs/analise-requisitos.md`).

## Revisão de texto com as skills

As regras das quatro skills foram lidas nos `SKILL.md` e aplicadas pela própria IA ao escrever e revisar os `.md` deste repositório. Não houve ferramenta automática de reescrita.

| Skill | Como foi usada |
|---|---|
| humanizer-pt-br | referência principal: títulos só com a primeira maiúscula, sem travessão de efeito, sem conectivos de preenchimento ("além disso", "cabe ressaltar"), sem gerúndio de análise rasa, aspas retas |
| humanizer (blader) | busca de padrões estruturais: contraste "não é X, é Y", frases de fechamento, tríades forçadas, afirmações infladas |
| no-ai-slop | corte de metacomentário sobre o próprio documento e de frases que serviriam para qualquer projeto |
| avoid-ai-writing | checagem de afirmações sem fonte e de exagero; a skill avisa que as regras foram calibradas para inglês, então foi usada como apoio |

Resultado da varredura final: nenhum travessão, aspas curvas, negrito decorativo ou termo da lista de vocabulário de IA nos documentos. Três frases de `docs/arquitetura.md` foram reescritas (um metacomentário e duas afirmações mais fortes do que o texto sustentava). Comandos, nomes de serviços, caminhos e parâmetros não foram alterados pela revisão.

## O que a IA não fez

- Não acessou nenhuma VM nem Windows Server. Nenhuma configuração do servidor foi executada.
- Não gerou evidências da infraestrutura.
- Não definiu a solução CitizenTech da equipe nem os integrantes.
- Não gravou o vídeo e não fez envio no Teams ou no portal.

## Revisão humana

Cada integrante deve ler os scripts e saber explicar cada linha, como pede o documento geral. Anote aqui ajustes feitos pela equipe depois da geração:

| Data | Quem | O que mudou |
|---|---|---|
| | | |
