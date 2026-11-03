# 🐘 4º passo: Implantação do PostgreSQL no Amazon EKS

**Projeto:** FIAP FCG  
**Cluster:** `fcg-platform`  
**Região AWS:** Virgínia do Norte (`us-east-1`)  
**Namespace Kubernetes:** `fcg-platform`  
**Banco:** PostgreSQL 16.9  
**Armazenamento:** PVC de 1 GiB, StorageClass `gp2`

---

## 1. Pré-requisitos

Antes de começar, confirme que você possui:

- [ ] AWS CLI instalado e autenticado.
- [ ] `kubectl` instalado.
- [ ] `eksctl` instalado.
- [ ] Acesso ao cluster EKS e permissões necessárias.
- [ ] Cluster EKS ativo.
- [ ] Pelo menos um nó de trabalho com status `Ready`.
- [ ] Repositório `fcg-platform` atualizado.

No PowerShell, acesse a pasta dos manifests:

```powershell
cd "C:\REPOSITORIO\4. FIAP\fcg-platform\k8s"
```

### 1.1. Confirmar a identidade AWS

```powershell
aws sts get-caller-identity
```

Verifique se o cluster está ativo:

```powershell
aws eks describe-cluster `
  --name fcg-platform `
  --region us-east-1 `
  --query "cluster.status" `
  --output text
```

Resultado esperado:

```text
ACTIVE
```

### 1.2. Atualizar o kubeconfig

Configure o acesso local ao cluster:

```powershell
aws eks update-kubeconfig `
  --name fcg-platform `
  --region us-east-1
```

Valide o contexto e os nós:

```powershell
kubectl config current-context
kubectl get nodes
```

Os nós devem estar disponíveis com status `Ready`.

---

## 2. Preparar o armazenamento persistente

O PostgreSQL utiliza um PVC (_PersistentVolumeClaim_) para armazenar os dados fora do ciclo de vida do contêiner.

Na infraestrutura criada manualmente, o provisionamento do volume EBS depende do **EBS CSI Driver**, que permite ao Kubernetes solicitar e gerenciar volumes na AWS.

### 2.1. Verificar se o EBS CSI Driver está instalado

Consulte o status do complemento:

```powershell
aws eks describe-addon `
  --cluster-name fcg-platform `
  --region us-east-1 `
  --addon-name aws-ebs-csi-driver `
  --query "addon.status" `
  --output text
```

Resultado esperado:

```text
ACTIVE
```

Se retornar `ResourceNotFoundException`, significa que o complemento ainda não está instalado.

Confira também os Pods e as StorageClasses:

```powershell
kubectl get pods -n kube-system
kubectl get storageclass
kubectl get storageclass gp2
```

A StorageClass utilizada pelo PostgreSQL é `gp2`, com provisionador `ebs.csi.aws.com`.

### 2.2. Identificar a função IAM do driver

A função IAM utilizada pelo EBS CSI Driver é:

**Nome:** `AmazonEKS_EBS_CSI_DriverRole`

**ARN:**

```text
arn:aws:iam::742057128217:role/AmazonEKS_EBS_CSI_DriverRole
```

**Política gerenciada associada:**

```text
AmazonEBSCSIDriverPolicyV2
```

Essa função concede ao driver as permissões necessárias para provisionar e gerenciar volumes EBS.

### 2.3. Associar o provedor OIDC ao cluster

O EKS utiliza o provedor OIDC para permitir que uma aplicação executada dentro do Kubernetes assuma uma função IAM por meio de uma Service Account.

Execute:

```powershell
eksctl utils associate-iam-oidc-provider `
  --cluster fcg-platform `
  --region us-east-1 `
  --approve
```

O comando associa o provedor OIDC ao cluster, caso ainda não exista.

### 2.4. Obter o identificador OIDC atual

Cada cluster EKS possui seu próprio identificador OIDC. Se o cluster for excluído e criado novamente, esse identificador poderá mudar.

Execute no PowerShell:

```powershell
$OIDCIssuer = aws eks describe-cluster `
  --name fcg-platform `
  --region us-east-1 `
  --query "cluster.identity.oidc.issuer" `
  --output text

$OIDC_ID = ($OIDCIssuer -split "/")[-1]

Write-Host "URL do provedor OIDC: $OIDCIssuer"
Write-Host "ID OIDC do cluster atual: $OIDC_ID"
```

O comando consulta os detalhes do cluster, obtém a URL do provedor OIDC e extrai seu identificador.

O resultado será semelhante a:

```text
URL do provedor OIDC: https://oidc.eks.us-east-1.amazonaws.com/id/IDENTIFICADOR
ID OIDC do cluster atual: IDENTIFICADOR
```

O identificador acima é ilustrativo. Utilize sempre o valor retornado pelo seu cluster atual.

### 2.5. Atualizar a relação de confiança da função IAM

A função `AmazonEKS_EBS_CSI_DriverRole` precisa confiar no provedor OIDC do cluster atual.

Se o cluster foi recriado, a relação de confiança poderá continuar apontando para o identificador antigo.

No Console AWS:

1. Acesse o serviço **IAM**.
2. No menu lateral, selecione **Funções**.
3. Pesquise e abra `AmazonEKS_EBS_CSI_DriverRole`.
4. Acesse a aba **Relações de confiança**.
5. Clique em **Editar política de confiança**.
6. Substitua as ocorrências do identificador OIDC antigo pelo valor de `$OIDC_ID`.
7. Clique em **Atualizar política de confiança**.

O identificador deve ser atualizado nos três pontos:

- `Principal.Federated`
- Condição `aud`
- Condição `sub`

Exemplo de política de confiança:

