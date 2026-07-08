# 🔔 FCG Notifications Worker

Este documento descreve o deploy do microsserviço **fcg-notifications-worker** no Kubernetes.

O Worker é responsável pelo processamento assíncrono de mensagens provenientes do RabbitMQ, executando tarefas de background como consumidores de eventos relacionados às notificações da plataforma.

## 📑 Sumário

- [🚀 Deploy](#-deploy)
  - [ConfigMap](#configmap)
  - [Secret](#secret)
  - [Deployment](#deployment)
- [🧠 Arquitetura](#-arquitetura)

# 🚀 Deploy

## ConfigMap

Responsável por configurações não sensíveis como ambiente, Serilog e parâmetros do MassTransit.

```bash
kubectl apply -f microservices/fcg-notifications/k8s/worker/configmap.yaml
```

Verificar:

```bash
kubectl get configmaps -n fcg-platform
```

## Secret

Contém dados sensíveis como connection strings para RabbitMQ e PostgreSQL.

```bash
kubectl apply -f microservices/fcg-notifications/k8s/worker/secret.yaml
```

Verificar:

```bash
kubectl get secrets -n fcg-platform
```

## Deployment

Responsável pela execução do Worker como processo contínuo (BackgroundService).

```bash
kubectl apply -f microservices/fcg-notifications/k8s/worker/deployment.yaml
```

Verificar:

```bash
kubectl get deployments -n fcg-platform
kubectl get pods -n fcg-platform
```

Visualizar logs (importante para debugging de eventos):

```bash
kubectl logs -f deployment/fcg-notifications-worker -n fcg-platform
```

# 🧠 Arquitetura

O Worker atua como consumidor de eventos assíncronos, processando mensagens enviadas pela API via RabbitMQ.
