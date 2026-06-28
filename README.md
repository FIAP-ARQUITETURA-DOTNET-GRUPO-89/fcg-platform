# 🚀 FcgPlatform

Repositório responsável pela orquestração da plataforma FCG, contendo configurações Docker Compose, Kubernetes e infraestrutura compartilhada.

# ☸️ Kubernetes Local

Este guia descreve como preparar um ambiente **Kubernetes local** utilizando o **Docker Desktop**, aplicar os manifestos da plataforma e validar se a infraestrutura está funcionando corretamente.

Ao final deste documento você terá um cluster Kubernetes local executando o **PostgreSQL**, pronto para receber os microsserviços da plataforma.

# 📑 Sumário

- [📋 Pré-requisitos](#-pré-requisitos)
- [🐳 Habilitando o Kubernetes no Docker Desktop](#-habilitando-o-kubernetes-no-docker-desktop)
- [🔍 Validando o Cluster](#-validando-o-cluster)
- [📁 Estrutura dos Manifestos](#-estrutura-dos-manifestos)
- [🚀 Deploy do PostgreSQL](#-deploy-do-postgresql)
  - [Namespace](#namespace)
  - [ConfigMap](#configmap)
  - [Secret](#secret)
  - [PersistentVolumeClaim](#persistentvolumeclaim)
  - [Deployment](#deployment)
  - [Service](#service)
- [🔐 Trabalhando com Secrets](#-trabalhando-com-secrets)
- [🧪 Testando a Conexão](#-testando-a-conexão)
- [🛠 Comandos Úteis](#-comandos-úteis)
- [🗑 Removendo os Recursos](#-removendo-os-recursos)

# 📋 Pré-requisitos

Antes de iniciar, certifique-se de possuir instalado:

- Docker Desktop
- Kubernetes habilitado
- kubectl

Verifique se o kubectl está instalado:

```bash
kubectl version --client
```

# 🐳 Habilitando o Kubernetes no Docker Desktop

Abra o Docker Desktop.

Acesse:

```
Settings
    └── Kubernetes
```

Marque a opção:

```
Enable Kubernetes
```

Clique em:

```
Apply & Restart
```

A criação do cluster pode levar alguns minutos.

# 🔍 Validando o Cluster

Verifique os contextos disponíveis.

```bash
kubectl config get-contexts
```

Resultado esperado:

```text
CURRENT   NAME
*         docker-desktop
```

Verifique o contexto atual.

```bash
kubectl config current-context
```

Resultado esperado:

```text
docker-desktop
```

Verifique se o cluster está ativo.

```bash
kubectl cluster-info
```

Resultado esperado:

```text
Kubernetes control plane is running...
CoreDNS is running...
```

Verifique os Nodes.

```bash
kubectl get nodes
```

Resultado esperado:

```text
NAME               STATUS
docker-desktop     Ready
```

# 📁 Estrutura dos Manifestos

```text
k8s/
├── namespace.yaml
│
└── infrastructure
    └── postgres
        ├── configmap.yaml
        ├── deployment.yaml
        ├── pvc.yaml
        ├── secret.yaml
        └── service.yaml
```

# 🚀 Deploy do PostgreSQL

## Namespace

Criar o namespace da plataforma.

```bash
kubectl apply -f k8s/namespace.yaml
```

Verificar:

```bash
kubectl get namespaces
```

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

Verificar os Pods.

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
kubectl logs <pod> -n fcg-platform
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

# 🔐 Trabalhando com Secrets

Os Secrets do Kubernetes utilizam **Base64** para armazenar os valores.

> ⚠️ Base64 **não é criptografia**. É apenas uma codificação.

Exemplo:

```yaml
data:
  POSTGRES_USER: ZmNnX3VzZXI=
  POSTGRES_PASSWORD: Y2hhbmdlbWU=
```

Corresponde a:

```text
POSTGRES_USER=fcg_user
POSTGRES_PASSWORD=changeme
```

## Gerando Base64

### Linux / WSL / Git Bash

```bash
echo -n "fcg_user" | base64
```

```bash
echo -n "changeme" | base64
```

### PowerShell

```powershell
[Convert]::ToBase64String(
    [Text.Encoding]::UTF8.GetBytes("fcg_user")
)
```

```powershell
[Convert]::ToBase64String(
    [Text.Encoding]::UTF8.GetBytes("changeme")
)
```

## Decodificando Base64

### Linux

```bash
echo "ZmNnX3VzZXI=" | base64 -d
```

---

### PowerShell

```powershell
[Text.Encoding]::UTF8.GetString(
    [Convert]::FromBase64String("ZmNnX3VzZXI=")
)
```

Resultado:

```text
fcg_user
```

# 🧪 Testando a Conexão

Criar um cliente PostgreSQL temporário.

```bash
kubectl run postgres-client \
  --rm -it \
  --image=postgres:16 \
  -n fcg-platform \
  -- bash
```

Dentro do container execute:

```bash
psql -h postgres -U fcg_user
```

Informe a senha cadastrada no Secret.

Exemplo:

```text
changeme
```

Resultado esperado:

```text
psql (16.x)

postgres=#
```

Isso confirma que:

- ✅ O Deployment está funcionando
- ✅ O Service está resolvendo corretamente
- ✅ O Secret foi carregado
- ✅ O PostgreSQL está aceitando conexões

# 🛠 Comandos Úteis

Listar todos os recursos.

```bash
kubectl get all -n fcg-platform
```

Listar ConfigMaps.

```bash
kubectl get configmaps -n fcg-platform
```

Listar Secrets.

```bash
kubectl get secrets -n fcg-platform
```

Listar PVCs.

```bash
kubectl get pvc -n fcg-platform
```

Listar Deployments.

```bash
kubectl get deployments -n fcg-platform
```

Listar Pods.

```bash
kubectl get pods -n fcg-platform
```

Listar Services.

```bash
kubectl get services -n fcg-platform
```

Visualizar logs.

```bash
kubectl logs <pod> -n fcg-platform
```

Detalhes de um recurso.

```bash
kubectl describe pod <pod> -n fcg-platform
```

# 🗑 Removendo os Recursos

Remover apenas o PostgreSQL.

```bash
kubectl delete -f k8s/infrastructure/postgres/
```

Remover toda a plataforma.

```bash
kubectl delete namespace fcg-platform
```
