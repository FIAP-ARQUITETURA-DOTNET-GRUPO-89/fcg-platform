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

### 3.2. pgAdmin \*opcional

```powershell
kubectl apply -f infrastructure/pgadmin/
```

### 3.3. RabbitMQ

```powershell
kubectl apply -f infrastructure/rabbitmq/
```

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
kubectl apply -f infrastructure/kong/
```

### 3.7. Observabilidade \*opcional

_Comando de implantação a adicionar._

## 4. Validar a infraestrutura

Confira os recursos implantados no namespace:

```powershell
kubectl get pods -n fcg-platform
kubectl get svc -n fcg-platform
kubectl get pvc -n fcg-platform
```

Verifique se os Pods estão em execução e se os PVCs estão vinculados (`Bound`), quando aplicável.

---

### ➡️ Próximo passo

Consulte os procedimentos detalhados de configuração e validação na pasta [manual](../manual/).
