# Testes realizados

Registro do que foi testado, onde e com qual resultado. Testes feitos fora da VM não valem como evidência da infraestrutura; servem para mostrar que os scripts foram verificados antes de ir para o servidor.

## 14/11/2026, máquina de desenvolvimento

Ambiente: Windows 11 Pro em português (pt-BR), Windows PowerShell 5.1.26100, sessão sem privilégio de administrador. Não é Windows Server, não tem AD, IIS nem DNS.

| Teste | Resultado | Observação |
|---|---|---|
| Parser do PowerShell 5.1 em todos os `.ps1`, `.psm1` e `.psd1` | Passou | 0 erros de sintaxe nos 13 arquivos |
| Arquivos só com caracteres ASCII | Passou | evita problema de codificação no 5.1, que lê `.ps1` sem BOM como ANSI |
| `Get-Counter "\Processor(_Total)\% Processor Time"` (comando do roteiro) | Falhou | "O objeto especificado não foi encontrado no computador". Confirma que o nome em inglês não funciona em Windows pt-BR |
| Tradução dos contadores (`Get-CTCounterPath`) | Passou, após correção | primeira versão lia `HKLM:\...\Perflib\009`, que não existe como chave comum, e caía no fallback. A versão final lê pelo `Registry::PerformanceData` e devolveu `\Processador(_Total)\% tempo de processador`, `\Memória\MBytes disponíveis`, `\LogicalDisk(C:)\% de espaço livre` e `\LogicalDisk(C:)\Megabytes livres`; os quatro leram valores com `Get-Counter` |
| `Monitor-Recursos.ps1` normal (logs no scratchpad, sem log de eventos) | Passou | linha verde com CPU, RAM e disco; `monitor.log` gravado com `fontes CPU=Get-Counter RAM=Get-Counter` |
| `Monitor-Recursos.ps1 -ModoTeste` | Passou | alerta marcado `[TESTE]` em `alertas-teste.log`, sem tocar no `alertas.log` |
| `Monitor-Recursos.ps1 -LimiteCPU 0` | Passou | alerta real de CPU gravado em `alertas.log` (feito com a versão anterior, que usava o fallback CIM) |
| `Teste-Falha.ps1 -Confirmar` fora do Windows Server | Passou | abortou com "este teste so roda no Windows Server da VM", código 3, sem tocar em nada |
| `Configurar-AD.ps1` e `Configurar-IIS.ps1` sem administrador | Passou | abortaram antes de qualquer alteração |
| `Configurar-IIS.ps1` (primeira execução) | Falhou, corrigido | `$PSScriptRoot` vem vazio no valor padrão de parâmetro no PowerShell 5.1. Corrigido nos três scripts que usavam isso |
| `Configurar-Rede.ps1` (modo diagnóstico) | Passou | só leitura; listou adaptadores, IPs, gateway, DNS e DHCP |
| `Validar-Ambiente.ps1` fora do servidor | Passou | rodou os 49 itens sem interromper; 3 PASSOU, 14 FALHOU, 32 ERRO (esperado sem AD/IIS/admin); TXT e CSV gravados |
| Página `app/` servida por HTTP local (`python -m http.server`) | Passou | `index.html` e `health.txt` com HTTP 200; o status da página mostrou "HTTP 200 (no ar)" |

Não testado fora da VM, por depender de Windows Server, AD, IIS ou administrador: promoção do domínio, criação de OU/grupos/usuários, IIS, NTFS, compartilhamento, GPO, RDP, auditoria, Data Collector Sets, tarefas agendadas, `sc.exe failure`, `Teste-Falha.ps1` e `Coletar-Evidencias.ps1`.

## 15/11/2026, preparação do host

| Teste / ação | Resultado | Observação |
|---|---|---|
| Rede do host | Lido | Ethernet `192.168.0.17/24`, gateway `192.168.0.1` |
| IPs candidatos ao servidor (`.250`, `.240`, `.230`) | Livres | não responderam ao ping e não estavam na tabela ARP; escolhido `192.168.0.250` |
| Virtualização da CPU | Ativa | `HypervisorPresent = True` (segurança baseada em virtualização em execução) |
| Ativação do Hyper-V (`Enable-WindowsOptionalFeature Microsoft-Hyper-V-All`) | Passou | `State: Enabled`, `RestartNeeded: True` |
| Parser no `scripts/host/Criar-VM-HyperV.ps1` | Passou | 0 erros; script ainda não executado (precisa do reinício) |
| Download da ISO `SERVER_EVAL_x64FRE_en-us.iso` | ver `AI_HANDOFF.md` | link oficial do Evaluation Center, 5.044.094.976 bytes |

## Na VM

| Data | Teste | Resultado | Evidência |
|---|---|---|---|
| | | | |
