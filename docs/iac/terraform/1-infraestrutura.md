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

### 3.0. Credenciais (Parameter Store + External Secrets)

Nenhum manifesto do repositório contém senhas. As credenciais ficam no **AWS Systems Manager Parameter Store** (`SecureString`, prefixo `/fcg-platform`) e o **External Secrets Operator**, instalado pelo Terraform, cria os Secrets do Kubernetes. Detalhes em [Gestão de Segredos](../../secrets.md).

Se os parâmetros ainda não foram publicados, siga o guia [2 - Configuração do Parameter Store](../setup/2-parameter-store.md) (passos 1 e 2 abaixo, em resumo).

1. Na raiz do repositório, crie o `.env.aws` a partir do modelo e preencha com valores fortes (`openssl rand -hex 24`):

   ```powershell
   Copy-Item ..\.env.example ..\.env.aws
   ```

2. Publique os parâmetros. Execute no **Git Bash**, na raiz do repositório:

   ```bash
   bash scripts/secrets.sh aws
   ```

3. Conecte o cluster ao Parameter Store e crie os ExternalSecrets:

   ```powershell
   kubectl apply -f aws/cluster-secret-store.yaml
   kubectl apply -f aws/external-secrets.yaml
   ```

4. Confira a sincronização:

   ```powershell
   kubectl get clustersecretstore
   kubectl get externalsecrets -n fcg-platform
   ```

   O `ClusterSecretStore` deve estar `Valid`/`Ready` e os ExternalSecrets com status `SecretSynced`. O `kong-config` só sincroniza depois do passo 3.6, que cria o ConfigMap `kong-config-template`.

> **Volumes existentes:** o PostgreSQL e o RabbitMQ gravam usuário e senha apenas na primeira inicialização do volume. Se o cluster já tinha esses componentes com as senhas antigas, remova os PVCs `postgres-pvc` e `rabbitmq-pvc` (os dados são perdidos) antes de implantá-los novamente.

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

Crie o namespace e o ExternalSecret do Grafana (a senha vem do parâmetro `/fcg-platform/grafana`):

```powershell
kubectl apply -f infrastructure/observability/namespace.yaml
kubectl apply -f aws/external-secrets-observability.yaml
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
- Senha: `GRAFANA_ADMIN_PASSWORD` definida no `.env.aws` (parâmetro `/fcg-platform/grafana`).

## 4. Validar a infraestrutura

Confira os recursos implantados no namespace:

```powershell
kubectl get pods -n fcg-platform
kubectl get svc -n fcg-platform
kubectl get pvc -n fcg-platform
kubectl get externalsecrets -A
```

Verifique se os Pods estão em execução e se os PVCs estão vinculados (`Bound`), quando aplicável.

---

## ➡️ Próximo passo

Siga para [2 - Implantação dos microserviços](./2-microservicos.md) para realizar o deploy das APIs e dos workers da plataforma FCG.
