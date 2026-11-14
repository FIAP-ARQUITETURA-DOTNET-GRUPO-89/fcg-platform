# 🐘 1º passo: Implantação da infraestrutura

**Projeto:** FIAP FCG  
**Cluster:** `fcg-platform`  
**Região AWS:** Virgínia do Norte (`us-east-1`)  
**Namespace Kubernetes:** `fcg-platform`

## 1. Pré-requisitos

Antes de iniciar, confirme que:

- A infraestrutura AWS foi provisionada pelo Terraform.
- O cluster EKS e os nós de trabalho estão disponíveis.
- AWS CLI e `kubectl` estão instalados.
- O acesso à AWS está autenticado.
- O repositório `fcg-platform` está atualizado.

## 2. Conectar ao cluster EKS

Autentique-se na AWS:

```powershell
aws login
```

Atualize o kubeconfig:

```powershell
aws eks update-kubeconfig `
  --name fcg-platform `
  --region us-east-1
```

Verifique o contexto e os nós:

```powershell
kubectl config current-context
kubectl get nodes
```

Os nós devem apresentar o status `Ready`.

## 3. Implantar os recursos Kubernetes

Acesse a pasta `k8s` do repositório:

```powershell
cd "C:\REPOSITORIO\4. FIAP\fcg-platform\k8s"
```

Crie o namespace:

```powershell
kubectl apply -f namespace.yaml
```

### 3.1. PostgreSQL

```powershell
kubectl apply -f infrastructure/postgres/
```

### 3.2. pgAdmin _opcional_

```powershell
kubectl apply -f infrastructure/pgadmin/
```

**Acesso ao pgAdmin (opcional)**

Para acessar a interface, execute o comando abaixo e mantenha o terminal aberto:

```powershell
kubectl port-forward svc/pgadmin 5050:80 -n fcg-platform
```

Em seguida, acesse pelo navegador:

`http://localhost:5050`

### 3.3. RabbitMQ

```powershell
kubectl apply -f infrastructure/rabbitmq/
```

**Acesso ao painel do RabbitMQ (opcional)**

Para acessar a interface de gerenciamento, execute o comando abaixo e mantenha o terminal aberto:

```powershell
kubectl port-forward svc/rabbitmq 15672:15672 -n fcg-platform
```

Em seguida, acesse pelo navegador:

`http://localhost:15672`

### 3.4. MongoDB

```powershell
kubectl apply -f infrastructure/mongodb/
```

### 3.5. Redis

```powershell
kubectl apply -f infrastructure/redis/
```

### 3.6. Kong

```powershell
kubectl apply -k infrastructure/kong/
```

### 3.7. OpenSearch

```powershell
kubectl apply -f infrastructure/opensearch/
```

### 3.8. Observabilidade _opcional_

Crie o namespace e o Secret utilizado pelo Grafana:

```powershell
kubectl apply -f infrastructure/observability/namespace.yaml
kubectl apply -f infrastructure/observability/secret.yaml
```

Adicione o repositório Helm do Prometheus Community:

```powershell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
helm repo update
```

Instale o kube-prometheus-stack:

```powershell
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack `
  --namespace observability `
  --values infrastructure/observability/values-kube-prometheus-stack.yaml `
  --wait `
  --timeout 15m
```

Aplique os recursos complementares de observabilidade:

```powershell
kubectl apply -k infrastructure/observability/
```

**Acesso ao Grafana (opcional)**

Para acessar o painel, execute o comando abaixo e mantenha o terminal aberto:

```powershell
kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n observability
```

Em seguida, acesse pelo navegador:

`http://localhost:3000`

**Credenciais de acesso:**

- Usuário: `admin`
- Senha: definida em `secret.yaml`.

## 4. Validar a infraestrutura

Confira os recursos implantados no namespace:

```powershell
kubectl get pods -n fcg-platform
kubectl get svc -n fcg-platform
kubectl get pvc -n fcg-platform
```

Verifique se os Pods estão em execução e se os PVCs estão vinculados (`Bound`), quando aplicável.

---

## ➡️ Próximo passo

Siga para [2 - Implantação dos microserviços](./2-microservicos.md) para realizar o deploy das APIs e dos workers da plataforma FCG.
