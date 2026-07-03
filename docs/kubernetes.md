# ☸️ Kubernetes

Este documento descreve como realizar o deploy da plataforma FCG em um cluster Kubernetes.

## 📑 Sumário

- [🚀 Deploy da Plataforma](#-deploy-da-plataforma)
- [🔐 Secrets](#-secrets)
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

- [PostgreSQL](infrastructure/postgres.md)
- [RabbitMQ](infrastructure/rabbitmq.md)

## Microsserviços

Após a infraestrutura estar disponível, realize o deploy dos microsserviços na seguinte ordem:

1. Users API
2. Catalog API
3. Payments API
4. Notifications API

A documentação de cada serviço encontra-se em:

- Users API
- Catalog API
- Payments API
- Notifications API

# 🔐 Secrets

A plataforma utiliza Kubernetes Secrets para armazenar informações sensíveis.

Exemplos:

- credenciais de banco de dados
- usuários e senhas
- connection strings
- chaves e tokens de autenticação

Base64 é apenas codificação, não criptografia.

👉 Veja detalhes em: [Secrets](secrets.md)

# 🛠 Scripts úteis

Scripts disponíveis no repositório para automação do ambiente Kubernetes.

## 🚀 Deploy completo

```bash
./scripts/deploy.sh
```

Responsável por subir toda a infraestrutura e serviços.

## 🧹 Cleanup do cluster

```bash
./scripts/cleanup.sh
```

Remove todos os recursos da plataforma no Kubernetes.

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
