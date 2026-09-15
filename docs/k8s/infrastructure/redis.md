# 🔴 Redis

Este documento descreve a configuração do **Redis** utilizado como infraestrutura de cache distribuído da plataforma FCG no Kubernetes.

## 📑 Sumário

- [🎯 Objetivo](#-objetivo)
- [⚙️ Configuração](#️-configuração)
- [🚀 Deploy](#-deploy)
- [🔎 Validação](#-validação)
- [🧹 Remoção](#-remoção)

# 🎯 Objetivo

O Redis é utilizado pelo **FCG Catalog** como cache distribuído, reduzindo consultas repetidas ao banco de dados e melhorando o desempenho das consultas do catálogo.

O Redis é executado no Kubernetes como um **Deployment** com uma réplica e disponibilizado internamente por meio de um **Service**.

# ⚙️ Configuração

Os manifests do Redis estão localizados em:

```text
k8s/infrastructure/redis/
├── deployment.yaml
└── service.yaml
```

### Deployment

O Redis utiliza a imagem:

```text
redis:7-alpine
```

O container expõe a porta:

```text
6379
```

O Deployment possui:

- 1 réplica;
- readiness probe;
- liveness probe;
- limites e requests de CPU e memória.

### Service

O Redis é disponibilizado pelo Service:

```text
fcg-redis
```

Dentro do cluster, os microsserviços podem acessar o Redis por:

```text
fcg-redis:6379
```

O Service utiliza o tipo:

```text
ClusterIP
```

# 🚀 Deploy

O Redis faz parte da infraestrutura compartilhada da plataforma.

Para realizar o deploy manualmente:

```bash
kubectl apply -f k8s/infrastructure/redis/deployment.yaml
kubectl apply -f k8s/infrastructure/redis/service.yaml
```

Para verificar o Deployment:

```bash
kubectl get deployment fcg-redis -n fcg-platform
```

Para verificar o Pod:

```bash
kubectl get pods -n fcg-platform -l app.kubernetes.io/name=fcg-redis
```

Para verificar o Service:

```bash
kubectl get service fcg-redis -n fcg-platform
```

O script de deploy completo da plataforma também realiza automaticamente a criação do Redis:

```bash
./scripts/deploy.sh
```

# 🔎 Validação

Para verificar se o Redis está respondendo corretamente:

```bash
kubectl exec deployment/fcg-redis -n fcg-platform -- redis-cli ping
```

Resultado esperado:

```text
PONG
```

Para visualizar os logs:

```bash
kubectl logs deployment/fcg-redis -n fcg-platform
```

# 🧹 Remoção

Para remover o Redis manualmente:

```bash
kubectl delete -f k8s/infrastructure/redis/ --ignore-not-found
```

O Redis também é removido automaticamente pelo script de cleanup:

```bash
./scripts/cleanup.sh
```
