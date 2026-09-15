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

Clone o repositório juntamente com todos os submódulos:

```bash
git clone --recurse-submodules https://github.com/FIAP-ARQUITETURA-DOTNET-GRUPO-89/fcg-platform.git
```

Sempre que houver atualização da referência dos submódulos, execute:

```bash
git submodule update --init --recursive
```

## 🚀 Começando

Antes de executar a plataforma, prepare o ambiente local.

👉 [Guia de inicialização do ambiente](docs/getting-started.md)

## 🏛️ Arquitetura

A FCG Platform utiliza uma arquitetura baseada em microsserviços, comunicação assíncrona orientada a eventos e infraestrutura containerizada.

👉 [Visão geral da arquitetura](docs/architecture/architecture-overview.md)

## 🐳 Executar com Docker

Para executar a FCG Platform localmente utilizando Docker Compose:

👉 [Documentação do Docker Compose](docs/docker-compose.md)

## ☸️ Executar com Kubernetes

Para executar a FCG Platform em um cluster Kubernetes:

👉 [Guia de Kubernetes](docs/kubernetes.md)
