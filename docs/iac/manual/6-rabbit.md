# 🐰 Subindo o RabbitMQ no AWS EKS

Este documento descreve o processo de implantação do RabbitMQ no cluster EKS do projeto FIAP FCG.

## 1. Configurações do ambiente

| Configuração  | Valor                      |
| ------------- | -------------------------- |
| Cluster EKS   | `fcg-platform`             |
| Região AWS    | `sa-east-1`                |
| Namespace     | `fcg-platform`             |
| Imagem        | `rabbitmq:3.13-management` |
| Réplicas      | 1                          |
| Service       | `ClusterIP`                |
| Armazenamento | PVC de 1 GiB               |

Confirme se a região configurada está correta:

```powershell
aws configure get region
```

Caso não esteja em `sa-east-1`, configure:

```powershell
aws configure set region sa-east-1
```

## 2. Estrutura dos arquivos

Os manifests do RabbitMQ estão organizados em:

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

**3.1. ConfigMap**

Cria as configurações não sensíveis do RabbitMQ.

```powershell
kubectl apply -f .\infrastructure\rabbitmq\configmap.yaml
```

**3.2. Secret**

Cria as credenciais utilizadas pelo RabbitMQ.

```powershell
kubectl apply -f .\infrastructure\rabbitmq\secret.yaml
```

**3.3. PersistentVolumeClaim**

Solicita o armazenamento persistente de 1 GiB para os dados do RabbitMQ.

```powershell
kubectl apply -f .\infrastructure\rabbitmq\pvc.yaml
```

O PVC utiliza a StorageClass `gp2`. Como ela utiliza `WaitForFirstConsumer`, o volume pode permanecer `Pending` até o agendamento do Pod.

**3.4. Service**

Cria o serviço interno para comunicação com o RabbitMQ.

```powershell
kubectl apply -f .\infrastructure\rabbitmq\service.yaml
```

**3.5. Deployment**

Cria o Pod do RabbitMQ.

```powershell
kubectl apply -f .\infrastructure\rabbitmq\deployment.yaml
```

O Deployment utiliza uma réplica e a estratégia `Recreate`, evitando a tentativa de executar dois Pods simultaneamente durante atualizações em um ambiente com recursos limitados.

## 4. Validar a implantação

Acompanhe a inicialização do Deployment:

```powershell
kubectl rollout status deployment/rabbitmq -n fcg-platform
```

Confira os Pods:

```powershell
kubectl get pods -n fcg-platform
```

O Pod do RabbitMQ deve apresentar status `Running` e `1/1` containers prontos.

Confira o armazenamento:

```powershell
kubectl get pvc rabbitmq-pvc -n fcg-platform
```

O status esperado é `Bound`.

Confira o Service:

```powershell
kubectl get svc rabbitmq -n fcg-platform
```

O RabbitMQ disponibiliza duas portas:

| Porta   | Finalidade                             |
| ------- | -------------------------------------- |
| `5672`  | Comunicação AMQP com os microsserviços |
| `15672` | Painel administrativo Management       |

## 5. Acessar o RabbitMQ Management

O painel administrativo não é exposto publicamente. Para acessá-lo, utilize `kubectl port-forward`.

```powershell
kubectl port-forward svc/rabbitmq 15672:15672 -n fcg-platform
```

Mantenha o terminal aberto e acesse:

http://localhost:15672

Credenciais:

| Campo   | Valor    |
| ------- | -------- |
| Usuário | `fcg`    |
| Senha   | `fcg123` |

O painel permite acompanhar filas, exchanges, conexões, canais e mensagens.

Para encerrar o acesso, pressione `CTRL + C` no terminal que está executando o port-forward.

Isso encerra apenas o túnel local, sem interromper o RabbitMQ no cluster.

## 6. Configuração para os microsserviços

Os microsserviços executados no mesmo namespace podem acessar o RabbitMQ utilizando o DNS interno do Kubernetes.

| Configuração | Valor      |
| ------------ | ---------- |
| Host         | `rabbitmq` |
| Porta        | `5672`     |
| Usuário      | `fcg`      |
| Senha        | `fcg123`   |
| Virtual Host | `/`        |

Formato da conexão AMQP:

```text
amqp://fcg:fcg123@rabbitmq:5672/
```

As credenciais devem ser fornecidas aos microsserviços por meio de Secrets ou configuração segura, sem serem versionadas diretamente no código.

## 7. Comandos úteis

**Consultar os logs:**

```powershell
kubectl logs deployment/rabbitmq -n fcg-platform
```

**Acompanhar os logs em tempo real:**

```powershell
kubectl logs -f deployment/rabbitmq -n fcg-platform
```

**Verificar os recursos do RabbitMQ:**

```powershell
kubectl get pods,pvc,svc -n fcg-platform
```

**Reiniciar o RabbitMQ:**

```powershell
kubectl rollout restart deployment/rabbitmq -n fcg-platform
```

**Acompanhar a reinicialização:**

```powershell
kubectl rollout status deployment/rabbitmq -n fcg-platform
```

## 8. Considerações sobre custos

A implantação foi feita considerando o reaproveitamento da infraestrutura existente:

- Apenas uma réplica do RabbitMQ.
- Utilização do nó EC2 já existente.
- Service do tipo `ClusterIP`, sem criação de LoadBalancer.
- Acesso administrativo por `port-forward`.
- Volume persistente de 1 GiB.

**Atenção:** o PVC utiliza armazenamento EBS, que pode gerar custos adicionais. O EKS, a instância EC2 e demais recursos existentes também podem gerar cobranças independentemente do RabbitMQ.

A interrupção do `port-forward` não desliga o RabbitMQ. O Pod permanece em execução no cluster.
