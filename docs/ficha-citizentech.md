# Ficha da CitizenTech

Modelo sugerido no documento geral da GS (slide "A Ficha da CitizenTech"). Os dados da solução vêm da apresentação da equipe ASTRO (Apresentação_GS_CIVIA.pdf). Cidade/bairro, indicador de impacto e ODS não constam da apresentação e precisam ser preenchidos pela equipe.

| Campo | Valor |
|---|---|
| Nome da CitizenTech | Civia |
| Cidade e bairro | a preencher |
| Cidadão beneficiado | pessoas com deficiência visual ou auditiva que se deslocam pela cidade |
| Problema, em uma frase | avisos de mobilidade urbana (placas, painéis, comunicados sonoros) não chegam a quem não vê ou não ouve, e uma mudança de plataforma ou de caminho vira uma dificuldade |
| Como funciona | óculos inteligentes com câmera e microfone captam o ambiente, uma IA interpreta e o aplicativo comunica por áudio, legendas e vibração; o app oferece rotas acessíveis, avisos em tempo real e pedido de ajuda |
| O que cada parte faz | a preencher (a parte de Operating Systems está abaixo) |
| Link do repositório | https://github.com/LuisCrivellaro/civia-infra |
| Indicador de impacto | a preencher |
| ODS conectados | a preencher, com uma frase sobre como a solução contribui para cada um |

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
