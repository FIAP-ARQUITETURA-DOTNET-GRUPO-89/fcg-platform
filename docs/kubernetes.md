# ☸️ Kubernetes

Este documento descreve como realizar o deploy da plataforma FCG em um cluster Kubernetes.

## 📑 Sumário

- [🚀 Deploy da Plataforma](#-deploy-da-plataforma)
- [🛠 Scripts úteis](#-scripts-úteis)
- [🛠 Comandos Úteis](#-comandos-úteis)

# 🚀 Deploy da Plataforma

Antes de iniciar, certifique-se de que o ambiente foi preparado conforme descrito no documento:

- [Getting Started](getting-started.md)

## Namespace

O primeiro recurso a ser criado é o namespace da plataforma.

```bash
kubectl apply -f k8s/namespace.yaml
```

Verificar:

```bash
kubectl get namespaces
```

Resultado esperado:

```text
NAME
fcg-platform
```

## Infraestrutura

Após criar o namespace, realize o deploy da infraestrutura compartilhada.

A documentação de cada componente encontra-se em:

- [PostgreSQL](k8s/infrastructure/postgres.md)
- [RabbitMQ](k8s/infrastructure/rabbitmq.md)
- [Kong API Gateway](k8s/infrastructure/kong.md)

## Microsserviços

Após a infraestrutura estar disponível, realize o deploy dos microsserviços na seguinte ordem:

1. FCG Users
2. FCG Notifications
3. FCG Catalog
4. FCG Payments

A documentação de cada componente encontra-se em:

- 👤 [FCG Users API](k8s/services/fcg-users-api.md)

- 🔔 [FCG Notifications Worker](k8s/services/fcg-notifications-worker.md)

- 🎮 [FCG Catalog API](k8s/services/fcg-catalog-api.md)

- 🎮 [FCG Catalog Worker](k8s/services/fcg-catalog-worker.md)

- 💳 [FCG Payments API](k8s/services/fcg-payments-api.md)

- 💳 [FCG Payments Worker](k8s/services/fcg-payments-worker.md)

# 🛠 Scripts úteis

Os scripts foram desenvolvidos para serem executados em um terminal compatível com **Bash** (Linux, macOS ou Git Bash no Windows).

No Windows, abra o **Git Bash** na raiz do repositório e execute os comandos abaixo.

## 🚀 Deploy completo

```bash
./scripts/deploy.sh
```

Responsável por realizar o deploy da infraestrutura compartilhada e dos microsserviços da plataforma no Kubernetes.

## 🧹 Cleanup do cluster

```bash
./scripts/cleanup.sh
```

Remove todos os recursos da plataforma implantados no cluster Kubernetes.

# 🛠 Comandos Úteis

Listar todos os recursos.

```bash
kubectl get all -n fcg-platform
```

Listar Pods.

```bash
kubectl get pods -n fcg-platform
```

Listar Deployments.

```bash
kubectl get deployments -n fcg-platform
```

Listar Services.

```bash
kubectl get services -n fcg-platform
```

Visualizar logs.

```bash
kubectl logs deployment/<deployment> -n fcg-platform
```

Descrever um Pod.

```bash
kubectl describe pod <pod> -n fcg-platform
```

Remover toda a infraestrutura.

```bash
kubectl delete -f k8s/
```

Ou remover completamente a plataforma.

```bash
kubectl delete namespace fcg-platform
```
