# 🚀 FCG Platform

Repositório responsável pela orquestração da plataforma FCG, contendo configurações do Docker Compose, Kubernetes e infraestrutura compartilhada utilizada pelos microsserviços.

## 📑 Sumário

- [📦 Clonando o repositório](#-clonando-o-repositório)
- [🚀 Começando](#-começando)
- [🏛️ Arquitetura](#️-arquitetura)
- [🐳 Executar com Docker](#-executar-com-docker)
- [☸️ Executar com Kubernetes](#️-executar-com-kubernetes)
- [🗃️ Redis — Cache Distribuído](#️-redis--cache-distribuído)
- [🧪 Validação](#-validação)

## 📦 Clonando o repositório

Este repositório utiliza **Git Submodules** para referenciar os repositórios dos microsserviços.

### Clone do repositório

Clone o repositório juntamente com todos os submódulos:

```bash
git clone --recurse-submodules https://github.com/FIAP-ARQUITETURA-DOTNET-GRUPO-89/fcg-platform.git
```

Os microsserviços referenciados como submódulos são mantidos dentro do diretório `microservices/`.

Sempre que houver atualização da referência dos submódulos, execute novamente o comando abaixo para sincronizar todos os microsserviços com as versões utilizadas pela plataforma:

```bash
git submodule update --init --recursive
```

## 🚀 Começando

Antes de executar a plataforma, prepare o ambiente local.

👉 [Guia de inicialização do ambiente](docs/getting-started.md)

## 🏛️ Arquitetura

A FCG Platform utiliza uma arquitetura baseada em microsserviços, comunicação assíncrona orientada a eventos e infraestrutura containerizada.

👉 [Visão geral da arquitetura](docs/architecture/architecture-overview.md)

A infraestrutura compartilhada utilizada pela plataforma inclui:

- PostgreSQL
- RabbitMQ
- Redis
- Docker Compose
- Kubernetes

O Redis é utilizado pelo **CatalogAPI** como **cache distribuído**, reduzindo consultas repetidas ao banco de dados durante as operações de leitura do catálogo.

## 🐳 Executar com Docker

Se você deseja executar a FCG Platform localmente utilizando Docker Compose:

👉 [Documentação do Docker](docs/docker-compose.md)

O ambiente Docker Compose possui o Redis como infraestrutura compartilhada:

```yaml
redis:
  image: redis:7-alpine
  container_name: fcg-redis
  restart: unless-stopped
  ports:
    - "6379:6379"
  volumes:
    - redis-data:/data
  healthcheck:
    test: ["CMD", "redis-cli", "ping"]
    interval: 5s
    timeout: 5s
    retries: 10
  networks:
    - fcg-network
```

O CatalogAPI utiliza o Redis através da connection string:

```text
ConnectionStrings__redis=redis:6379
```

O serviço do catálogo possui dependência de disponibilidade do Redis antes de iniciar.

Para validar a configuração do Docker Compose:

```bash
docker compose -f docker-compose-development.yml config
```

Para iniciar os serviços principais:

```bash
docker compose -f docker-compose-development.yml up -d postgres rabbitmq redis catalog-api
```

Para verificar o estado dos containers:

```bash
docker compose -f docker-compose-development.yml ps
```

O mesmo serviço Redis também está configurado no arquivo:

```text
docker-compose.yml
```

## ☸️ Executar com Kubernetes

Se você deseja executar a FCG Platform em um cluster Kubernetes:

👉 [Guia de Kubernetes](docs/kubernetes.md)

O ambiente Kubernetes possui uma infraestrutura dedicada para o Redis:

```text
k8s/
└── infrastructure/
    └── redis/
        ├── deployment.yaml
        └── service.yaml
```

O Redis é executado através de um Deployment:

```text
fcg-redis
```

e disponibilizado internamente no cluster através do Service:

```text
fcg-redis:6379
```

O CatalogAPI utiliza essa configuração através da variável:

```text
ConnectionStrings__redis
```

com o valor:

```text
fcg-redis:6379
```

O Redis possui configurações de **liveness** e **readiness probes**, permitindo que o Kubernetes acompanhe sua disponibilidade.

### CatalogAPI no Kubernetes

O CatalogAPI utiliza a imagem:

```text
jondamiao/fcg-catalog-api:1.0.2
```

O Deployment do CatalogAPI utiliza a infraestrutura compartilhada de PostgreSQL, RabbitMQ e Redis.

Para verificar os Pods:

```bash
kubectl get pods -n fcg-platform
```

Para verificar os Services:

```bash
kubectl get services -n fcg-platform
```

Para verificar o Deployment do CatalogAPI:

```bash
kubectl get deployment fcg-catalog-api -n fcg-platform
```

Para verificar a imagem utilizada pelo CatalogAPI:

```bash
kubectl get deployment fcg-catalog-api -n fcg-platform -o jsonpath="{.spec.template.spec.containers[0].image}"
```

Para validar a disponibilidade do Redis:

```bash
kubectl exec -it deployment/fcg-redis -n fcg-platform -- redis-cli PING
```

O resultado esperado é:

```text
PONG
```

## 🗃️ Redis — Cache Distribuído

O Redis foi adicionado à infraestrutura da plataforma para atender ao requisito de **cache distribuído** da Fase 3 do Tech Challenge.

O cache é utilizado pelo CatalogAPI nos endpoints:

```text
GET /api/games
GET /api/games/{id}
```

O objetivo é reduzir consultas repetidas ao PostgreSQL e melhorar o tempo de resposta das consultas de leitura.

### Docker Compose

No Docker Compose, o Redis utiliza a imagem:

```text
redis:7-alpine
```

O serviço é disponibilizado internamente para os microsserviços através de:

```text
redis:6379
```

Os dados do Redis são armazenados no volume:

```text
redis-data
```

### Kubernetes

No Kubernetes, o Redis utiliza:

```text
Deployment: fcg-redis
Service: fcg-redis
Porta: 6379
Namespace: fcg-platform
```

O CatalogAPI se conecta ao Redis através do Service Kubernetes:

```text
fcg-redis:6379
```

### Estratégia de cache

O CatalogAPI utiliza `StackExchange.Redis` para comunicação com o Redis.

São armazenados em cache:

- Resultados paginados de `GET /api/games`.
- Resultados individuais de `GET /api/games/{id}`.

As entradas possuem TTL de **5 minutos**.

As chaves utilizadas seguem os padrões:

```text
fcg:catalog:games:v{version}:page:{page}:size:{pageSize}
fcg:catalog:game:{id}
fcg:catalog:games:version
```

O versionamento é utilizado para realizar a invalidação lógica do cache das listagens sem a necessidade de localizar e excluir todas as chaves de paginação existentes.

### Invalidação do cache

O cache é invalidado após operações que alteram os dados do catálogo.

A invalidação da lista ocorre após:

- Criação de jogo.
- Atualização de jogo.
- Alteração de preço.
- Exclusão de jogo.

O cache individual do jogo também é invalidado após operações de atualização, alteração de preço ou exclusão.

### Comportamento em caso de indisponibilidade

O acesso ao Redis foi implementado de forma **fail-open**.

Caso o Redis esteja indisponível:

- A API continua processando as requisições.
- As consultas podem ser realizadas diretamente no PostgreSQL.
- As falhas de leitura e escrita no Redis são registradas em log.

Dessa forma, a indisponibilidade temporária do cache não impede o funcionamento principal do catálogo.

## 🧪 Validação

A implementação do Redis foi validada nos ambientes de desenvolvimento, Docker Compose e Kubernetes.

### Validação do Redis

A disponibilidade do Redis foi validada através do comando:

```bash
redis-cli PING
```

e, no Kubernetes:

```bash
kubectl exec -it deployment/fcg-redis -n fcg-platform -- redis-cli PING
```

O resultado esperado é:

```text
PONG
```

### Validação das chaves

Após consultas ao catálogo, foram identificadas chaves Redis seguindo os padrões:

```text
fcg:catalog:games:version
fcg:catalog:games:v1:page:1:size:10
fcg:catalog:game:{id}
```

Após uma operação de alteração, a versão da listagem é incrementada, fazendo com que as próximas consultas utilizem uma nova chave de cache.

### Validação do TTL

As entradas do cache possuem TTL de **5 minutos**.

A validação confirmou que as chaves armazenadas no Redis recebem o tempo de expiração configurado.

### Validação de invalidação

Foram validadas operações de:

- Criação de jogo.
- Atualização de jogo.
- Alteração de preço.
- Exclusão de jogo.

Após essas operações, as consultas seguintes retornaram os dados atualizados, confirmando a invalidação do cache.

### Validação de indisponibilidade

O Redis foi temporariamente interrompido durante uma consulta ao catálogo.

Mesmo com o Redis indisponível, a API continuou retornando os dados através do PostgreSQL, confirmando o comportamento **fail-open**.

### Validação de concorrência

Foram realizadas múltiplas consultas simultâneas ao endpoint de listagem.

As requisições retornaram corretamente e o cache permaneceu consistente para o escopo atual da implementação.

### Testes automatizados

A implementação foi validada através de testes unitários e de integração no CatalogAPI.

Foram validados cenários de:

- Cache hit.
- Cache miss.
- Consulta ao banco após cache miss.
- Armazenamento do resultado no cache.
- Invalidação após criação.
- Invalidação após atualização.
- Invalidação após alteração de preço.
- Invalidação após exclusão.
- Consulta por ID utilizando cache.
- Comportamento quando o Redis está indisponível.

### Teste de performance

Foi realizado um teste comparando uma consulta com **cache miss** com 20 consultas utilizando **cache hit**.

Resultados obtidos:

| Métrica | Resultado |
|---------|-----------|
| Cache MISS | 453,16 ms |
| Cache HIT — 20 requisições | 132,30 ms |
| Cache HIT — média por requisição | 6,62 ms |
| Redução observada | 98,54% |

Os resultados demonstraram ganho significativo de desempenho nas consultas atendidas pelo cache.
