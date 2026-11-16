# Ficha da CitizenTech

Modelo sugerido no documento geral da GS (slide "A Ficha da CitizenTech"). Os dados da solução vêm da apresentação da equipe ASTRO (Apresentação_GS_CIVIA.pdf). Cidade, ODS e indicador de impacto foram definidos pela equipe em 16/11/2026.

| Campo | Valor |
|---|---|
| Nome da CitizenTech | Civia |
| Cidade e bairro | São Paulo (SP), em toda a rede de metrô, trem e ônibus, começando pelas estações da Avenida Paulista, que a equipe usa no caminho até a FIAP |
| Cidadão beneficiado | pessoas com deficiência visual ou auditiva que se deslocam pela cidade |
| Problema, em uma frase | avisos de mobilidade urbana (placas, painéis, comunicados sonoros) não chegam a quem não vê ou não ouve, e uma mudança de plataforma ou de caminho vira uma dificuldade |
| Como funciona | óculos inteligentes com câmera e microfone captam o ambiente, uma IA interpreta e o aplicativo comunica por áudio, legendas e vibração; o app oferece rotas acessíveis, avisos em tempo real e pedido de ajuda |
| O que cada parte faz | a preencher (a parte de Operating Systems está abaixo) |
| Link do repositório | https://github.com/LuisCrivellaro/civia-infra |
| Indicador de impacto | percentual de trajetos que o usuário conclui sem precisar pedir ajuda a outra pessoa (medido pelo aplicativo, que registra quando a função de pedir ajuda é acionada) |
| ODS conectados | ODS 10 (Redução das desigualdades): pessoas com deficiência visual ou auditiva passam a receber as mesmas informações de mobilidade que os demais passageiros. ODS 11 (Cidades e comunidades sustentáveis): contribui com a meta 11.2, transporte acessível para todos, com atenção às pessoas com deficiência |

## Integrantes (equipe ASTRO)

| Nome | RM |
|---|---|
| Ana Luiza Santana da Rocha | RM561194 |
| Evandro Yuji Kaibara de Oliveira | RM559274 |
| Guilherme Rodrigues Leite | RM560131 |
| Luís Filipe Crivellaro | RM560877 |
| Pedro Henrique Batista Bergamin | RM559443 |

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
