# 🐇 RabbitMQ

Este documento descreve como realizar o deploy da instância do RabbitMQ utilizada pela plataforma FCG no Kubernetes.

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
kubectl apply -f k8s/infrastructure/rabbitmq/configmap.yaml
```

Verificar:

```bash
kubectl get configmaps -n fcg-platform
```

## Secret

Aplicar:

```bash
kubectl apply -f k8s/infrastructure/rabbitmq/secret.yaml
```

Verificar:

```bash
kubectl get secrets -n fcg-platform
```

## PersistentVolumeClaim

Aplicar:

```bash
kubectl apply -f k8s/infrastructure/rabbitmq/pvc.yaml
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
kubectl apply -f k8s/infrastructure/rabbitmq/deployment.yaml
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
rabbitmq-xxxxxxxxxx          1/1     Running
```

Visualizar detalhes:

```bash
kubectl describe pod <pod> -n fcg-platform
```

Visualizar logs:

```bash
kubectl logs deployment/rabbitmq -n fcg-platform
```

Resultado esperado:

```text
Server startup complete
```

## Service

Aplicar:

```bash
kubectl apply -f k8s/infrastructure/rabbitmq/service.yaml
```

Verificar:

```bash
kubectl get services -n fcg-platform
```

Resultado esperado:

```text
NAME        TYPE        CLUSTER-IP      PORT(S)
rabbitmq    ClusterIP   xxx.xxx.xxx.xx  5672/TCP,15672/TCP
```

# 🔄 Port Forward

Como o Service do RabbitMQ é do tipo **ClusterIP**, ele só pode ser acessado internamente pelo cluster.

Durante o desenvolvimento, utilize o comando abaixo para expor temporariamente a interface de gerenciamento do RabbitMQ.

```bash
kubectl port-forward svc/rabbitmq 15672:15672 -n fcg-platform
```

Após executar o comando, a interface Web estará disponível em:

```text
http://localhost:15672
```

Utilize o usuário e a senha configurados no `rabbitmq-secret`.

Caso seja necessário conectar uma aplicação executando fora do cluster (por exemplo, durante o desenvolvimento local), exponha também a porta AMQP:

```bash
kubectl port-forward svc/rabbitmq 5672:5672 -n fcg-platform
```

Após executar o comando, o broker estará disponível em:

```text
Host: localhost
Port: 5672
```
