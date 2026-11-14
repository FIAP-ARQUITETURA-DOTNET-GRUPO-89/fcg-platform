# 🚀 2º passo: Implantação dos microserviços

**Projeto:** FIAP FCG  
**Cluster:** `fcg-platform`  
**Região AWS:** Virgínia do Norte (`us-east-1`)  
**Namespace Kubernetes:** `fcg-platform`

## 📋 1. Pré-requisitos

Antes de iniciar, confirme que:

- A infraestrutura AWS foi provisionada pelo Terraform.
- O cluster EKS e os nós de trabalho estão disponíveis.
- Os microserviços possuem imagens Docker publicadas no Amazon ECR.
- AWS CLI e `kubectl` estão instalados.
- O acesso à AWS está autenticado.
- A infraestrutura Kubernetes foi implantada conforme o guia [1 - Implantação da infraestrutura](./1-infraestrutura.md).

## ☁️ 2. Conectar ao cluster EKS

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

## 🔗 3. Verificar as dependências

Antes de implantar os microserviços, confirme que o namespace e os componentes necessários estão disponíveis:

```powershell
kubectl get namespace fcg-platform
kubectl get pods -n fcg-platform
kubectl get svc -n fcg-platform
```

Os serviços utilizam os seguintes nomes DNS internos:

- PostgreSQL: `postgres:5432`
- RabbitMQ: `rabbitmq:5672`
- MongoDB: `mongodb:27017`
- Redis: `fcg-redis:6379`

Implante e valide esses componentes antes de prosseguir, conforme o guia [1 - Implantação da infraestrutura](./1-infraestrutura.md).

## 🏗️ 4. Implantar os microserviços

Acesse a pasta raiz do repositório:

```powershell
cd "C:\REPOSITORIO\4. FIAP\fcg-platform"
```

### 4.1. FCG Users API

```powershell
kubectl apply -f microservices/fcg-users/k8s/api/
```

### 4.2. FCG Catalog API e Worker

```powershell
kubectl apply -f microservices/fcg-catalog/k8s/api/
kubectl apply -f microservices/fcg-catalog/k8s/worker/
```

### 4.3. FCG Payments API e Worker

```powershell
kubectl apply -f microservices/fcg-payments/k8s/api/
kubectl apply -f microservices/fcg-payments/k8s/worker/
```

### 4.4. FCG Notifications Worker

```powershell
kubectl apply -f microservices/fcg-notifications/k8s/worker/
```

## ✅ 5. Validar a implantação

Confira os Deployments, Pods e Services:

```powershell
kubectl get deployments -n fcg-platform
kubectl get pods -n fcg-platform -o wide
kubectl get svc -n fcg-platform
```

Verifique se os Pods estão em execução (`Running`) e se os Deployments apresentam o número esperado de réplicas disponíveis.

## 🌐 6. Atualizar o DNS no Postman

Após cada `terraform apply`, um novo DNS é criado para o Load Balancer do
Kong. Obtenha o DNS atual:

```powershell
$dns = kubectl get svc kong -n fcg-platform -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
"http://{0}:8000/api" -f $dns
```

Atualize a variável `Base-URL-Gateway-API` do arquivo `docs/api-collection/aws.postman_environment.json` com o resultado, por exemplo:

```text
http://k8s-fcgplatf-kong-29fd0d599c-80f32ab160a5e684.elb.us-east-1.amazonaws.com:8000/api
```

Depois use a coleção `docs/api-collection/fcg-platform.postman_collection.json` para chamar os endpoints.

## 🛡️ 7. Cuidados de segurança e custos

- **Credenciais:** não compartilhe chaves de acesso, tokens ou senhas. Evite armazenar credenciais diretamente nos arquivos do projeto.
- **Permissões:** utilize apenas as permissões AWS necessárias para executar as atividades do projeto.
- **Imagens Docker:** mantenha as imagens dos microserviços no Amazon ECR e evite expor credenciais de acesso ao registry.
- **Custos AWS:** lembre-se de que EKS, instâncias EC2, volumes EBS, Load Balancers e outros recursos podem gerar cobranças enquanto estiverem provisionados.
- **Ambiente de estudo:** evite manter o ambiente ativo quando não estiver utilizando o projeto.
- **Encerramento:** ao finalizar os estudos, siga o procedimento de remoção descrito no README do Terraform.

## ➡️ Próximo passo

Quando finalizar os testes, consulte a seção [Remover os recursos](./README.md#-remover-os-recursos) no README do Terraform para destruir a infraestrutura e conferir no Console AWS se não restaram recursos que possam gerar cobranças.
