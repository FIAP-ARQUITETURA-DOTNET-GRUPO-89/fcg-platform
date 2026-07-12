# 🐘 PostgreSQL

Este documento descreve como realizar o deploy da instância do PostgreSQL utilizada pela plataforma FCG no Kubernetes.

## 📑 Sumário

- [🚀 Deploy](#-deploy)
  - [ConfigMap](#configmap)
  - [Secret](#secret)
  - [PersistentVolumeClaim](#persistentvolumeclaim)
  - [Deployment](#deployment)
  - [Service](#service)
- [🔄 Port Forward](#-port-forward)

# 🚀 Deploy

## ConfigMap

Aplicar:

```bash
kubectl apply -f k8s/infrastructure/postgres/configmap.yaml
```

Verificar:

```bash
kubectl get configmaps -n fcg-platform
```

## Secret

Aplicar:

```bash
kubectl apply -f k8s/infrastructure/postgres/secret.yaml
```

Verificar:

```bash
kubectl get secrets -n fcg-platform
```

## PersistentVolumeClaim

Aplicar:

```bash
kubectl apply -f k8s/infrastructure/postgres/pvc.yaml
```

Verificar:

```bash
kubectl get pvc -n fcg-platform
```

Resultado esperado:

```text
STATUS
Bound
```

## Deployment

Aplicar:

```bash
kubectl apply -f k8s/infrastructure/postgres/deployment.yaml
```

Verificar:

```bash
kubectl get deployments -n fcg-platform
```

Verificar os Pods:

```bash
kubectl get pods -n fcg-platform
```

Resultado esperado:

```text
NAME                         READY   STATUS
postgres-xxxxxxxxxx          1/1     Running
```

Visualizar detalhes:

```bash
kubectl describe pod <pod> -n fcg-platform
```

Visualizar logs:

```bash
kubectl logs deployment/postgres -n fcg-platform
```

## Service

Aplicar:

```bash
kubectl apply -f k8s/infrastructure/postgres/service.yaml
```

Verificar:

```bash
kubectl get services -n fcg-platform
```

Resultado esperado:

```text
NAME
postgres
```

# 🔄 Port Forward

Como o Service do PostgreSQL é do tipo **ClusterIP**, ele só pode ser acessado internamente pelo cluster.

Durante o desenvolvimento, utilize o comando abaixo para expor temporariamente o banco na máquina local.

```bash
kubectl port-forward svc/postgres 5432:5432 -n fcg-platform
```

Após executar o comando, o PostgreSQL estará disponível em:

```text
Host: localhost
Port: 5432
```
