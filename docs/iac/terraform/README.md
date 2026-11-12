# Terraform na AWS

Este guia provisiona o cluster EKS e o grupo de nós EC2 descritos nos
documentos manuais:

- [Criação do cluster EKS](../manual/2-cluster-eks.md)
- [Criação do grupo de nós EC2](../manual/3-nos-ec2.md)

O Terraform utiliza a VPC padrão da conta, as sub-redes disponíveis nessa VPC
e cria:

- Cluster EKS `fcg-platform` na região `us-east-1`.
- Endpoint público e privado do Kubernetes.
- Complementos `vpc-cni`, `coredns` e `kube-proxy`.
- Provedor OIDC do cluster e role IAM do EBS CSI Driver.
- Complemento `aws-ebs-csi-driver` para provisionar volumes EBS dos PVCs.
- Grupo de nós `fcg-workers`.
- Instâncias `m7i-flex.large` com disco EBS de 20 GiB.
- Escalabilidade inicial de 1 nó, com mínimo e máximo iguais a 1.
- Roles IAM separadas para o cluster e para os nós.

## Escolha um único fluxo

Este projeto oferece duas formas alternativas de criar a infraestrutura:

1. **Manual:** siga os documentos em `docs/iac/manual`, usando o Console AWS,
   AWS CLI, `eksctl` e `kubectl`.
2. **Terraform:** siga este documento do início ao fim.

Não misture os fluxos para o mesmo cluster. Se o cluster e seus recursos forem
criados pelo Terraform, não execute manualmente as etapas equivalentes de
OIDC, IAM ou addons. Se forem criados manualmente, não execute `terraform
apply` sobre esses mesmos recursos.

## Pré-requisitos

1. Instale o AWS CLI, conforme a seção de AWS CLI do
   [primeiro guia manual](../manual/1-aws-cli-e-eksctl.md). O `eksctl` não é
   necessário para executar o Terraform.
2. Instale o Terraform.
3. Autentique-se na conta AWS:

   ```powershell
   aws login
   aws configure set region us-east-1
   aws sts get-caller-identity
   ```

4. Confirme que a conta possui uma VPC padrão com sub-redes suficientes para o
   cluster.
5. Garanta permissões para criar EKS, EC2, IAM, OIDC e os complementos do EKS.

> O Terraform não cria uma VPC. Ele reutiliza a VPC padrão e todas as sub-redes
> disponíveis nela.

## Estrutura do projeto

O módulo é mantido propositalmente simples:

```text
iac/terraform/aws/
├── versions.tf            # versão do Terraform e provider AWS
├── providers.tf           # configuração dos providers AWS e Helm
├── variables.tf           # parâmetros configuráveis
├── data.tf                # VPC e sub-redes existentes
├── iam.tf                 # roles e políticas IAM
├── main.tf                # cluster EKS e addons
├── node-group.tf          # grupo de nós EC2
├── outputs.tf             # valores exibidos após o apply
└── .terraform.lock.hcl    # versões e hashes do provider
```

## Inicializar o projeto

Abra o PowerShell na pasta do módulo AWS:

```powershell
cd "..\fcg-platform\iac\terraform\aws"
terraform init
```

## Revisar o plano

Valide as alterações antes de criar recursos:

```powershell
terraform fmt -check
terraform validate
terraform plan
```

## Criar a infraestrutura

Depois de revisar o plano:

```powershell
terraform apply
```

Digite `yes` quando solicitado. A criação do cluster e do grupo de nós pode
levar vários minutos.

Para aprovar sem confirmação interativa, use somente após revisar o plano:

```powershell
terraform apply -auto-approve
```

## Validar o ambiente

Consulte os outputs:

```powershell
terraform output
```

Configure o contexto do Kubernetes e valide o nó:

```powershell
aws eks update-kubeconfig --region us-east-1 --name fcg-platform
kubectl config current-context
kubectl get nodes
kubectl get pods -A
```

O nó deve aparecer como `Ready`.

Verifique também os addons:

```powershell
aws eks describe-addon `
  --region us-east-1 `
  --cluster-name fcg-platform `
  --addon-name coredns `
  --query "addon.{status:status,health:health.issues}"
```

O status esperado é `ACTIVE`.

Valide o addon:

```powershell
aws eks describe-addon `
  --region us-east-1 `
  --cluster-name fcg-platform `
  --addon-name aws-ebs-csi-driver `
  --query "addon.{status:status,health:health.issues}"
```

O status esperado é `ACTIVE`. Depois disso, os PVCs que usam a StorageClass
`gp2` poderão provisionar volumes EBS para o PostgreSQL.

## Remover os recursos

Quando o ambiente não for mais necessário, remova os recursos gerenciados pelo
Terraform:

```powershell
terraform destroy
```

Confirme `yes` e depois verifique no console da AWS se não restaram volumes,
endereços IP, Load Balancers ou outros recursos criados fora deste módulo.
