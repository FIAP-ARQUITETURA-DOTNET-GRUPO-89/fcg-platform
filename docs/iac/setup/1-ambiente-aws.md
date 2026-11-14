# 🛠️ Configuração do ambiente AWS

**Projeto:** FIAP FCG  
**Cluster:** `fcg-platform`  
**Região AWS:** Virgínia do Norte (`us-east-1`)  
**Sistema operacional:** Windows  
**Terminal:** PowerShell

## 📋 1. Pré-requisitos

As ferramentas utilizadas no projeto são:

| Ferramenta | Finalidade                                    |
| ---------- | --------------------------------------------- |
| AWS CLI    | Autenticação e gerenciamento dos recursos AWS |
| kubectl    | Comunicação e gerenciamento do Kubernetes     |
| eksctl     | Utilitário para operações em clusters EKS     |
| Terraform  | Provisionamento da infraestrutura como código |

## 📦 2. Instalar as ferramentas

### 2.1. AWS CLI

Instale pelo Windows Package Manager:

```powershell
winget install -e --id Amazon.AWSCLI
```

Feche e abra o PowerShell novamente e confirme a instalação:

```powershell
aws --version
```

### 2.2. kubectl

Instale utilizando o Winget:

```powershell
winget install -e --id Kubernetes.kubectl
```

Confirme a instalação:

```powershell
kubectl version --client
```

### 2.3. eksctl

Baixe a versão para Windows AMD64 na documentação oficial:

[https://eksctl.io/installation/](https://eksctl.io/installation/)

Extraia o executável `eksctl.exe` e adicione sua pasta à variável de ambiente `PATH`.

Confirme a instalação:

```powershell
eksctl version
```

### 2.4. Terraform

Instale pelo Windows Package Manager:

```powershell
winget install -e --id Hashicorp.Terraform
```

Confirme a instalação:

```powershell
terraform version
```

## ☁️ 3. Configurar o acesso à AWS

### 3.1. Autenticar na AWS

Execute:

```powershell
aws login
```

Conclua a autenticação no navegador.

Confirme a identidade autenticada:

```powershell
aws sts get-caller-identity
```

### 3.2. Configurar a região padrão

O projeto utiliza a região `us-east-1`:

```powershell
aws configure set region us-east-1
```

Confirme a configuração:

```powershell
aws configure get region
```

O resultado esperado é:

```text
us-east-1
```

## ☸️ 4. Configurar o acesso ao cluster EKS

Após o provisionamento da infraestrutura pelo Terraform, atualize o contexto local do Kubernetes:

```powershell
aws eks update-kubeconfig --region us-east-1 --name fcg-platform
```

Confirme o contexto ativo:

```powershell
kubectl config current-context
```

## 🛡️ 5. Cuidados de segurança e custos

- **Credenciais:** não compartilhe chaves de acesso, tokens ou senhas. Evite armazenar credenciais diretamente nos arquivos do projeto.
- **Permissões:** utilize apenas as permissões AWS necessárias para executar as atividades do projeto.
- **Custos AWS:** recursos como EKS, instâncias EC2, volumes EBS, Load Balancers e transferência de dados podem gerar cobranças.
- **Ambiente de estudo:** evite manter recursos provisionados quando não estiver utilizando o ambiente.
- **Encerramento:** ao finalizar os estudos, execute o `terraform destroy` no diretório correto para remover a infraestrutura gerenciada pelo Terraform.
- **Conferência:** após a destruição, verifique no Console AWS se não permaneceram recursos cobrados, como volumes EBS, Load Balancers ou endereços IP públicos.

## ➡️ 6. Próximo passo

Acesse o [README do Terraform](../terraform/README.md) para o processo de provisionamento e gerenciamento da infraestrutura AWS.
