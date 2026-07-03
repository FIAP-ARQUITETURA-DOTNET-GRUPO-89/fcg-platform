# 🚀 Getting Started

Este guia descreve como preparar o ambiente de desenvolvimento para executar a plataforma **FCG Platform** localmente.

Ao final deste documento você terá todas as ferramentas necessárias para executar a aplicação utilizando **Docker Compose** ou realizar o deploy em um cluster **Kubernetes**.

# 📑 Sumário

- [📋 Pré-requisitos](#-pré-requisitos)
- [🐳 Instalando o Docker Desktop](#-instalando-o-docker-desktop)
- [☸️ Habilitando o Kubernetes](#-habilitando-o-kubernetes)
- [🔍 Validando o Ambiente](#-validando-o-ambiente)
- [📁 Estrutura do Repositório](#-estrutura-do-repositório)

# 📋 Pré-requisitos

Antes de iniciar, certifique-se de possuir instalado:

- Git
- Docker Desktop
- Kubernetes habilitado no Docker Desktop
- kubectl

Versões recomendadas:

| Ferramenta     | Versão                             |
| -------------- | ---------------------------------- |
| Docker Desktop | Latest                             |
| Kubernetes     | 1.30+                              |
| kubectl        | Compatível com a versão do cluster |

# 🐳 Instalando o Docker Desktop

Faça o download do Docker Desktop:

https://www.docker.com/products/docker-desktop/

Após a instalação, confirme que o Docker está funcionando.

```bash
docker --version
```

# ☸️ Habilitando o Kubernetes

Abra o Docker Desktop.

Acesse:

```text
Settings
    └── Kubernetes
```

Marque a opção:

```text
Enable Kubernetes
```

Clique em:

```text
Apply & Restart
```

A criação do cluster pode levar alguns minutos.

Verifique se o kubectl está instalado:

```bash
kubectl version --client
```

# 🔍 Validando o Ambiente

## Verificar Contextos

```bash
kubectl config get-contexts
```

Resultado esperado:

```text
CURRENT   NAME
*         docker-desktop
```

## Verificar Contexto Atual

```bash
kubectl config current-context
```

Resultado esperado:

```text
docker-desktop
```

## Verificar o Cluster

```bash
kubectl cluster-info
```

Resultado esperado:

```text
Kubernetes control plane is running...
CoreDNS is running...
```

## Verificar os Nodes

```bash
kubectl get nodes
```

Resultado esperado:

```text
NAME               STATUS
docker-desktop     Ready
```

# 📁 Estrutura do Repositório

A estrutura do repositório de orquestração está organizada da seguinte forma:

```text
.
├── docker-compose.yml
├── docs
├── k8s
│   ├── catalog-api
│   ├── infrastructure
│   │   ├── postgres
│   │   └── rabbitmq
│   ├── notifications-api
│   ├── payments-api
│   ├── users-api
│   └── namespace.yaml
├── scripts
├── LICENSE
└── README.md
```

Cada diretório possui uma responsabilidade específica:

| Diretório          | Responsabilidade                             |
| ------------------ | -------------------------------------------- |
| docs               | Documentação da plataforma                   |
| k8s                | Manifestos Kubernetes                        |
| scripts            | Scripts auxiliares para deploy e limpeza     |
| docker-compose.yml | Orquestração local utilizando Docker Compose |
