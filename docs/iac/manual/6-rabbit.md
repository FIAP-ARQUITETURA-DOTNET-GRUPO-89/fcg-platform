# 🐰 6º passo: Implantação do RabbitMQ no Amazon EKS

Este documento descreve a implantação do RabbitMQ no cluster EKS do projeto FIAP FCG, considerando que o cluster e o grupo de nós já estão disponíveis.

## 1. Configurações do ambiente

| Configuração  | Valor                      |
| ------------- | -------------------------- |
| Cluster EKS   | `fcg-platform`             |
| Região AWS    | `us-east-1`                |
| Namespace     | `fcg-platform`             |
| Imagem        | `rabbitmq:3.13-management` |
| Réplicas      | 1                          |
| Service       | `ClusterIP`                |
| Armazenamento | PVC de 1 GiB               |

Confirme a região configurada:

```powershell
aws configure get region
```

Caso necessário:

```powershell
aws configure set region us-east-1
```

## 2. Estrutura dos arquivos

```text
k8s/
└── infrastructure/
    └── rabbitmq/
        ├── configmap.yaml
        ├── deployment.yaml
        ├── pvc.yaml
        ├── secret.yaml
        └── service.yaml
```

## 3. Aplicar os manifests

Execute os comandos a partir da pasta `k8s` do repositório `fcg-platform`.

```powershell
kubectl apply -f .\infrastructure\rabbitmq\
```

A aplicação cria as configurações, credenciais, armazenamento persistente, serviço interno e Deployment do RabbitMQ.

O PVC utiliza a StorageClass `gp2`. Como ela possui a política `WaitForFirstConsumer`, o volume pode permanecer `Pending` até o agendamento do Pod.

## 4. Validar a implantação

Acompanhe a inicialização:

```powershell
kubectl rollout status deployment/rabbitmq -n fcg-platform
```

Verifique os recursos:

```powershell
kubectl get pods,pvc,svc -n fcg-platform
```

Resultados esperados:

- Pod do RabbitMQ: `Running` e `1/1`.
- PVC `rabbitmq-pvc`: `Bound`.
- Service `rabbitmq`: `ClusterIP`.

O RabbitMQ disponibiliza:

| Porta   | Finalidade                             |
| ------- | -------------------------------------- |
| `5672`  | Comunicação AMQP com os microsserviços |
| `15672` | Painel administrativo Management       |

## 5. Acessar o painel Management

O painel não é exposto publicamente. Para acessá-lo, utilize o encaminhamento de porta:

```powershell
kubectl port-forward svc/rabbitmq 15672:15672 -n fcg-platform
```

Mantenha o terminal aberto e acesse [http://localhost:15672](http://localhost:15672).

Credenciais configuradas no Secret:

| Campo   | Valor    |
| ------- | -------- |
| Usuário | `fcg`    |
| Senha   | `fcg123` |

Para encerrar o acesso, pressione `CTRL + C`. Isso encerra apenas o túnel local, sem interromper o RabbitMQ no cluster.

### ➡️ Próximo passo

Com o RabbitMQ implantado, a infraestrutura de mensageria está disponível para integração com os microsserviços do projeto FCG.
