# Evidências

Só entram aqui prints e saídas reais da VM. Nada de imagens montadas ou saídas editadas.

- Arquivos `.txt` são gerados por `scripts/Coletar-Evidencias.ps1` e têm no cabeçalho servidor, data e comando.
- Prints de tela têm nome `<nn>-<o-que-mostra>.png`, por exemplo `04-ntfs-gpo/07-gpo-painel-bloqueado-bruno.png`.
- Se refizer uma evidência, substitua o arquivo antigo para não ficar resultado desatualizado.

Gerado em 16/11/2026 na VM `SRV-CITIZENTECH`:
- saídas de comando de todas as etapas (`Coletar-Evidencias.ps1`) e o resultado do `Validar-Ambiente.ps1` (49/49);
- os transcripts dos três testes de falha e os logs dos scripts (`07-logs/logs-scripts/`), copiados de `C:\Scripts\logs`;
- o log do IIS do dia (`07-logs/u_ex261116.log`);
- `01-rede/00-winver.png`: captura da tela da VM feita pelo Hyper-V;
- `03-iis/06-navegador-site-pelo-ip.jpg`: o site aberto no navegador do PC host pelo IP do servidor;
- `04-ntfs-gpo/07-gpo-painel-bloqueado-bruno.png` e `08-gpresult-bruno.txt`: teste da GPO com o `bruno.teste`;
- `04-ntfs-gpo/09-relatorio-gpo.html`: relatório da GPO gerado com `Get-GPOReport` (seção 5.1 do roteiro);
- `05-monitoramento/09-perfmon-grafico-3-contadores.png` e `10-agendador-historico.png`;
- `06-teste-falha/06-services-recovery-w3svc.png`: aba Recovery do W3SVC no `services.msc`;
- `07-logs/07-event-viewer-security.png` e `08-pasta-logs-iis.png`;
- `03-iis/07-aba-seguranca-site.png`, `04-ntfs-gpo/10-rdp-conexao-hostname.png` e `11-share-acessado-do-host.png`, tirados à noite pela Área de Trabalho Remota e pelo Explorador do PC host.

Única alteração nas saídas: os endereços IPv6 públicos da conexão de internet (prefixo da operadora) foram trocados por `[IPv6-publico-removido]`, porque o repositório é público.

Todos os prints pedidos no roteiro estão nas pastas.

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

O transcript completo de cada teste de falha fica em `C:\Scripts\logs\teste-falha-<modo>-<data>.log` na VM. Os três testes de 16/11 de madrugada já foram copiados para `06-teste-falha/`; o teste rodado durante a gravação do vídeo ficou só na VM.
