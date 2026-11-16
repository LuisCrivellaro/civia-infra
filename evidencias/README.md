# Evidências

Só entram aqui prints e saídas reais da VM. Nada de imagens montadas ou saídas editadas.

- Arquivos `.txt` são gerados por `scripts/Coletar-Evidencias.ps1` e têm no cabeçalho servidor, data e comando.
- Prints de tela são feitos à mão. Nome: `<nn>-<o-que-mostra>.png`, por exemplo `03-iis/06-navegador-site.png`.
- Se refizer uma evidência, substitua o arquivo antigo para não ficar resultado desatualizado.

Até 14/11/2026 nenhuma evidência da VM foi gerada; as pastas estão vazias.

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
