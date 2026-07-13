# 📨 Arquitetura Orientada a Eventos

Este documento descreve a arquitetura de comunicação assíncrona da **FCG Platform**, detalhando os eventos publicados e consumidos pelos microsserviços através do broker de mensagens.

## 📑 Sumário

- [📦 Contratos de Eventos](#-contratos-de-eventos)
- [👤 Fluxo de Cadastro de Usuário](#-fluxo-de-cadastro-de-usuário)
- [🎮 Fluxo de Compra de Jogo](#-fluxo-de-compra-de-jogo)

# 📦 Contratos de Eventos

Para padronizar a comunicação entre os microsserviços, a plataforma utiliza uma biblioteca compartilhada contendo os contratos de integração e eventos de mensageria.

Repositório:

👉 [fcg-event-contracts](https://github.com/FIAP-ARQUITETURA-DOTNET-GRUPO-89/fcg-event-contracts)

# 👤 Fluxo de Cadastro de Usuário

Fluxo responsável pela criação de usuários e envio de notificações de boas-vindas.

| Passo | Quem Executa           | Tipo   | O que faz?                                                  | Evento Consumido        | Evento Gerado      | Quem vai Consumir?     | Ação Final / Impacto                                      |
| ----- | ---------------------- | ------ | ----------------------------------------------------------- | ----------------------- | ------------------ | ---------------------- | --------------------------------------------------------- |
| **1** | `users-api`            | API    | Cadastra o usuário no banco através de uma requisição HTTP. | _Nenhum (Gatilho HTTP)_ | `UserCreatedEvent` | `notifications-worker` | Persiste o usuário e publica o evento para o ecossistema. |
| **2** | `notifications-worker` | Worker | Consome o evento de criação de usuário.                     | `UserCreatedEvent`      | _Nenhum_           | _Nenhum_               | Realiza o envio simulado do e-mail de boas-vindas.        |

# 🎮 Fluxo de Compra de Jogo

Fluxo responsável pelo processamento completo de uma compra, envolvendo catálogo, pagamentos e notificações.

| Passo | Quem Executa           | Tipo   | O que faz?                                                               | Evento Consumido        | Evento Gerado           | Quem vai Consumir?                       | Ação Final / Impacto                                                                         |
| ----- | ---------------------- | ------ | ------------------------------------------------------------------------ | ----------------------- | ----------------------- | ---------------------------------------- | -------------------------------------------------------------------------------------------- |
| **1** | `catalog-api`          | API    | Recebe a solicitação de compra do jogo através de uma requisição HTTP.   | _Nenhum (Gatilho HTTP)_ | `OrderPlacedEvent`      | `payments-worker`                        | Publica o pedido de compra para processamento financeiro.                                    |
| **2** | `payments-worker`      | Worker | Processa e simula a cobrança do pedido recebido.                         | `OrderPlacedEvent`      | `PaymentProcessedEvent` | `catalog-worker`, `notifications-worker` | Publica o resultado do pagamento (`Approved` ou `Rejected`).                                 |
| **3** | `catalog-worker`       | Worker | Consome o resultado do pagamento para atualizar a biblioteca do usuário. | `PaymentProcessedEvent` | _Nenhum_                | _Nenhum_                                 | Caso o pagamento seja aprovado, adiciona o jogo à biblioteca do usuário.                     |
| **4** | `notifications-worker` | Worker | Consome o resultado do pagamento para notificar o usuário.               | `PaymentProcessedEvent` | _Nenhum_                | _Nenhum_                                 | Caso o pagamento seja aprovado, realiza o envio simulado do e-mail de confirmação da compra. |
