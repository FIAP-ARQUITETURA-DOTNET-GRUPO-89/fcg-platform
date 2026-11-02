# Terraform na AWS

Este guia provisiona o cluster EKS e o grupo de nós EC2 descritos nos
documentos manuais:

- [Criação do cluster EKS](../manual/2-cluster-eks.md)
- [Criação do grupo de nós EC2](../manual/3-nos-ec2.md)

O Terraform utiliza a VPC padrão da conta, as sub-redes disponíveis nessa VPC
e cria:

- Cluster EKS `fcg-platform` na região `sa-east-1`.
- Endpoint público e privado do Kubernetes.
- Complementos `vpc-cni`, `coredns` e `kube-proxy`.
- Provedor OIDC do cluster e role IAM do EBS CSI Driver.
- Complemento `aws-ebs-csi-driver` para provisionar volumes EBS dos PVCs.
- Grupo de nós `fcg-workers`.
- Instâncias `t3.small` com disco EBS de 20 GiB.
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
   aws configure set region sa-east-1
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
├── providers.tf           # configuração do provider AWS
├── variables.tf           # parâmetros configuráveis
├── data.tf                # VPC e sub-redes existentes
├── iam.tf                 # roles e políticas IAM
├── main.tf                # cluster EKS e addons
├── node-group.tf          # grupo de nós EC2
├── outputs.tf             # valores exibidos após o apply
└── .terraform.lock.hcl    # versões e hashes do provider
```

O Terraform não exige um arquivo por recurso. Todos os arquivos `.tf` no
diretório formam um único módulo. A separação em `modules` e `environments`
é útil quando existem componentes reutilizáveis ou ambientes como
desenvolvimento, homologação e produção. Elas não são necessárias neste
projeto porque existe apenas uma configuração AWS simples.

## Inicializar o projeto

Abra o PowerShell na pasta do módulo AWS:

```powershell
cd "C:\REPOSITORIO\4. FIAP\fcg-platform\iac\terraform\aws"
terraform init
```

## Revisar o plano

Valide as alterações antes de criar recursos:

```powershell
terraform fmt -check
terraform validate
terraform plan
```

Para alterar os CIDRs autorizados no endpoint público, sem editar os arquivos:

```powershell
terraform plan `
  -var='cluster_public_access_cidrs=["SEU_IP_PUBLICO/32"]'
```

O valor padrão `0.0.0.0/0` reproduz o procedimento manual, mas permite acesso
ao endpoint público a partir de qualquer origem IPv4. Restrinja-o ao IP
confiável sempre que possível.

## Criar a infraestrutura

Depois de revisar o plano:

```powershell
terraform apply
```

Digite `yes` quando solicitado. A criação do cluster e do grupo de nós pode
levar vários minutos.

O grupo de nós não depende da conclusão dos addons. Isso é intencional: o
CoreDNS precisa de nós disponíveis para agendar seus Pods. Depois que o grupo
de nós estiver `Active`, o EKS deverá deixar o CoreDNS como `ACTIVE`.

Para aprovar sem confirmação interativa, use somente após revisar o plano:

```powershell
terraform apply -auto-approve
```

### Erro `EntityAlreadyExists` na role do EBS CSI

Se aparecer o erro:

```text
EntityAlreadyExists: Role with name AmazonEKS_EBS_CSI_DriverRole already exists
```

essa role foi criada anteriormente fora do state atual do Terraform. Isso
ocorre, por exemplo, quando o EBS CSI Driver foi configurado manualmente.
Importe a role existente para o state antes de tentar o `apply` novamente:

```powershell
terraform import aws_iam_role.ebs_csi `
  "AmazonEKS_EBS_CSI_DriverRole"
```

Depois, revise o plano:

```powershell
terraform plan
```

Se o plano mostrar apenas ajustes na configuração da role ou do EBS CSI
Driver, execute:

```powershell
terraform apply
```

Não exclua a role manualmente apenas para contornar o erro. Ela pode estar
sendo utilizada pelo addon `aws-ebs-csi-driver` ou por recursos existentes.

## Validar o ambiente

Consulte os outputs:

```powershell
terraform output
```

Configure o contexto do Kubernetes e valide o nó:

```powershell
aws eks update-kubeconfig --region sa-east-1 --name fcg-platform
kubectl config current-context
kubectl get nodes
kubectl get pods -A
```

O nó deve aparecer como `Ready`.

Verifique também os addons:

```powershell
aws eks describe-addon `
  --region sa-east-1 `
  --cluster-name fcg-platform `
  --addon-name coredns `
  --query "addon.{status:status,health:health.issues}"
```

O status esperado é `ACTIVE`.

O Terraform também configura automaticamente os recursos necessários para
volumes persistentes no EKS:

- Provedor OIDC associado ao cluster.
- Role IAM vinculada à conta de serviço do EBS CSI Driver.
- Política `AmazonEBSCSIDriverPolicy`.
- Addon `aws-ebs-csi-driver`.

Valide o addon:

```powershell
aws eks describe-addon `
  --region sa-east-1 `
  --cluster-name fcg-platform `
  --addon-name aws-ebs-csi-driver `
  --query "addon.{status:status,health:health.issues}"
```

O status esperado é `ACTIVE`. Depois disso, os PVCs que usam a StorageClass
`gp2` poderão provisionar volumes EBS para o PostgreSQL.

### Recuperação após falha do addon

Se uma execução anterior tiver terminado com o CoreDNS em `DEGRADED` por
`InsufficientNumberOfReplicas`, aplique novamente depois desta correção. O
node group será criado sem aguardar o CoreDNS:

```powershell
terraform plan
terraform apply
```

Não execute dois `terraform apply` simultaneamente. Se o plano indicar que o
addon será recriado, isso é esperado quando ele ficou registrado
incompletamente após o timeout; revise o plano e confirme que ele não propõe
remover o cluster ou a VPC.

## Alterar configurações

Os valores podem ser sobrescritos por variáveis:

```powershell
terraform plan `
  -var='kubernetes_version=1.37' `
  -var='node_instance_types=["t3.small"]' `
  -var='node_desired_size=1'
```

Para uso recorrente, crie um arquivo local `terraform.tfvars` na pasta
`iac/terraform/aws`. Esse arquivo não deve ser versionado, pois pode conter
configurações específicas do ambiente.

## Remover os recursos

Quando o ambiente não for mais necessário, remova os recursos gerenciados pelo
Terraform:

```powershell
terraform destroy
```

Confirme `yes` e depois verifique no console da AWS se não restaram volumes,
endereços IP, Load Balancers ou outros recursos criados fora deste módulo.
