# Ficha da CitizenTech — Civia

## 1. Identificação do projeto

A **Civia** é uma solução de mobilidade urbana acessível desenvolvida pela equipe ASTRO para a Global Solution da FIAP.

A proposta utiliza óculos inteligentes e inteligência artificial para ajudar pessoas com deficiência visual ou auditiva a se deslocarem pela cidade com mais autonomia.

As informações sobre a solução foram baseadas na apresentação da equipe (`Apresentação_GS_CIVIA.pdf`). A cidade, os Objetivos de Desenvolvimento Sustentável (ODS) e o indicador de impacto foram definidos pela equipe em 16/11/2026.

### Informações gerais

| Campo | Descrição |
|---|---|
| Nome da solução | Civia |
| Equipe | ASTRO |
| Cidade | São Paulo — SP |
| Área de atuação | Rede de metrô, trem e ônibus, com implantação inicial prevista nas estações da Avenida Paulista |
| Público beneficiado | Pessoas com deficiência visual ou auditiva |
| Repositório | [github.com/LuisCrivellaro/civia-infra](https://github.com/LuisCrivellaro/civia-infra) |

## 2. Problema identificado

As informações de mobilidade urbana nem sempre são acessíveis a todos os passageiros.

Avisos em placas, painéis eletrônicos e comunicados sonoros podem não chegar adequadamente às pessoas com deficiência visual ou auditiva.

Isso dificulta a identificação de mudanças de plataforma, alterações de itinerário, desvios e outras situações comuns no transporte público.

## 3. Solução proposta

A Civia propõe integrar óculos inteligentes a um aplicativo de apoio à mobilidade urbana.

Os óculos utilizam câmera e microfone para captar informações do ambiente. Uma inteligência artificial interpreta esses dados, enquanto o aplicativo transmite as informações ao usuário de maneira acessível.

### Principais funcionalidades

- **Interpretação do ambiente:** identificação de informações visuais e sonoras captadas pelos óculos.
- **Comunicação acessível:** transmissão de informações por áudio, legendas e vibração.
- **Rotas acessíveis:** orientação durante os deslocamentos pela cidade.
- **Avisos em tempo real:** comunicação de alterações relevantes no trajeto.
- **Solicitação de ajuda:** recurso para pedir assistência quando necessário.

Cada disciplina envolvida na Global Solution possui entregas específicas. Este repositório contempla somente a infraestrutura relacionada à disciplina de Operating Systems.

## 4. Indicador de impacto

O principal indicador definido pela equipe é o **percentual de trajetos concluídos sem necessidade de solicitar ajuda a outra pessoa**.

A medição será realizada pelo aplicativo, considerando os registros de acionamento da funcionalidade de solicitação de ajuda durante os deslocamentos.

Esse indicador permitirá acompanhar a autonomia proporcionada pela solução aos usuários.

## 5. Objetivos de Desenvolvimento Sustentável (ODS)

A Civia está relacionada a dois Objetivos de Desenvolvimento Sustentável da ONU.

| ODS | Relação com o projeto |
|---|---|
| ODS 10 — Redução das Desigualdades | Ampliar o acesso de pessoas com deficiência visual ou auditiva às informações de mobilidade urbana. |
| ODS 11 — Cidades e Comunidades Sustentáveis | Contribuir com a meta 11.2, que prevê sistemas de transporte acessíveis, com atenção às necessidades das pessoas com deficiência. |

## 6. Integrantes da equipe ASTRO

| Integrante | RM |
|---|---|
| Ana Luiza Santana da Rocha | RM561194 |
| Evandro Yuji Kaibara de Oliveira | RM559274 |
| Guilherme Rodrigues Leite | RM560131 |
| Luís Filipe Crivellaro | RM560877 |
| Pedro Henrique Batista Bergamin | RM559443 |

---

# Infraestrutura — Operating Systems

## 7. Objetivo da infraestrutura

A parte de Operating Systems tem como objetivo configurar um ambiente Windows Server capaz de hospedar a aplicação web de demonstração da Civia.

A infraestrutura contempla os seguintes recursos:

- Hospedagem da aplicação no IIS.
- Gerenciamento de usuários e grupos pelo Active Directory.
- Configuração de rede e resolução de nomes por DNS.
- Controle de acesso e permissões.
- Monitoramento de CPU, memória e disco.
- Registro de logs e auditoria.
- Testes de falha e mecanismos de recuperação automática.

## 8. Ambiente utilizado

| Componente | Configuração |
|---|---|
| Sistema operacional | Windows Server 2022 Standard Evaluation |
| Virtualização | Hyper-V |
| Nome do servidor | `SRV-CITIZENTECH` |
| Domínio | `citizentech.local` |
| NetBIOS | `CITIZENTECH` |
| Endereço IP | `192.168.0.250/24` |
| Gateway | `192.168.0.1` |
| DNS | `127.0.0.1` e `::1` |
| Servidor web | Internet Information Services (IIS) |
| Modelo de hospedagem | Caminho A — Aplicação estática |

Os endereços DNS foram ajustados durante a promoção do servidor a controlador de domínio.

A configuração de rede pode ser consultada no arquivo:

`evidencias/01-rede/03-ipconfig-all.txt`

## 9. Hospedagem da aplicação

A aplicação utilizada nesta entrega consiste em uma página estática de demonstração, contendo informações sobre a Civia.

Os arquivos estão disponíveis no diretório `app/` do repositório.

Essa página foi preparada para demonstrar o funcionamento da hospedagem no IIS e **não representa a versão final da aplicação web desenvolvida pela equipe**.

### Configuração

| Item | Descrição |
|---|---|
| Tipo de aplicação | Site estático |
| Tecnologias de hospedagem | IIS |
| Modelo utilizado | Caminho A do roteiro de Operating Systems |
| Application Pool | Pool configurado sem código gerenciado |
| Diretório no repositório | `app/` |

### Endereços de acesso

**Acesso pelo endereço IP:**

`http://192.168.0.250`

**Acesso pelo domínio:**

`http://srv-citizentech.citizentech.local`

O acesso por nome depende de a máquina cliente utilizar o DNS configurado no servidor.

Caso a aplicação final utilize backend em Node.js, Python ou .NET, será necessário configurar o runtime correspondente e adotar o Caminho B de hospedagem, conforme a seção 4.3 do roteiro da disciplina.

## 10. Credenciais de teste

Foram consideradas as seguintes contas fictícias para os testes de autenticação e permissões:

| Usuário | Finalidade |
|---|---|
| `ana.souza` | Conta de teste do ambiente |
| `bruno.teste` | Conta de teste do ambiente |

Por motivos de segurança, as senhas reais não são disponibilizadas no repositório.

## 11. Referências do projeto

- **Roteiro de Atividade — Operating Systems:** requisitos de infraestrutura, hospedagem, monitoramento, testes e evidências.
- **Apresentação_GS_CIVIA.pdf:** apresentação geral da solução desenvolvida pela equipe ASTRO.
- **Documento geral da Global Solution:** modelo da ficha da CitizenTech.
- **Repositório GitHub:** https://github.com/LuisCrivellaro/civia-infra