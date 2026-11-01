# 📘 Runbook — PostgreSQL no AWS EKS

Projeto: FIAP FCG\
Cluster: `fcg-platform`\
Região AWS: São Paulo (`sa-east-1`)\
Namespace Kubernetes: `fcg-platform`\
Banco: PostgreSQL 16.9\
Armazenamento: PVC de 1 GiB, StorageClass `gp2`

## 1. Pré-requisitos

Antes de começar, confirme que você tem:

- AWS CLI instalado e autenticado.
- `kubectl` instalado.
- `eksctl` instalado.
- Acesso ao cluster EKS e permissões para executar os comandos.
- O repositório `fcg-platform` atualizado.
- O cluster EKS e pelo menos um nó de trabalho disponíveis.

No PowerShell, entre na pasta dos manifests:

```
cd "C:\REPOSITORIO\4. FIAP\fcg-platform\k8s"
```

### 1.1. Confirmar a identidade AWS

```
aws sts get-caller-identity
```

Confirme a região e o status do cluster:

```
aws eks describe-cluster `
  --name fcg-platform `
  --region sa-east-1 `
  --query "cluster.status" `
  --output text
```

O resultado esperado é:

```
ACTIVE
```

### 1.2. Atualizar a configuração local do Kubernetes

```
aws eks update-kubeconfig `
  --name fcg-platform `
  --region sa-east-1
```

Valide o acesso:

```
kubectl get nodes
```

O nó deve aparecer com status `Ready`.

## 2. Preparar o armazenamento persistente

O PostgreSQL utiliza um PVC (PersistentVolumeClaim) para armazenar os dados fora do ciclo de vida do contêiner.

O armazenamento persistente é provisionado na AWS por meio do EBS CSI Driver.

### 2.1. Verificar se o EBS CSI Driver está instalado

```
aws eks describe-addon `
  --cluster-name fcg-platform `
  --region sa-east-1 `
  --addon-name aws-ebs-csi-driver `
  --query "addon.status" `
  --output text
```

O resultado esperado é:

```
ACTIVE
```

Se retornar `ResourceNotFoundException`, significa que o complemento ainda não está instalado no cluster.

Confira também os recursos do driver:

```
kubectl get pods -n kube-system
kubectl get storageclass
```

A StorageClass utilizada pelo PostgreSQL é `gp2`, com provisionador `ebs.csi.aws.com`.

Confira se ela existe:

```
kubectl get storageclass gp2
```

### 2.2. Recursos IAM do driver

A Função do IAM criada para o driver é:

Nome: `AmazonEKS_EBS_CSI_DriverRole`

ARN:

```
arn:aws:iam::742057128217:role/AmazonEKS_EBS_CSI_DriverRole
```

Política gerenciada associada:

```
AmazonEBSCSIDriverPolicyV2
```

Essa função permite que o EBS CSI Driver realize as operações necessárias para provisionar e gerenciar volumes EBS.

### 2.3. Associar o provedor OIDC ao cluster

O EKS utiliza o provedor OIDC para permitir que uma aplicação executada dentro do Kubernetes assuma uma Função do IAM por meio de uma Service Account.

Sempre que o cluster for criado novamente, associe o provedor OIDC do novo cluster.

Execute:

```
eksctl utils associate-iam-oidc-provider `
  --cluster fcg-platform `
  --region sa-east-1 `
  --approve
```

O comando cria o provedor OIDC para o cluster, caso ainda não exista.

### 2.4. Obter o ID OIDC do cluster atual

Importante: cada cluster EKS possui seu próprio identificador OIDC. Quando um cluster é excluído e criado novamente, esse identificador pode mudar.

Para descobrir o identificador atual, execute no PowerShell:

```
$OIDCIssuer = aws eks describe-cluster `
  --name fcg-platform `
  --region sa-east-1 `
  --query "cluster.identity.oidc.issuer" `
  --output text

$OIDC_ID = ($OIDCIssuer -split "/")[-1]

Write-Host "URL do provedor OIDC: $OIDCIssuer"
Write-Host "ID OIDC do cluster atual: $OIDC_ID"
```

O comando executa três etapas:

1. Consulta os detalhes do cluster EKS.
2. Obtém a URL do provedor OIDC.
3. Extrai somente o identificador que aparece depois de `/id/`.

O resultado será semelhante a:

```
URL do provedor OIDC: https://oidc.eks.sa-east-1.amazonaws.com/id/6E83E3D6F3050D3B4BF1DDF4A2D589C7

ID OIDC do cluster atual: 6E83E3D6F3050D3B4BF1DDF4A2D589C7
```

