# Docker Compose - FCG Platform

Este documento descreve como executar toda a plataforma utilizando **Docker Compose** e imagens publicadas no **Docker Hub**.

---

# Arquitetura

A plataforma é composta pelos seguintes serviços:

| Serviço | Tipo | Porta |
|---------|------|------:|
| Fcg Users API | API | 7071 |
| Fcg Catalog API | API | 7072 |
| Fcg Payments API | API | 7074 |
| Fcg Catalog Worker | Worker | - |
| Fcg Notifications Worker | Worker | - |
| Fcg Payments Worker | Worker | - |
| PostgreSQL | Database | 5432 |
| RabbitMQ | Broker | 5672 |
| RabbitMQ Management | Dashboard | 15672 |

> **Observação:** Atualmente apenas o microserviço **Users** não possui Worker.

---

# Pré-requisitos

- Docker Desktop
- Docker Compose

Verifique a instalação:

```bash
docker --version
docker compose version
```

---

# Executando a plataforma

Na raiz do projeto execute:

```bash
docker compose up -d
```

Acompanhar os logs:

```bash
docker compose logs -f
```

---

# Parando a plataforma

```bash
docker compose down
```

Remover também os volumes:

```bash
docker compose down -v
```

---

# Reconstruindo as imagens (ambiente local)

Caso esteja utilizando Dockerfiles locais:

```bash
docker compose up --build -d
```

ou

```bash
docker compose build
docker compose up -d
```

---

# Serviços

## PostgreSQL

| Configuração | Valor |
|--------------|-------|
| Host | localhost |
| Porta | 5432 |
| Database | fcg |
| Usuário | postgres |
| Senha | postgres |

---

## RabbitMQ

| Configuração | Valor |
|--------------|-------|
| Broker | amqp://guest:guest@localhost:5672 |
| Dashboard | http://localhost:15672 |
| Usuário | guest |
| Senha | guest |

---

# APIs

| Serviço | URL |
|---------|-----|
| Users API | http://localhost:7071 |
| Catalog API | http://localhost:7072 |
| Notifications API | http://localhost:7073 |
| Payments API | http://localhost:7074 |

---

# Workers

Os Workers executam tarefas assíncronas consumindo eventos do RabbitMQ.

| Worker | Responsabilidade |
|---------|------------------|
| Catalog Worker | Atualização do catálogo após processamento de pagamentos. |
| Notifications Worker | Envio de notificações e comunicação com os usuários. |
| Payments Worker | Processamento de pagamentos e publicação de eventos. |

---

# Estrutura

```text
fcg-platform
│
├── docker-compose.yml
│
└── microservices
    ├── fcg-users
    ├── fcg-catalog
    ├── fcg-payments
    └── fcg-notifications
```

---

# Variáveis de Ambiente

Todas as configurações são injetadas pelo Docker Compose.

Exemplo:

```yaml
environment:
  ASPNETCORE_ENVIRONMENT: Docker
  ASPNETCORE_URLS: http://+:7071

  ConnectionStrings__Default: Host=postgres;Port=5432;Database=fcg;Username=postgres;Password=postgres

  ConnectionStrings__Rabbitmq: amqp://guest:guest@rabbitmq:5672
```

---

# Docker Hub

As imagens oficiais da plataforma são publicadas no Docker Hub.

| Serviço | Imagem |
|---------|---------|
| Users API | `jondamiao/fcg-users-api` |
| Catalog API | `jondamiao/fcg-catalog-api` |
| Catalog Worker | `jondamiao/fcg-catalog-worker` |
| Payments API | `jondamiao/fcg-payments-api` |
| Payments Worker | `jondamiao/fcg-payments-worker` |
| Notifications Worker | `jondamiao/fcg-notifications-worker` |

---

# Atualizando as imagens

Após publicar uma nova versão:

```bash
docker compose pull
docker compose up -d
```

Para utilizar uma versão específica:

```yaml
image: jondamiao/fcg-users-api:1.0.0
```

---

# Comandos úteis

Listar containers:

```bash
docker ps
```

Visualizar logs:

```bash
docker compose logs -f
```

Visualizar logs de um serviço:

```bash
docker compose logs -f payments-worker
```

Entrar em um container:

```bash
docker exec -it fcg-users-api sh
```

Reiniciar um serviço:

```bash
docker compose restart payments-worker
```

Parar toda a plataforma:

```bash
docker compose down
```

Atualizar imagens:

```bash
docker compose pull
```

Subir novamente:

```bash
docker compose up -d
```

---

# Fluxo de Deploy

```text
             GitHub
                │
                ▼
      GitHub Actions CI/CD
                │
                ▼
     Build API + Worker Images
                │
                ▼
           Docker Hub
                │
                ▼
      docker compose pull
                │
                ▼
       docker compose up -d
```

---

# Observações

- Todos os serviços executam na rede Docker `fcg-network`.
- PostgreSQL e RabbitMQ são compartilhados entre todos os microserviços.
- Os Workers consomem eventos publicados pelas APIs utilizando RabbitMQ.
- As configurações de banco de dados e mensageria são injetadas via variáveis de ambiente.
- Recomenda-se utilizar versões específicas das imagens (`1.0.0`, `1.0.1`, etc.) em ambientes de produção para garantir previsibilidade nos deployments.