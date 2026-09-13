# 🚀 FCG Platform

Repositório responsável pela orquestração da plataforma FCG, contendo configurações do Docker Compose, Kubernetes e infraestrutura compartilhada utilizada pelos microsserviços.

## 📑 Sumário

- [📦 Clonando o repositório](#-clonando-o-repositório)
- [🚀 Começando](#-começando)
- [🏛️ Arquitetura](#️-arquitetura)
- [🐳 Executar com Docker](#-executar-com-docker)
- [☸️ Executar com Kubernetes](#️-executar-com-kubernetes)
- [📈 Observabilidade](#-observabilidade)

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

## 📈 Observabilidade

A plataforma adota uma **stack de código aberto baseada em Prometheus + Grafana**, implantada no cluster Kubernetes via Helm e manifestos versionados neste repositório.

### Justificativa da escolha

- Os microsserviços já usam **.NET Aspire com OpenTelemetry** por padrão, e o exporter Prometheus se pluga diretamente ao pipeline OTel existente — instrumentação em ~5 linhas por serviço.
- O `kube-prometheus-stack` (Helm) entrega Prometheus, Grafana, `kube-state-metrics` e `node-exporter` em um único comando, com dashboards de infraestrutura K8s já prontos.
- Toda a configuração (values do Helm, `ServiceMonitor`, dashboards) fica versionada no repositório, garantindo reprodutibilidade.
- Sem dependências externas (contas, chaves, trials).

### O que é coletado

- **Métricas HTTP** dos microsserviços `fcg-users-api`, `fcg-catalog-api`, `fcg-payments-api`: taxa de requisições por status code, latência p50/p95/p99, taxa de erros, requisições em andamento.
- **Métricas do runtime .NET**: uso de memória, coletas de GC por geração.
- **Métricas de infraestrutura K8s**: consumo de CPU/memória por pod, saúde dos nós, kubelet.

O `fcg-notifications` (Worker) não é coletado nesta fase — está sendo migrado para Lambda na Parte 2, onde métricas ficam no CloudWatch nativamente.

### Como subir

Passo a passo, targets, dashboards e troubleshooting:

👉 [Guia da Stack de Observabilidade](k8s/infrastructure/observability/README.md)