Substitua `ID_OIDC_DO_CLUSTER_ATUAL` pelo identificador obtido na etapa anterior.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::742057128217:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/ID_OIDC_DO_CLUSTER_ATUAL"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.us-east-1.amazonaws.com/id/ID_OIDC_DO_CLUSTER_ATUAL:aud": "sts.amazonaws.com",
          "oidc.eks.us-east-1.amazonaws.com/id/ID_OIDC_DO_CLUSTER_ATUAL:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }
  ]
}
```

Preserve os seguintes valores:

| Campo         | Valor                                                     |
| ------------- | --------------------------------------------------------- |
| `aud`         | `sts.amazonaws.com`                                       |
| `sub`         | `system:serviceaccount:kube-system:ebs-csi-controller-sa` |
| Provedor OIDC | Identificador do cluster atual                            |

**Importante:** não altere os valores de `aud` e `sub`. Apenas atualize o identificador OIDC.

Essa atualização deve ser repetida se o cluster for recriado e seu identificador OIDC mudar.

### 2.6. Instalar o EBS CSI Driver

Depois de associar o OIDC e atualizar a relação de confiança, instale o complemento:

```powershell
aws eks create-addon `
  --cluster-name fcg-platform `
  --region us-east-1 `
  --addon-name aws-ebs-csi-driver `
  --service-account-role-arn arn:aws:iam::742057128217:role/AmazonEKS_EBS_CSI_DriverRole
```

Aguarde a conclusão da instalação.

### 2.7. Validar a instalação

Consulte o status do complemento:

```powershell
aws eks describe-addon `
  --cluster-name fcg-platform `
  --region us-east-1 `
  --addon-name aws-ebs-csi-driver `
  --query "addon.status" `
  --output text
```

Resultado esperado:

```text
ACTIVE
```

Confira os Pods do driver e a StorageClass:

```powershell
kubectl get pods -n kube-system
kubectl get storageclass
kubectl get storageclass gp2
```

Com o driver instalado e a StorageClass disponível, prossiga para a criação do PostgreSQL.

---

## 3. Criar os recursos do PostgreSQL

Os manifests ficam organizados na seguinte estrutura:

```text
k8s/
├── namespace.yaml
└── infrastructure/
    └── postgres/
        ├── configmap.yaml
        ├── deployment.yaml
        ├── pvc.yaml
        ├── secret.yaml
        └── service.yaml
```

### 3.1. Criar o namespace

```powershell
kubectl apply -f namespace.yaml
```

### 3.2. Aplicar os manifests

Execute os comandos na ordem abaixo:

```powershell
kubectl apply -f infrastructure/postgres/configmap.yaml

kubectl apply -f infrastructure/postgres/secret.yaml

kubectl apply -f infrastructure/postgres/pvc.yaml

kubectl apply -f infrastructure/postgres/deployment.yaml

kubectl apply -f infrastructure/postgres/service.yaml
```

Responsabilidade de cada arquivo:

| Arquivo           | Responsabilidade                                |
| ----------------- | ----------------------------------------------- |
| `configmap.yaml`  | Configurações não sensíveis do PostgreSQL       |
| `secret.yaml`     | Usuário e senha do banco                        |
| `pvc.yaml`        | Solicitação do volume persistente de 1 GiB      |
| `deployment.yaml` | Criação e gerenciamento do contêiner PostgreSQL |
| `service.yaml`    | Acesso interno ao banco pela porta 5432         |

**Atenção:** o Secret deve conter as credenciais esperadas pelo Deployment. Não publique senhas reais no repositório Git.

### 3.3. Conferir o volume persistente

Verifique se o PVC foi provisionado:

```powershell
kubectl get pvc -n fcg-platform
```

O PVC `postgres-pvc` deve apresentar o status `Bound`.

Se permanecer `Pending`, consulte os detalhes:

```powershell
kubectl describe pvc postgres-pvc -n fcg-platform
```

Problemas de provisionamento podem estar relacionados ao EBS CSI Driver, à função IAM ou à StorageClass.

---

## 4. Acompanhar a inicialização

Depois de aplicar os manifests, acompanhe a inicialização do Deployment:

```powershell
kubectl rollout status deployment/postgres `
  -n fcg-platform `
  --timeout=180s
```

Confira os Pods:

```powershell
kubectl get pods -n fcg-platform
```

Resultado esperado:

```text
NAME                       READY   STATUS    RESTARTS
postgres-xxxxxxxxxx-xxxxx  1/1     Running   0
```

Confira o Service:

```powershell
kubectl get svc -n fcg-platform
```

O serviço `postgres` deve estar disponível na porta `5432/TCP`.

Consulte os logs:

```powershell
kubectl logs deployment/postgres -n fcg-platform
```

Se o Pod estiver em `CrashLoopBackOff`, consulte os logs da execução anterior:

```powershell
kubectl logs deployment/postgres `
  -n fcg-platform `
  --previous
```

Para investigar eventos e problemas de configuração:

```powershell
kubectl describe pod `
  -l app.kubernetes.io/name=postgres `
  -n fcg-platform
```

---

## 5. Testar a conexão com o PostgreSQL

O Service utiliza o tipo `ClusterIP`, portanto o banco não fica diretamente exposto à internet.

Para testar o acesso localmente, abra um túnel temporário:

```powershell
kubectl port-forward `
  svc/postgres `
  5432:5432 `
  -n fcg-platform
```

Com o túnel ativo, uma aplicação cliente poderá acessar o banco pelo endereço:

```text
localhost:5432
```

Utilize as credenciais configuradas no Secret do Kubernetes.

Para encerrar o túnel, pressione `Ctrl + C` no terminal.

---

### ➡️ Próximo passo

Com o PostgreSQL implantado e validado, prossiga para [5. Configuração do pgAdmin](./5-pg-admin.md).
