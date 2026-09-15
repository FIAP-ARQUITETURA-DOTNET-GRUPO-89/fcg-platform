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
| Redis | Cache | 6379 |
| Prometheus | Observabilidade | 9090 |
| Grafana | Observabilidade | 3000 |

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

## Redis

O Redis é utilizado pelo **FCG Catalog** como cache distribuído, reduzindo consultas repetidas ao banco de dados e melhorando o desempenho das consultas do catálogo.

| Configuração | Valor |
|--------------|-------|
| Host | localhost |
| Porta | 6379 |
| Serviço Docker | redis |
| Rede | fcg-network |

O Redis utiliza a imagem:

```text
redis:7-alpine
```

O serviço possui persistência por meio do volume:

```text
redis-data
```

Para verificar se o Redis está respondendo:

```bash
docker exec fcg-redis redis-cli ping
```

Resultado esperado:

```text
PONG
```

---

## Prometheus

O **Prometheus** coleta métricas dos microsserviços FCG (Users, Catalog, Payments) a partir do endpoint `/metrics` que cada API expõe no formato Prometheus.

| Configuração | Valor |
|--------------|-------|
| URL | http://localhost:9090 |
| Serviço Docker | prometheus |
| Rede | fcg-network |

A imagem utilizada é:

```text
prom/prometheus:v2.55.1
```

Configuração de scrape em:

```text
docker/infrastructure/prometheus/prometheus.yml
```

Para inspecionar quais alvos estão sendo coletados, acesse `http://localhost:9090/targets`.

---

## Grafana

O **Grafana** exibe os dashboards em tempo real com métricas coletadas pelo Prometheus.

| Configuração | Valor |
|--------------|-------|
| URL | http://localhost:3000 |
| Usuário | admin |
| Senha | admin |
| Serviço Docker | grafana |
| Rede | fcg-network |

A imagem utilizada é:

```text
grafana/grafana:11.3.0
```

O Grafana já vem com o datasource **Prometheus** e o dashboard **FCG — Visão geral** provisionados automaticamente. Os arquivos de configuração estão em:

```text
docker/infrastructure/grafana/
├── provisioning/
│   ├── datasources/prometheus.yml
│   └── dashboards/fcg.yml
└── dashboards/
    └── fcg-overview.json
```

Persistência do estado do Grafana via volume:

```text
grafana-data
```

Após subir a plataforma, acesse `http://localhost:3000` e o dashboard estará na pasta **FCG** dentro do menu **Dashboards**.

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

Para o FCG Catalog, a conexão com o Redis utiliza:

```yaml
environment:
  ConnectionStrings__redis: redis:6379
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
- PostgreSQL, RabbitMQ e Redis são compartilhados entre os microserviços.
- Os Workers consomem eventos publicados pelas APIs utilizando RabbitMQ.
- O FCG Catalog utiliza o Redis como cache distribuído.
- As configurações de banco de dados, mensageria e cache são injetadas via variáveis de ambiente.
- O Prometheus faz scrape do endpoint `/metrics` de cada API a cada 15 s; o Grafana consome esses dados e exibe no dashboard **FCG — Visão geral**.
- Recomenda-se utilizar versões específicas das imagens (`1.0.0`, `1.0.1`, etc.) em ambientes de produção para garantir previsibilidade nos deployments.
