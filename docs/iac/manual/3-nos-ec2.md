# ☸️ Criação do Grupo de Nós no Amazon EKS

## 1. Objetivo

Criar um grupo de nós gerenciados (_Managed Node Group_) no Amazon EKS para disponibilizar capacidade computacional ao cluster `fcg-platform`, permitindo executar as aplicações do projeto FCG.

O grupo de nós utiliza instâncias EC2 gerenciadas pelo EKS, responsáveis por executar os Pods do Kubernetes.

## 2. Pré-requisitos

- Cluster EKS `fcg-platform` criado e com status `Active`.
- Região AWS: `sa-east-1` (São Paulo).
- VPC e sub-redes disponíveis.
- Permissões IAM para criar e gerenciar grupos de nós.
- Função IAM específica para os nós de trabalho.

## 3. Acessar o cluster

1. Entre no [Console da AWS](https://console.aws.amazon.com/).
2. Acesse o serviço **Elastic Kubernetes Service (EKS)**.
3. Selecione a região **América do Sul (São Paulo) — `sa-east-1`**.
4. Abra o cluster `fcg-platform`.
5. Acesse a aba **Computação (Compute)**.
6. Clique em **Adicionar grupo de nós**.

## 4. Etapa 1 — Configuração do grupo de nós

Preencha os campos conforme a tabela:

| Campo                 | Valor               |
| --------------------- | ------------------- |
| Nome do grupo de nós  | `fcg-workers`       |
| Função IAM do nó      | `AmazonEKSNodeRole` |
| Rótulos do Kubernetes | Nenhum              |
| Taints do Kubernetes  | Nenhum              |
| Tag — chave           | `Project`           |
| Tag — valor           | `FCG`               |

### Sobre a função IAM

A função `AmazonEKSNodeRole` deve permitir que os nós se registrem no cluster e executem as operações necessárias. Ela deve possuir as permissões apropriadas para os nós de trabalho, sem reutilizar a função IAM do plano de controle do EKS.

## 5. Etapa 2 — Configuração de computação e escalabilidade

Configure os parâmetros de computação:

| Campo              | Valor                             |
| ------------------ | --------------------------------- |
| Tipo de capacidade | On-Demand                         |
| Tipo de AMI        | Amazon Linux 2023 — x86_64 padrão |
| Tipo de instância  | `t3.small`                        |
| CPU virtual        | 2 vCPUs                           |
| Memória            | 2 GiB                             |
| Tamanho do disco   | 20 GiB                            |
| Tamanho desejado   | 1 nó                              |
| Tamanho mínimo     | 1 nó                              |
| Tamanho máximo     | 1 nó                              |

**Por que usar `t3.small`?**

O tipo `t3.small` apareceu na consulta de tipos de instância marcados como elegíveis ao Free Tier na região `sa-east-1`. Ele mantém a arquitetura x86-64, compatível com a imagem .NET utilizada no projeto.

A elegibilidade deve ser confirmada para as condições atuais da conta. Além disso, 2 GiB de RAM podem ser insuficientes para executar vários microsserviços simultaneamente.

### Configuração do Auto Scaling Group

| Campo                                 | Valor        |
| ------------------------------------- | ------------ |
| Grupo ativo do AWS Auto Scaling Group | Desabilitado |

O grupo de nós gerenciado utiliza um Auto Scaling Group criado e administrado pelo EKS. A opção acima permanece desabilitada porque não precisamos configurar um grupo ativo adicional para este primeiro teste.

### Configuração de atualização

| Campo                     | Valor        |
| ------------------------- | ------------ |
| Máximo indisponível       | 1 nó         |
| Estratégia de atualização | Padrão       |
| Reparo automático de nós  | Desabilitado |

**Observação:** com apenas um nó, uma atualização ou falha pode interromper temporariamente as aplicações. Essa configuração prioriza simplicidade e baixo custo inicial, não alta disponibilidade.

## 6. Etapa 3 — Configuração de rede

Selecione as três sub-redes da VPC padrão:

| Sub-rede                   | Zona de disponibilidade | CIDR             |
| -------------------------- | ----------------------- | ---------------- |
| `subnet-04e2b2af75e439d4a` | `sa-east-1b`            | `172.31.16.0/20` |
| `subnet-0051cc5eef20c6b72` | `sa-east-1a`            | `172.31.0.0/20`  |
| `subnet-09e73057b7f4e7cae` | `sa-east-1c`            | `172.31.32.0/20` |

### Acesso remoto

- Acesso remoto por SSH: desabilitado.
- Chave SSH: não configurada.

O acesso administrativo inicial será realizado por meio do Kubernetes e do comando `kubectl`, sem habilitar SSH nos nós.

**Importante:** os nós precisam de conectividade de saída para baixar imagens do Docker Hub e acessar os serviços necessários. A configuração de rede deve permitir essa comunicação.

## 7. Revisar e criar

Antes de criar, revise as três etapas e confirme:

- [ ] Nome do grupo: `fcg-workers`.
- [ ] Função IAM do nó: `AmazonEKSNodeRole`.
- [ ] Instância `t3.small`.
- [ ] Disco EBS de 20 GiB.
- [ ] Escalabilidade configurada para um único nó.
- [ ] Três sub-redes selecionadas.
- [ ] Acesso SSH desabilitado.
- [ ] Tag `Project=FCG`.

Após a revisão, clique em **Criar**.

Aguarde até que o grupo de nós apresente o status `Active`. Se continuar em `Criando`, verifique o histórico de atividades do Auto Scaling e os problemas de integridade antes de realizar novas tentativas.

## 8. Validar o nó com kubectl

Após a criação, autentique-se na AWS pelo terminal:

```powershell
aws login
```

Em seguida, atualize o contexto do Kubernetes:

```powershell
aws eks update-kubeconfig --region sa-east-1 --name fcg-platform
```

Confirme o contexto atual:

```powershell
kubectl config current-context
```

O resultado esperado deve identificar o cluster `fcg-platform` na região `sa-east-1`.

### Verificar os nós

```powershell
kubectl get nodes
```

Para detalhar o estado e a capacidade do nó:

```powershell
kubectl get nodes -o wide
kubectl describe nodes
```

O nó deve aparecer com o status `Ready`.

### Verificar os Pods do cluster

```powershell
kubectl get pods -A
```

Confira especialmente os Pods do namespace `kube-system`, como o CoreDNS. Depois que o nó estiver disponível, os Pods que estavam em `Pending` por falta de capacidade computacional deverão ter a oportunidade de ser agendados.

Se algum Pod continuar em `Pending`, investigue antes de implantar as aplicações:

```powershell
kubectl describe pod -n kube-system NOME_DO_POD
kubectl get events -A --sort-by=.lastTimestamp
```

Substitua `NOME_DO_POD` pelo nome real do Pod.

## 9. Considerações sobre custos

A criação do grupo de nós adiciona recursos cobrados à conta AWS. Os principais itens são:

- Instância EC2 `t3.small`, conforme as condições de cobrança aplicáveis.
- Volume EBS de 20 GiB.
- Possível endereço IPv4 público e outros custos de rede.
- Plano de controle do EKS, cobrado separadamente enquanto o cluster existir.

O tipo `t3.small` constar na lista de instâncias elegíveis não garante que todos os recursos do ambiente serão gratuitos. A gratuidade depende das condições da conta, da franquia disponível e dos demais recursos utilizados.

O AWS Budgets ajuda a acompanhar os gastos, mas não bloqueia automaticamente a criação de recursos nem interrompe cobranças.

## 10. Encerramento do ambiente

Quando terminar os testes, não basta excluir os Pods ou encerrar manualmente a instância EC2.

Para interromper os principais custos do ambiente, siga o procedimento de limpeza do projeto:

1. Excluir aplicações e serviços publicados, incluindo Load Balancers que tenham sido criados.
2. Excluir o grupo de nós gerenciado `fcg-workers`.
3. Aguardar a exclusão do grupo de nós.
4. Excluir o cluster EKS `fcg-platform`, quando não for mais necessário.
5. Verificar se restaram volumes EBS, endereços IP ou outros recursos cobrados.

Antes de excluir qualquer recurso, confirme que ele pertence ao ambiente de testes e que não contém dados que precisam ser preservados.

---

## Resultado esperado

Ao final, o cluster `fcg-platform` deverá possuir um grupo de nós gerenciado chamado `fcg-workers`, com uma instância EC2 `t3.small` disponível para executar os Pods do projeto FIAP FCG.

A próxima etapa será validar a infraestrutura e implantar a primeira aplicação .NET no Kubernetes, utilizando a imagem pública já publicada no Docker Hub.
