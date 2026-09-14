# 🍃 MongoDB

Este documento descreve como realizar o deploy da instância do MongoDB utilizada pela plataforma FCG no Kubernetes.

## 📑 Sumário

- [🚀 Deploy](#-deploy)
  - [PersistentVolumeClaim](#persistentvolumeclaim)
  - [Deployment](#deployment)
  - [Service](#service)
- [🔄 Port Forward](#-port-forward)

# 🚀 Deploy

## PersistentVolumeClaim

Aplicar:

```bash
kubectl apply -f k8s/infrastructure/mongodb/pvc.yaml
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
kubectl apply -f k8s/infrastructure/mongodb/deployment.yaml
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
mongodb-xxxxxxxxxx           1/1     Running
```

Visualizar detalhes:

```bash
kubectl describe pod <pod> -n fcg-platform
```

Visualizar logs:

```bash
kubectl logs deployment/mongodb -n fcg-platform
```

## Service

Aplicar:

```bash
kubectl apply -f k8s/infrastructure/mongodb/service.yaml
```

Verificar:

```bash
kubectl get services -n fcg-platform
```

Resultado esperado:

```text
NAME
mongodb
```

# 🔄 Port Forward

Como o Service do MongoDB é do tipo **ClusterIP**, ele só pode ser acessado internamente pelo cluster.

Durante o desenvolvimento, utilize o comando abaixo para expor temporariamente o banco na máquina local.

```bash
kubectl port-forward svc/mongodb 27017:27017 -n fcg-platform
```

Após executar o comando, o MongoDB estará disponível em:

```text
Host: localhost
Port: 27017
```