# 🚪 Kong API Gateway

Este documento descreve como realizar o deploy da instância do **Kong API Gateway** utilizada pela plataforma FCG no Kubernetes.

O Kong funciona como o **único ponto de entrada externo** para as APIs da plataforma, sendo responsável por:

- Roteamento das requisições.
- Autenticação JWT.
- Rate limiting.
- Encaminhamento das requisições para os Services Kubernetes.

## 📑 Sumário

- [🎯 Objetivo](#-objetivo)
- [🏗 Arquitetura](#-arquitetura)
- [⚙️ Configuração](#️-configuração)
- [🔐 Autenticação JWT](#-autenticação-jwt)
- [🚦 Rate Limiting](#-rate-limiting)
- [🚀 Deploy](#-deploy)
  - [Secret](#secret)
  - [Kustomization](#kustomization)
  - [Deployment](#deployment)
  - [Service](#service)

# 🎯 Objetivo

O Kong foi introduzido para fornecer um ponto de entrada único para as APIs da FCG.

Dessa forma, os clientes não precisam conhecer ou acessar diretamente cada microsserviço.

```text
                    ┌─────────────────┐
                    │     Usuário     │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │      Kong       │
                    │   API Gateway   │
                    └────────┬────────┘
                             │
             ┌───────────────┼───────────────┐
             │               │               │
             ▼               ▼               ▼
        Users API       Catalog API     Payments API

```

O Gateway também centraliza políticas de segurança e controle de tráfego.

# 🏗 Arquitetura

No Kubernetes, o Kong é executado dentro do namespace `fcg-platform`.

O Service do Kong utiliza `LoadBalancer`, permitindo que as requisições externas sejam direcionadas para o Gateway.

As APIs permanecem utilizando `ClusterIP`, ficando disponíveis apenas internamente no cluster.

```text
Cliente
   │
   ▼
LoadBalancer
   │
   ▼
Kong :8000
   │
   ├──────────────► fcg-users-api:7010
   │
   ├──────────────► fcg-catalog-api:7030
   │
   └──────────────► fcg-payments-api:7040

```

## Serviços Kubernetes

| Serviço          | Porta | Tipo         |
| ---------------- | ----- | ------------ |
| Kong             | 8000  | LoadBalancer |
| FCG Users API    | 7010  | ClusterIP    |
| FCG Catalog API  | 7030  | ClusterIP    |
| FCG Payments API | 7040  | ClusterIP    |

# ⚙️ Configuração

O Kong utiliza o modo **DB-less**, portanto não possui banco de dados próprio.

A configuração é declarativa e mantida no arquivo `kong.yml`. O Kustomize gera automaticamente o `ConfigMap` necessário a partir desse arquivo declarativo.

O Deployment utiliza:

```text
KONG_DATABASE=off

```

e:

```text
KONG_DECLARATIVE_CONFIG=/etc/kong/kong.yml

```

As informações sensíveis não ficam expostas diretamente no manifesto público. A chave JWT utilizada pelo Kong é armazenada no `Secret` do Kubernetes.

## Rotas

| Rota            | Backend          | Segurança | Rate Limit              |
| --------------- | ---------------- | --------- | ----------------------- |
| `/api/auth`     | FCG Users API    | Pública   | 5 req/min por IP        |
| `/api/users`    | FCG Users API    | JWT       | 60 req/min por consumer |
| `/api/games`    | FCG Catalog API  | JWT       | 60 req/min por consumer |
| `/api/orders`   | FCG Catalog API  | JWT       | 60 req/min por consumer |
| `/api/library`  | FCG Catalog API  | JWT       | 60 req/min por consumer |
| `/api/payments` | FCG Payments API | JWT       | 60 req/min por consumer |

# 🔐 Autenticação JWT

As rotas protegidas utilizam o plugin `jwt` do Kong.

O JWT é emitido pela Users API durante a autenticação.

A configuração utiliza:

```text
Issuer: FcgUsers-Issuer
Algorithm: HS256

```

O Kong possui um Consumer configurado para validar os tokens:

```text
fcg-users-api

```

A chave utilizada pelo Kong para validar o token deve ser a mesma utilizada pela Users API para assinar o JWT.

O Kong valida:

- Assinatura do token.
- `iss` (issuer).
- `exp` (expiration).

# 🚦 Rate Limiting

O Kong também aplica controle de tráfego nas rotas da plataforma.

## Login

A rota:

```text
/api/auth

```

possui o limite de:

```text
5 requisições por minuto por IP

```

Essa proteção reduz tentativas excessivas de autenticação.

## Rotas autenticadas

As rotas protegidas possuem limite de:

```text
60 requisições por minuto por consumer

```

# 🚀 Deploy

O Kong é implantado após os microsserviços no script de deploy da plataforma, garantindo que os Services das APIs já estejam criados quando o Gateway iniciar.

## Secret

Aplicar:

```bash
kubectl apply -f k8s/infrastructure/kong/secret.yaml

```

Verificar:

```bash
kubectl get secrets -n fcg-platform

```

## Kustomization

Aplicar a configuração declarativa gerada via Kustomize (gera o ConfigMap dinamicamente):

```bash
kubectl apply -k k8s/infrastructure/kong/

```

Verificar os ConfigMaps gerados:

```bash
kubectl get configmaps -n fcg-platform

```

## Deployment

Aplicar:

```bash
kubectl apply -f k8s/infrastructure/kong/deployment.yaml

```

Verificar:

```bash
kubectl get deployments -n fcg-platform

```

Verificar os Pods:

```bash
kubectl get pods -n fcg-platform -l app.kubernetes.io/name=kong

```

Resultado esperado:

```text
NAME                    READY   STATUS
kong-xxxxxxxxxx-xxxxx   1/1     Running

```

Visualizar detalhes:

```bash
kubectl describe pod -l app.kubernetes.io/name=kong -n fcg-platform

```

Visualizar logs:

```bash
kubectl logs deployment/kong -n fcg-platform

```

## Service

Aplicar:

```bash
kubectl apply -f k8s/infrastructure/kong/service.yaml

```

Verificar:

```bash
kubectl get services -n fcg-platform

```

Resultado esperado:

```text
NAME   TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)
kong   LoadBalancer   10.x.x.x       localhost     8000:xxxxx/TCP

```

No Docker Desktop, o Service `LoadBalancer` disponibiliza o proxy do Kong na porta:

```text
8000

```
