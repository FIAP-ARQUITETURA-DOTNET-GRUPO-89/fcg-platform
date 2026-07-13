# 🚀 FCG Platform

Repositório responsável pela orquestração da plataforma FCG, contendo configurações do Docker Compose, Kubernetes e infraestrutura compartilhada utilizada pelos microsserviços.

## 📑 Sumário

- [📦 Clonando o repositório](#-clonando-o-repositório)
- [🚀 Começando](#-começando)
- [🏛️ Arquitetura](#️-arquitetura)
- [🐳 Executar com Docker](#-executar-com-docker)
- [☸️ Executar com Kubernetes](#️-executar-com-kubernetes)

## 📦 Clonando o repositório

Este repositório utiliza **Git Submodules** para referenciar os repositórios dos microsserviços.

### Opção 1 (Recomendada)

Clone o repositório juntamente com todos os submódulos:

```bash
git clone --recurse-submodules https://github.com/FIAP-ARQUITETURA-DOTNET-GRUPO-89/fcg-platform.git
```

### Opção 2

Caso o repositório já tenha sido clonado sem os submódulos, inicialize-os executando:

```bash
git submodule update --init --recursive
```

Sempre que houver atualização da referência dos submódulos, execute novamente o comando acima para sincronizar todos os microsserviços com as versões utilizadas pela plataforma.

## 🚀 Começando

Antes de executar a plataforma, prepare o ambiente local.

👉 [Guia de inicialização do ambiente](docs/getting-started.md)

## 🏛️ Arquitetura

A FCG Platform utiliza uma arquitetura baseada em microsserviços, comunicação assíncrona orientada a eventos e infraestrutura containerizada.

👉 [Visão geral da arquitetura](docs/architecture/architecture-overview.md)

## 🐳 Executar com Docker

Se você deseja executar a FCG Platform localmente utilizando Docker Compose:

👉 [Documentação do Docker](docs/docker-compose.md)

## ☸️ Executar com Kubernetes

Se você deseja executar a FCG Platform em um cluster Kubernetes:

👉 [Guia de Kubernetes](docs/kubernetes.md)
