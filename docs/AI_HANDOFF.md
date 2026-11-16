# Ponto de retomada

Atualizado em 14/11/2026. Prazo da entrega: 19/11/2026, 23h55 (Teams).

## Estado

- Repositório local em `C:\Projetos\OS GS`, publicado em https://github.com/LuisCrivellaro/civia-infra (público).
- VM `SRV-CITIZENTECH` no Hyper-V do PC (switch externo `Civia-Externo`, IP 192.168.0.250), Windows Server 2022 Standard Evaluation em inglês, domínio `citizentech.local`.
- Todas as etapas executadas na VM em 16/11/2026; `Validar-Ambiente.ps1` = 49/49. Recuperação automática comprovada (Crash e Parada).
- Evidências de texto em `evidencias/`; faltam prints manuais de telas gráficas, a ficha da equipe e o vídeo.
- Registro completo das execuções: `docs/testes-realizados.md`.
- Comandos na VM foram executados por PowerShell Direct a partir do host (`Invoke-Command -VMName SRV-CITIZENTECH`). Para repetir à mão, use a janela da VM ou o mesmo método com `Get-Credential`.

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

## Ponto exato de parada (16/11/2026, ~01:45)

- Passo em andamento: demonstrar a GPO com o usuário `bruno.teste`.
- MUDANÇA TEMPORÁRIA ATIVA na VM: a Default Domain Controllers Policy foi editada para dar "Allow log on locally" ao grupo `GG_CitizenTech_Usuarios` (SID `...-1104`). Versão da GPO passou para 5. Backup do arquivo original: `C:\Scripts\logs\GptTmpl-DDCP-original.inf` (na VM).
- A sessão do Administrator foi encerrada; a VM está na tela de login.
- Próximos passos ao retomar:
  1. Na janela da VM: Other user > `CITIZENTECHruno.teste` > senha das contas de teste.
  2. Abrir o Painel de Controle na sessão do bruno e capturar a mensagem de restrição (`evidencias/04-ntfs-gpo/07-gpo-painel-bloqueado.png`). Rodar `gpresult /r` na sessão dele.
  3. Desfazer a mudança: copiar o backup de volta para `C:\Windows\SYSVOL\domain\Policies\{6AC1786C-016F-11D2-945F-00C04fB984F9}\MACHINE\Microsoft\Windows NT\SecEdit\GptTmpl.inf`, subir a versão da GPO (AD `versionNumber` e `GPT.INI`) para 6 e rodar `gpupdate /target:computer /force`. Conferir com `secedit /export /areas USER_RIGHTS`.
  4. Registrar em `docs/testes-realizados.md` e no checklist.
- Controle da VM: o host usa um processo auxiliar elevado (PowerShell Direct) que encerra sozinho em algumas horas. Para retomar, ele precisa ser aberto de novo (UAC + senha do Administrator digitada pelo aluno).
- Depois da GPO: ficha da Civia (dados da equipe), vídeo e envio no Teams até 19/11 às 23h55.

## Pendências (em ordem)

1. Prints de telas gráficas: feitos em 16/11 (Monitor de Desempenho, Agendador, Recovery, Event Viewer, logs do IIS). Falta só a aba Security da pasta do site (opcional).
2. GPO na prática: logon como `bruno.teste` (alternativa de laboratório no roteiro de configuração, passo 7) e print do Painel de Controle bloqueado.
3. RDP de outra máquina (ou do host: `mstsc /v:192.168.0.250`) com `hostname` na tela.
4. Ficha da Civia: problema, cidadão, cidade, ODS, integrantes e RM.
5. Vídeo de até 7 min (`docs/roteiro-video.md`), link no README.
6. Commit e push finais; um integrante envia o link no Teams até 19/11 às 23h55.

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
