# Ficha da CitizenTech

Modelo sugerido no documento geral da GS (slide "A Ficha da CitizenTech"). Os campos da solução são da equipe e ainda não foram informados; preencha antes da entrega e copie o resumo para o README.

| Campo | Valor |
|---|---|
| Nome da CitizenTech | Civia |
| Cidade e bairro | a preencher |
| Cidadão beneficiado | a preencher |
| Problema, em uma frase | a preencher |
| Como funciona | a preencher |
| O que cada parte faz | a preencher (a parte de Operating Systems está abaixo) |
| Link do repositório | https://github.com/LuisCrivellaro/civia-infra |
| Indicador de impacto | a preencher |
| ODS conectados | a preencher, com uma frase sobre como a solução contribui para cada um |

## Integrantes

| Nome | RM |
|---|---|
| a preencher | a preencher |

## Parte de Operating Systems

| Campo | Valor |
|---|---|
| Função na solução | servidor que hospeda a aplicação web da CitizenTech, com contas, permissões, monitoramento e recuperação de falhas |
| Forma de hospedagem | Caminho A: site estático no IIS, pool sem código gerenciado |
| Aplicação hospedada | página de demonstração em `app/` até a equipe entregar a aplicação web |
| Servidor | `SRV-CITIZENTECH` |
| Domínio | `citizentech.local` |
| IP | a confirmar depois da configuração na VM |
| URL de acesso | `http://<IP>` ou `http://srv-citizentech.citizentech.local` (de máquinas que usam o servidor como DNS) |
| Credenciais de teste | `ana.souza` e `bruno.teste`, contas fictícias. Senhas fora do repositório |

Se a aplicação final tiver backend (Node.js, Python ou .NET), registre aqui o runtime e mude a hospedagem para o Caminho B do roteiro (seção 4.3).
