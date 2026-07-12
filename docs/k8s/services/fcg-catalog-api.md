# 📚 FCG Catalog API

Este documento descreve o deploy do microsserviço **fcg-catalog-api** no Kubernetes.

A API é responsável pelo gerenciamento do catálogo de jogos da plataforma e publicação de eventos para o RabbitMQ.

## 📑 Sumário

- [🚀 Deploy](#-deploy)
  - [ConfigMap](#configmap)
  - [Secret](#secret)
  - [Deployment](#deployment)
  - [Service](#service)
- [🔄 Port Forward](#-port-forward)
- [🧠 Arquitetura](#-arquitetura)

# 🚀 Deploy

## ConfigMap

Responsável por configurações não sensíveis como ambiente, Serilog e demais configurações da aplicação.

```bash
kubectl apply -f microservices/fcg-catalog/k8s/api/configmap.yaml
```

Verificar:

```bash
kubectl get configmaps -n fcg-platform
```

## Secret

Contém dados sensíveis como connection strings e demais segredos utilizados pela aplicação.

```bash
kubectl apply -f microservices/fcg-catalog/k8s/api/secret.yaml
```

Verificar:

```bash
kubectl get secrets -n fcg-platform
```

## Deployment

Responsável pela execução da API.

```bash
kubectl apply -f microservices/fcg-catalog/k8s/api/deployment.yaml
```

Verificar:

```bash
kubectl get deployments -n fcg-platform
kubectl get pods -n fcg-platform
```

## Service

Expõe a API internamente no cluster.

```bash
kubectl apply -f microservices/fcg-catalog/k8s/api/service.yaml
```

Verificar:

```bash
kubectl get svc -n fcg-platform
```

# 🔄 Port Forward

Como o Service é ClusterIP, utilizamos port-forward para acesso local:

```bash
kubectl port-forward svc/fcg-catalog-api 7030:7030 -n fcg-platform
```

A API estará disponível em:

```text
http://localhost:7030
```

# 🧠 Arquitetura

A API se comunica com:

- PostgreSQL (persistência)
- RabbitMQ (publicação de eventos)
