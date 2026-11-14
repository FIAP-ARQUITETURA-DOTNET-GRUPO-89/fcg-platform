# ☁️ Terraform na AWS

Este guia apresenta o processo de provisionamento e gerenciamento da infraestrutura AWS do projeto FIAP FCG utilizando Terraform.

O Terraform utiliza a VPC padrão da conta, as sub-redes disponíveis nessa VPC e cria:

- Cluster EKS `fcg-platform` na região `us-east-1`.
- Endpoint público e privado do Kubernetes.
- Complementos `vpc-cni`, `coredns` e `kube-proxy`.
- Provedor OIDC do cluster e role IAM do EBS CSI Driver.
- Complemento `aws-ebs-csi-driver` para provisionar volumes EBS dos PVCs.
- Grupo de nós `fcg-workers`.
- Instâncias `m7i-flex.large` com disco EBS de 20 GiB.
- Escalabilidade inicial de 1 nó, com mínimo e máximo iguais a 1.
- Roles IAM separadas para o cluster e para os nós.

> **Atenção:** o Terraform não cria uma VPC. Ele reutiliza a VPC padrão e as sub-redes disponíveis nela.

## 📋 Pré-requisitos

1. Instale e configure as ferramentas descritas no guia de [Configuração do ambiente AWS](../setup/1-ambiente-aws.md).
2. Autentique-se na conta AWS:

   ```powershell
   aws login
   ```

3. Configure a região padrão:

   ```powershell
   aws configure set region us-east-1
   ```

4. Confirme a identidade autenticada:

   ```powershell
   aws sts get-caller-identity
   ```

## 📁 Estrutura do projeto

O módulo é mantido propositalmente simples:

```text
iac/terraform/aws/
├── versions.tf           # versão do Terraform e provider AWS
├── providers.tf          # configuração dos providers AWS e Helm
├── variables.tf          # parâmetros configuráveis
├── data.tf               # VPC e sub-redes existentes
├── iam.tf                # roles e políticas IAM
├── main.tf               # cluster EKS e addons
├── node-group.tf         # grupo de nós EC2
├── outputs.tf             # valores exibidos após o apply
└── .terraform.lock.hcl   # versões e hashes do provider
```

## 🚀 Inicializar o projeto

Abra o PowerShell na pasta do módulo AWS:

```powershell
cd "C:\REPOSITORIO\4. FIAP\fcg-platform\iac\terraform\aws"
```

Inicialize o Terraform:

```powershell
terraform init
```

## 🔎 Revisar o plano

Valide os arquivos e revise os recursos que serão criados:

```powershell
terraform fmt -check
terraform validate
terraform plan
```

## 🏗️ Criar a infraestrutura

Depois de revisar o plano, execute:

```powershell
terraform apply
```

Digite `yes` quando solicitado. A criação do cluster e do grupo de nós pode levar vários minutos.

Para aprovar sem confirmação interativa, utilize somente após revisar o plano:

```powershell
terraform apply -auto-approve
```

## ✅ Validar o ambiente

Consulte os outputs:

```powershell
terraform output
```

Configure o contexto do Kubernetes e valide o acesso ao cluster:

```powershell
aws eks update-kubeconfig --region us-east-1 --name fcg-platform
kubectl config current-context
kubectl get nodes
kubectl get pods -A -o wide
```

O nó disponível deve apresentar o status `Ready`.

## 🗑️ Remover os recursos

Quando o ambiente não for mais necessário, remova os recursos gerenciados pelo Terraform:

```powershell
terraform destroy
```

Confirme com `yes` e aguarde a conclusão da operação.

### Conferir a remoção no Console AWS

Após finalizar o `terraform destroy`, acesse o [Console AWS](https://console.aws.amazon.com/) pelo navegador, selecione a região `us-east-1` e confira se não restaram recursos do projeto:

- **Amazon EKS:** verifique se o cluster `fcg-platform` foi excluído.
- **Amazon EC2:** confira se não existem instâncias em execução ou pendentes de encerramento.
- **Volumes EBS:** verifique se não restaram volumes vinculados ao projeto.
- **Load Balancers:** confira se não existem balanceadores de carga associados ao cluster.

Caso algum recurso tenha permanecido, avalie sua origem e faça a remoção manual pelo Console AWS, se não for mais necessário.

**Atenção aos custos:** recursos como EKS, EC2, EBS e Load Balancers podem gerar cobranças enquanto estiverem provisionados, mesmo que não estejam sendo utilizados.

## ➡️ Próximo passo

1. **Opcional:** acesse [0 - Configuração do Headlamp](./0-headlamp.md) para configurar uma interface visual de gerenciamento do Kubernetes.
2. **Próximo passo:** siga para [1 - Implantação da infraestrutura Kubernetes](./1-infraestrutura.md) para instalar os componentes necessários ao funcionamento da plataforma.