O identificador acima é apenas um exemplo de saída. Sempre utilize o valor retornado pelo seu cluster atual.

Guarde o valor de `$OIDC_ID`, pois ele será utilizado na próxima etapa.

### 2.5. Atualizar a relação de confiança da Função do IAM

A Função `AmazonEKS_EBS_CSI_DriverRole` precisa confiar no provedor OIDC do cluster atual.

Quando o cluster é excluído e recriado, a Função do IAM pode continuar existindo, mas sua relação de confiança poderá apontar para o identificador OIDC antigo.

Por isso, é necessário atualizar a relação de confiança.

Como atualizar pelo Console AWS:

1. Acesse o serviço IAM.
2. No menu lateral, clique em Funções.
3. Pesquise e abra `AmazonEKS_EBS_CSI_DriverRole`.
4. Acesse a aba Relações de confiança.
5. Clique em Editar política de confiança.
6. Localize o identificador OIDC antigo na política.
7. Substitua todas as ocorrências pelo valor de `$OIDC_ID` obtido na etapa anterior.
8. Clique em Atualizar política de confiança.

É necessário atualizar o identificador nos três pontos da política:

- `Principal.Federated`
- Condição `aud`
- Condição `sub`

Exemplo de política de confiança:

Substitua `ID_OIDC_DO_CLUSTER_ATUAL` pelo identificador obtido no PowerShell.

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::742057128217:oidc-provider/oidc.eks.sa-east-1.amazonaws.com/id/ID_OIDC_DO_CLUSTER_ATUAL"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.sa-east-1.amazonaws.com/id/ID_OIDC_DO_CLUSTER_ATUAL:aud": "sts.amazonaws.com",
          "oidc.eks.sa-east-1.amazonaws.com/id/ID_OIDC_DO_CLUSTER_ATUAL:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }
  ]
}
```

Atenção aos valores que devem ser preservados:

| Campo         | Valor                                                     |
| ------------- | --------------------------------------------------------- |
| `aud`         | `sts.amazonaws.com`                                       |
| `sub`         | `system:serviceaccount:kube-system:ebs-csi-controller-sa` |
| Provedor OIDC | Identificador do cluster atual                            |

Não substitua os valores de `aud` e `sub`. Apenas atualize o identificador OIDC.

Importante: essa atualização deve ser repetida sempre que o cluster EKS for excluído e recriado e seu identificador OIDC mudar. A mesma Função do IAM pode ser reutilizada.

### 2.6. Instalar o EBS CSI Driver

Depois de associar o OIDC e atualizar a relação de confiança, instale o complemento no cluster:

```
aws eks create-addon `
  --cluster-name fcg-platform `
  --region sa-east-1 `
  --addon-name aws-ebs-csi-driver `
  --service-account-role-arn arn:aws:iam::742057128217:role/AmazonEKS_EBS_CSI_DriverRole
```

Aguarde a instalação terminar.

### 2.7. Validar a instalação

Consulte o status do complemento:

```
aws eks describe-addon `
  --cluster-name fcg-platform `
  --region sa-east-1 `
  --addon-name aws-ebs-csi-driver `
  --query "addon.status" `
  --output text
```

O resultado esperado é:

```
ACTIVE
```

Verifique os Pods do driver:

```
kubectl get pods -n kube-system
```

Confira a StorageClass:

```
kubectl get storageclass
```

E confirme especificamente a `gp2`:

```
kubectl get storageclass gp2
```

Somente depois dessas verificações prossiga com a criação do PostgreSQL.

## 3. Criar os recursos do PostgreSQL

Os manifests ficam em:

```
k8s/
└── infrastructure/
    └── postgres/
        ├── configmap.yaml
        ├── deployment.yaml
        ├── pvc.yaml
        ├── secret.yaml
        └── service.yaml
```

O namespace é definido em `namespace.yaml`.

### 3.1. Criar o namespace

```
kubectl apply -f namespace.yaml
```

### 3.2. Aplicar as configurações

Execute os comandos na ordem abaixo:

```
kubectl apply -f infrastructure/postgres/configmap.yaml
kubectl apply -f infrastructure/postgres/secret.yaml
kubectl apply -f infrastructure/postgres/pvc.yaml
kubectl apply -f infrastructure/postgres/deployment.yaml
kubectl apply -f infrastructure/postgres/service.yaml
```

O que cada arquivo faz:

