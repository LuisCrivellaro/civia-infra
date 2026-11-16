# Ponto de retomada

Atualizado em 14/11/2026. Prazo da entrega: 19/11/2026, 23h55 (Teams).

## Estado

- Repositório local em `C:\Projetos\OS GS`. Não é repositório Git ainda; nada foi commitado nem publicado.
- Scripts, página de demonstração e documentação prontos.
- Nada foi executado em Windows Server. Todos os critérios estão como Preparado ou Pendente.
- Testes feitos fora da VM e seus resultados: `docs/testes-realizados.md`.

## Arquivos

| Arquivo | Função |
|---|---|
| `README.md` | visão geral, ficha, configurações, rastreabilidade, limitações |
| `prompts.md` | registro do uso de IA |
| `.gitignore`, `.gitattributes` | PDFs fora do Git; CRLF nos scripts |
| `app/index.html`, `style.css`, `app.js`, `health.txt` | página estática de demonstração (Caminho A) |
| `scripts/config/CitizenTech.config.psd1` | todos os valores do ambiente |
| `scripts/lib/CitizenTech.Common.psm1` | log, checagens, SIDs, tradução de contadores, tarefas |
| `scripts/Configurar-Rede.ps1` | diagnóstico, renomear, IP fixo |
| `scripts/Configurar-AD.ps1` | AD DS, promoção, OU, grupos, usuários |
| `scripts/Configurar-IIS.ps1` | IIS, pool, site, NTFS, firewall |
| `scripts/Configurar-Infraestrutura.ps1` | File Server, GPO, RDP, auditoria, DFS |
| `scripts/Configurar-Monitoramento.ps1` | Data Collector Sets, fonte de eventos, tarefas |
| `scripts/Monitor-Recursos.ps1` | alerta por limiar (testado localmente) |
| `scripts/Configurar-Recuperacao.ps1` | sc failure, pool, tarefa de recuperação |
| `scripts/Recupera-Site.ps1` | vigilância e recuperação |
| `scripts/Teste-Falha.ps1` | falha controlada (modos Crash, Parada, Pool) |
| `scripts/Validar-Ambiente.ps1` | 49 verificações, só leitura |
| `scripts/Coletar-Evidencias.ps1` | salva saídas reais em `evidencias/` |
| `docs/*.md` | roteiro de configuração, arquitetura, análise de requisitos, ficha, checklist, roteiro do vídeo, testes |
| `evidencias/` | pastas vazias com `.gitkeep` e `README.md` explicando o que vai em cada uma |

Fora do repositório: as quatro skills de escrita foram instaladas em `%USERPROFILE%\.claude\skills\` (`humanizer`, `humanizer-pt-br`, `no-ai-slop`, `avoid-ai-writing`), só com `SKILL.md`, licença e referências.

## Decisões já tomadas

- Caminho A (estático), porque a aplicação da equipe não foi encontrada.
- Recuperação provada pelo modo `Crash` (SCM, evento 7031) e pelo modo `Parada` (tarefa agendada). Fallback manual nunca conta como automático.
- Nomes localizados resolvidos por SID/GUID e tradução de contadores pelo índice do Perflib.
- RDP sem a função RDS; NLA e firewall restrito à sub-rede local.
- DFS opcional, só Namespace.

## Pendências (em ordem)

1. Criar a VM e instalar o Windows Server 2022 (humano).
2. Seguir `docs/roteiro-configuracao.md` passos 1 a 12 (humano, na VM).
3. Rodar `Validar-Ambiente.ps1` até ficar tudo `PASSOU` e `Coletar-Evidencias.ps1`.
4. Fazer os prints manuais listados em `evidencias/README.md`.
5. Copiar `evidencias/` da VM para o repositório.
6. Atualizar status em `README.md` e `docs/checklist-entrega.md`; registrar em `docs/testes-realizados.md` (seção "Na VM").
7. Preencher ficha da CitizenTech, integrantes, IP real.
8. Se a aplicação real da equipe existir, trocar `app/` e rodar `Configurar-IIS.ps1` de novo.
9. Gravar o vídeo (`docs/roteiro-video.md`), subir e colocar o link no README.
10. Criar o repositório no GitHub, commit e push (com autorização do aluno), enviar o link no Teams por um integrante, conferir o envio.

## Comandos para continuar

Na máquina de desenvolvimento, conferir sintaxe depois de qualquer mudança:

```powershell
Get-ChildItem .\scripts -Recurse -Include *.ps1,*.psm1 | ForEach-Object {
  $t=$null; $e=$null
  [void][System.Management.Automation.Language.Parser]::ParseFile($_.FullName,[ref]$t,[ref]$e)
  "{0} erros={1}" -f $_.Name, $e.Count }
```

Na VM: ver `docs/roteiro-configuracao.md`.

## Riscos conhecidos

- `Configurar-Monitoramento.ps1` usa a API COM do PLA; não foi testado (precisa de administrador). Se a atribuição de `PerformanceCounters` ou `AlertThresholds` falhar, a alternativa é `logman create counter CitizenTech_Monitor -c <contadores> -si 15 -f bin -o C:\PerfLogs\CitizenTech\Recursos` e `logman create alert`.
- Em controlador de domínio a política de auditoria pode ser sobrescrita pela Default Domain Controllers Policy; conferir depois de `gpupdate /force`.
- O modo `Crash` encerra o `svchost` do grupo `iissvcs`. O script aborta se houver serviço fora de W3SVC/WAS/IISADMIN/W3LOGSVC no mesmo processo.
