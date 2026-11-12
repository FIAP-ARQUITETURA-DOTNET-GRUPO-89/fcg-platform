# ☸️ 3º passo: Criação do Grupo de Nós (EC2) no Amazon EKS

## 🎯 Objetivo

Criar um grupo de nós gerenciados (_Managed Node Group_) no Amazon EKS para disponibilizar capacidade computacional ao cluster `fcg-platform`, permitindo executar as aplicações do projeto FIAP Cloud Games (FCG).

Os nós utilizam instâncias EC2 gerenciadas pelo EKS e são responsáveis por executar os Pods do Kubernetes.

## 📋 Pré-requisitos

- Cluster EKS `fcg-platform` criado e com status `Active`.
- Região AWS: `us-east-1` (Virgínia do Norte).
- VPC e sub-redes disponíveis.
- Permissões IAM para criar e gerenciar grupos de nós.
- Função IAM específica para os nós de trabalho.

## 1. 🌐 Acessar o cluster

1. Acesse o [Console da AWS](https://console.aws.amazon.com/).
2. Entre no serviço **Elastic Kubernetes Service (EKS)**.
3. Selecione a região **EUA (Virgínia do Norte) — `us-east-1`**.
4. Abra o cluster `fcg-platform`.
5. Acesse a aba **Computação (Compute)**.
6. Clique em **Adicionar grupo de nós**.

## 2. ⚙️ Configurar o grupo de nós

Na primeira etapa, configure:

| Campo              | Valor               |
| ------------------ | ------------------- |
| Nome do grupo      | `fcg-workers`       |
| Função IAM do nó   | `AmazonEKSNodeRole` |
| Rótulos Kubernetes | Nenhum              |
| Taints Kubernetes  | Nenhum              |
| Tag — chave        | `Project`           |
| Tag — valor        | `FCG`               |

### 🔐 Sobre a função IAM

A função `AmazonEKSNodeRole` deve permitir que os nós se registrem no cluster e executem as operações necessárias.

Ela deve possuir as permissões apropriadas para os nós de trabalho, sem reutilizar a função IAM do plano de controle do EKS.

## 3. 🖥️ Configurar computação e escalabilidade

Configure os parâmetros das instâncias EC2:

| Campo              | Valor                             |
| ------------------ | --------------------------------- |
| Tipo de capacidade | On-Demand                         |
| Tipo de AMI        | Amazon Linux 2023 — x86_64 padrão |
| Tipo de instância  | `m7i-flex.large`                  |
| CPU                | 2 vCPUs                           |
| Memória            | 2 GiB                             |
| Disco              | 20 GiB                            |
| Tamanho desejado   | 1 nó                              |
| Tamanho mínimo     | 1 nó                              |
| Tamanho máximo     | 1 nó                              |

### 💡 Por que utilizar `m7i-flex.large`?

O tipo `m7i-flex.large` apareceu na consulta de instâncias elegíveis ao Free Tier na região `us-east-1`.

Sua arquitetura x86-64 é compatível com a imagem .NET utilizada no projeto.

⚠️ **Atenção:**

- A elegibilidade ao Free Tier depende das condições atuais da conta e da franquia disponível.
- A instância possui apenas 2 GiB de RAM, podendo ser insuficiente para executar vários microsserviços simultaneamente.
- Verifique os preços e as condições de gratuidade antes de provisionar.

### Configuração do Auto Scaling Group

| Campo                                 | Valor        |
| ------------------------------------- | ------------ |
| Grupo ativo do AWS Auto Scaling Group | Desabilitado |

O EKS cria e administra automaticamente um Auto Scaling Group para o grupo de nós gerenciado.

A opção acima permanece desabilitada porque não precisamos configurar um grupo ativo adicional para este primeiro teste.

### Configuração de atualização

| Campo                     | Valor        |
| ------------------------- | ------------ |
| Máximo indisponível       | 1 nó         |
| Estratégia de atualização | Padrão       |
| Reparo automático de nós  | Desabilitado |

**⚠️ Observação:** como teremos apenas um nó, uma atualização ou falha poderá interromper temporariamente as aplicações. Essa configuração prioriza simplicidade e baixo custo inicial, não alta disponibilidade.

## 4. 🌐 Configurar a rede

Selecione as três sub-redes da VPC padrão:

| Sub-rede                   | Zona de disponibilidade | CIDR             |
| -------------------------- | ----------------------- | ---------------- |
| `subnet-04e2b2af75e439d4a` | `us-east-1b`            | `172.31.16.0/20` |
| `subnet-0051cc5eef20c6b72` | `us-east-1a`            | `172.31.0.0/20`  |
| `subnet-09e73057b7f4e7cae` | `us-east-1c`            | `172.31.32.0/20` |

### 🔑 Acesso remoto

| Configuração          | Valor           |
| --------------------- | --------------- |
| Acesso remoto por SSH | Desabilitado    |
| Chave SSH             | Não configurada |

O acesso administrativo inicial será realizado por meio do Kubernetes e do comando `kubectl`, sem habilitar SSH nos nós.

⚠️ **Importante:** os nós precisam de conectividade de saída para baixar imagens do Docker Hub e acessar os serviços necessários. A configuração de rede deve permitir essa comunicação.

## 5. 🔍 Revisar e criar

Antes de confirmar a criação, revise as configurações:

### Checklist de validação

- [ ] Nome do grupo: `fcg-workers`.
- [ ] Função IAM: `AmazonEKSNodeRole`.
- [ ] Instância EC2: `m7i-flex.large`.
- [ ] Disco EBS: 20 GiB.
- [ ] Escalabilidade configurada para um único nó.
- [ ] Três sub-redes selecionadas.
- [ ] Acesso SSH desabilitado.
- [ ] Tag `Project=FCG`.
- [ ] Custos estimados e elegibilidade ao Free Tier conferidos.

Após a revisão, clique em **Criar**.

⏳ Aguarde até que o grupo de nós apresente o status `Active`.

Se permanecer em `Criando`, verifique o histórico de atividades do Auto Scaling e os problemas de integridade antes de realizar novas tentativas.

## 6. ✅ Validar o nó com kubectl

Após a criação, abra o PowerShell e autentique-se na AWS:

```powershell
aws login
```

Atualize o contexto do Kubernetes:

```powershell
aws eks update-kubeconfig --region us-east-1 --name fcg-platform
```

Confirme o contexto atual:

```powershell
kubectl config current-context
```

O resultado esperado deve identificar o cluster `fcg-platform` na região `us-east-1`.

### Verificar os nós

Execute:

```powershell
kubectl get nodes
```

Para consultar mais detalhes:

```powershell
kubectl get nodes -o wide
kubectl describe nodes
```

<badge color="success">Status esperado: Ready</badge>

O nó deverá aparecer com o status `Ready`, indicando que está disponível para executar os Pods.

### Verificar os Pods do cluster

Execute:

```powershell
kubectl get pods -A
```

Confira especialmente os Pods do namespace `kube-system`, como o CoreDNS.

Com o nó disponível, os Pods que estavam em `Pending` por falta de capacidade computacional poderão ser agendados.

Se algum Pod continuar em `Pending`, investigue antes de implantar as aplicações:

```powershell
kubectl describe pod -n kube-system NOME_DO_POD
kubectl get events -A --sort-by=.lastTimestamp
```

Substitua `NOME_DO_POD` pelo nome real do Pod.

## 7. 💰 Considerações sobre custos

A criação do grupo de nós adiciona recursos cobrados à conta AWS.

### Recursos que devem ser monitorados

- Instância EC2 `m7i-flex.large`, conforme as condições de cobrança aplicáveis.
- Volume EBS de 20 GiB.
- Possível endereço IPv4 público e outros custos de rede.
- Plano de controle do EKS, cobrado separadamente enquanto o cluster existir.

⚠️ **Importante:**

A elegibilidade da instância ao Free Tier não garante que todos os recursos do ambiente serão gratuitos.

A gratuidade depende das condições da conta, da franquia disponível e dos demais recursos utilizados.

O AWS Budgets ajuda a acompanhar os gastos, mas não bloqueia automaticamente a criação de recursos nem interrompe cobranças.

## 8. 🧹 Encerramento do ambiente

Ao finalizar os testes, não basta excluir os Pods ou encerrar manualmente a instância EC2.

Para evitar cobranças desnecessárias, siga o procedimento:

1. Excluir aplicações e serviços publicados, incluindo Load Balancers criados.
2. Excluir o grupo de nós gerenciado `fcg-workers`.
3. Aguardar a exclusão do grupo de nós.
4. Excluir o cluster EKS `fcg-platform`, quando não for mais necessário.
5. Verificar se restaram volumes EBS, endereços IP ou outros recursos cobrados.

## 📌 Resultado esperado

Ao final, o cluster `fcg-platform` deverá possuir um grupo de nós gerenciado chamado `fcg-workers`, com uma instância EC2 `m7i-flex.large` disponível para executar os Pods do projeto FIAP FCG.

### ➡️ Próximo passo

Com o cluster EKS e o grupo de nós disponíveis, prossiga para [4. Configuração do PostgreSQL](./4-postgres.md).