| Arquivo           | Responsabilidade                                |
| ----------------- | ----------------------------------------------- |
| `configmap.yaml`  | Configurações não sensíveis do PostgreSQL       |
| `secret.yaml`     | Usuário e senha do banco                        |
| `pvc.yaml`        | Solicitação do volume persistente de 1 GiB      |
| `deployment.yaml` | Criação e gerenciamento do contêiner PostgreSQL |
| `service.yaml`    | Acesso interno ao banco pela porta 5432         |

O Secret deve conter as credenciais esperadas pelo Deployment. Não publique senhas reais no repositório Git.

### 3.3. Conferir o volume persistente

```
kubectl get pvc -n fcg-platform
```

O PVC `postgres-pvc` deve ficar com status `Bound`.

Se permanecer `Pending`, verifique os detalhes:

```
kubectl describe pvc postgres-pvc -n fcg-platform
```

Problemas de provisionamento podem estar relacionados ao driver EBS CSI, à Função IAM ou à StorageClass.

## 4. Acompanhar a inicialização

Depois de aplicar os manifests, acompanhe o Deployment:

```
kubectl rollout status deployment/postgres `
  -n fcg-platform `
  --timeout=180s
```

Confira o Pod:

```
kubectl get pods -n fcg-platform
```

O resultado esperado é semelhante a:

```
NAME                       READY   STATUS    RESTARTS
postgres-xxxxxxxxxx-xxxxx  1/1     Running   0
```

Confira o serviço:

```
kubectl get svc -n fcg-platform
```

O serviço `postgres` deve existir na porta `5432/TCP`.

Confira os logs:

```
kubectl logs deployment/postgres -n fcg-platform
```

Se o Pod estiver em `CrashLoopBackOff`, consulte os logs do contêiner anterior:

```
kubectl logs deployment/postgres `
  -n fcg-platform `
  --previous
```

Para investigar eventos e problemas de configuração:

```
kubectl describe pod `
  -l app.kubernetes.io/name=postgres `
  -n fcg-platform
```

## 5. Testar a conexão com o PostgreSQL

O Service é do tipo `ClusterIP`, portanto o banco não fica diretamente exposto à internet.

Para testar o acesso localmente, abra um túnel temporário:

```
kubectl port-forward `
  svc/postgres `
  5432:5432 `
  -n fcg-platform
```

## 7. Encerrar o ambiente ao final do dia

Objetivo: evitar custos do cluster e dos nós quando você não estiver estudando.

Primeiro, confira quais recursos existem:

```
aws eks list-nodegroups `
  --cluster-name fcg-platform `
  --region sa-east-1

kubectl get pvc -n fcg-platform
kubectl get pv
```

Anote o nome do node group e os identificadores dos volumes que aparecem nos resultados.

### 7.1. Se pretende preservar o cluster

Se você quiser apenas parar de utilizar o ambiente, pode excluir o node group gerenciado pelo EKS:

```
eksctl delete nodegroup `
  --cluster fcg-platform `
  --name NOME_DO_NODEGROUP `
  --region sa-east-1
```

Substitua `NOME_DO_NODEGROUP` pelo nome real.

A exclusão do node group encerra as instâncias EC2 gerenciadas por ele. Porém, o cluster EKS continua existindo e continua gerando cobrança.

### 7.2. Se pretende excluir o cluster inteiro

Se você realmente quiser excluir o cluster para interromper a cobrança do plano de controle, faça isso somente depois de decidir o destino dos dados.

Antes de excluir:

1. Verifique se precisa dos dados do PostgreSQL.
2. Faça backup, se necessário.
3. Identifique o volume EBS associado ao PVC.
4. Verifique se existem Load Balancers, IPs públicos, volumes ou outros recursos criados pela aplicação.
5. Confirme quais recursos serão excluídos e quais poderão permanecer.

Não exclua manualmente a instância EC2 antes de identificar se ela pertence ao node group gerenciado pelo EKS. Prefira a exclusão do node group ou do cluster pelos mecanismos próprios do EKS.

A exclusão do cluster não deve ser considerada garantia de remoção de todos os recursos associados. Verifique os recursos remanescentes no Console AWS, especialmente volumes EBS e Load Balancers.

### 7.3. O que acontece com os dados?

O PVC `postgres-pvc` utiliza armazenamento persistente. Excluir um Pod ou Deployment não equivale a excluir o volume.

O comportamento de retenção depende da política de recuperação do PersistentVolume. Confira:

```
kubectl get pv
```

