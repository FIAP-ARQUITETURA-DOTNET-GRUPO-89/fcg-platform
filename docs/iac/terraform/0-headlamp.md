# 🖥️ Headlamp: gerenciamento visual do Kubernetes

Este guia apresenta a instalação e configuração do **Headlamp** no Windows para gerenciamento visual do cluster Kubernetes `fcg-platform`, provisionado na AWS EKS pelo Terraform.

O Headlamp permite visualizar e administrar recursos Kubernetes, como Pods, Deployments, Services, ConfigMaps, Secrets e Persistent Volumes, por meio de uma interface gráfica.

A ferramenta é executada localmente e utiliza o arquivo `kubeconfig` gerado pelo AWS CLI para acessar o cluster.

## Pré-requisitos

1. Windows com PowerShell.
2. AWS CLI instalado e configurado.
3. kubectl instalado.
4. Terraform aplicado e cluster EKS em funcionamento.
5. Permissões IAM e Kubernetes RBAC para acessar o cluster.

## Instalação

Abra o PowerShell e execute:

```powershell
winget install headlamp
```

Após a instalação, abra o **Headlamp** pelo menu Iniciar do Windows.

Documentação oficial: https://headlamp.dev/

## Autenticação na AWS

Antes de conectar ao cluster, autentique-se na conta AWS:

```powershell
aws login
```

Configure a região utilizada pelo projeto:

```powershell
aws configure set region us-east-1
```

Verifique a identidade autenticada:

```powershell
aws sts get-caller-identity
```

## Configuração do kubeconfig

O Headlamp utiliza o arquivo `kubeconfig` do Kubernetes para identificar e acessar os clusters disponíveis.

Gere ou atualize a configuração do cluster EKS:

```powershell
aws eks update-kubeconfig --region us-east-1 --name fcg-platform
```

Por padrão, o arquivo é armazenado em:

```text
C:\Users\SEU_USUARIO\.kube\config
```

Verifique se o arquivo foi criado:

```powershell
Test-Path "$HOME\.kube\config"
```

O resultado esperado é `True`.

## Validar a conexão com o cluster

Antes de abrir o Headlamp, valide o acesso pelo kubectl:

```powershell
kubectl config current-context
kubectl config get-contexts
kubectl get nodes
kubectl get pods -A
```

O nó EC2 deverá apresentar o status `Ready`, e os Pods deverão ser listados conforme os recursos existentes no cluster.

## Conectar o Headlamp ao EKS

1. Abra o Headlamp pelo menu Iniciar.
2. Aguarde a identificação dos contextos disponíveis no kubeconfig.
3. Localize o contexto correspondente ao cluster `fcg-platform`.
4. Selecione o cluster para estabelecer a conexão.
5. Aguarde o carregamento dos recursos Kubernetes.

O contexto terá um identificador semelhante a:

```text
arn:aws:eks:us-east-1:CONTA_AWS:cluster/fcg-platform
```

Após a conexão, será possível navegar pelos recursos do cluster utilizando a interface gráfica.

Para visualizar os recursos do projeto, selecione o namespace `fcg-platform`.

## Autenticação e atualização do acesso

O Headlamp utiliza as credenciais AWS disponíveis localmente para autenticar no EKS.

Caso a sessão AWS expire, execute novamente:

```powershell
aws login
```

Se necessário, atualize o contexto Kubernetes:

```powershell
aws eks update-kubeconfig --region us-east-1 --name fcg-platform
```

Depois, reinicie o Headlamp ou atualize a conexão com o cluster.

### ➡️ Próximo passo

Após conectar ao cluster, utilize o Headlamp para acompanhar o estado dos Pods, consultar logs, verificar Deployments e administrar os recursos do namespace `fcg-platform`.
