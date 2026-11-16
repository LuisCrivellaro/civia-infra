# Evidências

Só entram aqui prints e saídas reais da VM. Nada de imagens montadas ou saídas editadas.

- Arquivos `.txt` são gerados por `scripts/Coletar-Evidencias.ps1` e têm no cabeçalho servidor, data e comando.
- Prints de tela são feitos à mão. Nome: `<nn>-<o-que-mostra>.png`, por exemplo `03-iis/06-navegador-site.png`.
- Se refizer uma evidência, substitua o arquivo antigo para não ficar resultado desatualizado.

Gerado em 16/11/2026 na VM `SRV-CITIZENTECH`:
- saídas de comando de todas as etapas (`Coletar-Evidencias.ps1`) e o resultado do `Validar-Ambiente.ps1` (49/49);
- os transcripts dos três testes de falha e os logs dos scripts (`07-logs/logs-scripts/`), copiados de `C:\Scripts\logs`;
- o log do IIS do dia (`07-logs/u_ex261116.log`);
- `01-rede/00-winver.png`: captura da tela da VM feita pelo Hyper-V;
- `03-iis/06-navegador-site-pelo-ip.jpg`: o site aberto no navegador do PC host pelo IP do servidor.

Única alteração nas saídas: os endereços IPv6 públicos da conexão de internet (prefixo da operadora) foram trocados por `[IPv6-publico-removido]`, porque o repositório é público.

Ainda faltam os prints manuais de telas gráficas marcados como pendentes em `docs/checklist-entrega.md`.

## O que vai em cada pasta

| Pasta | Gerado pelo script | Prints manuais |
|---|---|---|
| `00-validacao` | resultado do `Validar-Ambiente.ps1`, `00-ficha-infraestrutura.txt` | bloco de validação final do roteiro 8.1 em um único print |
| `01-rede` | hostname, versão, `ipconfig /all`, `Get-NetIPConfiguration` | `00-winver.png`, `ipconfig /all` na tela |
| `02-ad-dns` | `Get-ADDomain`, `nslookup`, `Get-DnsServerZone`, usuários, grupos | os mesmos comandos na tela |
| `03-iis` | recursos Web-*, `Get-Website`, pool, `Invoke-WebRequest`, `Get-Acl` | navegador com a página pelo IP, aba Segurança da pasta |
| `04-ntfs-gpo` | share, NTFS do share, `Get-GPO -All`, link da GPO, RDP, DFS | usuário sem Painel de Controle, acesso ao `\\SRV-CITIZENTECH\CitizenTech`, conexão RDP com `hostname` |
| `05-monitoramento` | `logman query`, arquivos `.blg`, `Get-Counter`, execução do script, tarefas, `monitor.log`, alertas | Monitor de Desempenho com os conjuntos ativos e o gráfico dos 3 contadores, Agendador com histórico |
| `06-teste-falha` | `sc.exe qfailure`, pool, resumo do teste, `recuperacao.log`, eventos 7031 | as etapas do `Teste-Falha.ps1` no terminal, aba Recuperação no `services.msc`, navegador fora do ar e de volta |
| `07-logs` | `auditpol`, eventos Security, 4624/4625, 4663, SACL, logs do IIS | Visualizador de Eventos no log Segurança, pasta de logs do IIS aberta |

O transcript completo de cada teste de falha fica em `C:\Scripts\logs\teste-falha-<modo>-<data>.log` na VM. Copie para `06-teste-falha/`.