Se a política for `Delete`, o volume poderá ser excluído quando o PVC/PV for liberado. Se for `Retain`, o volume poderá continuar existindo e gerando cobrança.

Não exclua o PVC nem o volume sem saber se precisa dos dados.

Se não precisar preservar os dados do banco de testes, confirme que o volume pode ser descartado antes de limpar os recursos. Se precisar dos dados, faça backup ou planeje a preservação do volume antes da exclusão do cluster.

## 8. Amanhã: recriar o ambiente

Se você excluir o cluster inteiro, não será suficiente executar apenas os manifests do PostgreSQL. Será necessário recriar a infraestrutura.

### 8.1. Ordem de recriação

A sequência recomendada é:

1. Criar o cluster EKS na região `sa-east-1`.
2. Criar o node group gerenciado.
3. Atualizar o kubeconfig local.
4. Associar o provedor OIDC do novo cluster.
5. Obter o novo identificador OIDC pelo PowerShell.
6. Atualizar a relação de confiança da Função `AmazonEKS_EBS_CSI_DriverRole`.
7. Instalar o complemento `aws-ebs-csi-driver`.
8. Aguardar o complemento ficar `ACTIVE`.
9. Conferir a StorageClass `gp2`.
10. Aplicar o namespace e os manifests do PostgreSQL.
11. Verificar o PVC, o Pod e o Service.

### 8.2. Atualizar o kubeconfig

```
aws eks update-kubeconfig `
  --name fcg-platform `
  --region sa-east-1
```

### 8.3. Associar o provedor OIDC

```
eksctl utils associate-iam-oidc-provider `
  --cluster fcg-platform `
  --region sa-east-1 `
  --approve
```

### 8.4. Obter o novo ID OIDC

```
$OIDCIssuer = aws eks describe-cluster `
  --name fcg-platform `
  --region sa-east-1 `
  --query "cluster.identity.oidc.issuer" `
  --output text

$OIDC_ID = ($OIDCIssuer -split "/")[-1]

Write-Host "URL do provedor OIDC: $OIDCIssuer"
Write-Host "ID OIDC do cluster atual: $OIDC_ID"
```

Utilize o novo identificador retornado para atualizar a relação de confiança da Função `AmazonEKS_EBS_CSI_DriverRole`, conforme explicado na seção 2.5.

### 8.5. Instalar o EBS CSI Driver

```
aws eks create-addon `
  --cluster-name fcg-platform `
  --region sa-east-1 `
  --addon-name aws-ebs-csi-driver `
  --service-account-role-arn arn:aws:iam::742057128217:role/AmazonEKS_EBS_CSI_DriverRole
```

Confira o status:

```
aws eks describe-addon `
  --cluster-name fcg-platform `
  --region sa-east-1 `
  --addon-name aws-ebs-csi-driver `
  --query "addon.status" `
  --output text
```

O resultado esperado é `ACTIVE`.

Confira também:

```
kubectl get pods -n kube-system
kubectl get storageclass
```

Depois, execute novamente os comandos da seção 3.

Se os dados não precisarem ser preservados, o PostgreSQL poderá ser inicializado em um novo volume. Se quiser preservar os dados, será necessário planejar a recuperação do volume ou de um backup compatível.

## 9. Checklist de encerramento

- Salvar alterações no Git e confirmar que os manifests estão atualizados.
- Decidir se os dados do PostgreSQL precisam ser preservados.
- Fazer backup, caso necessário.
- Identificar node group, volumes EBS e recursos de rede.
- Excluir o node group ou o cluster, conforme o plano escolhido.
- Conferir se o cluster EKS foi excluído, caso esse seja o objetivo.
- Conferir volumes EBS, Load Balancers, IPs públicos e outros recursos remanescentes.
- Conferir o AWS Billing e os custos acumulados.

Lembrete: o orçamento e os alertas de cobrança ajudam a monitorar os gastos, mas não interrompem automaticamente os recursos. Verifique os recursos remanescentes após a limpeza.

## 10. Estado conhecido do ambiente

Na última execução validada:

- Cluster: `fcg-platform`
- Região: `sa-east-1`
- Namespace: `fcg-platform`
- PostgreSQL: `postgres:16.9`
- PVC: `postgres-pvc`, 1 GiB, `Bound`
- Service: `postgres`, porta 5432
- Deployment: `postgres`, rollout concluído
- Pod: `1/1 Running`, sem reinicializações
- EBS CSI: complemento instalado e Pods em inicialização durante a verificação anterior

Use os comandos de verificação antes de presumir que o estado permanece igual no próximo dia.
