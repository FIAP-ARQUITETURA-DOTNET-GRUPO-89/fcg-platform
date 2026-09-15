# 📈 Observabilidade (Prometheus + Grafana)

Este documento descreve a configuração da stack de observabilidade da plataforma FCG no Kubernetes, composta por **Prometheus** para coleta de métricas e **Grafana** para visualização, implantada via chart `kube-prometheus-stack`.

## 📑 Sumário

- [🎯 Objetivo](#-objetivo)
- [⚙️ Configuração](#️-configuração)
- [🚀 Deploy](#-deploy)
- [🔎 Acesso](#-acesso)
- [✅ Validação](#-validação)
- [📊 Dashboard "FCG — Visão geral"](#-dashboard-fcg--visão-geral)
- [🧩 Contrato de descoberta](#-contrato-de-descoberta)
- [🧹 Remoção](#-remoção)
- [🛠 Troubleshooting](#-troubleshooting)
- [ℹ️ Nota sobre `fcg-notifications`](#ℹ️-nota-sobre-fcg-notifications)

# 🎯 Objetivo

A stack cobre os três pilares mais importantes para operar uma arquitetura de microsserviços em Kubernetes:

- **Métricas HTTP** dos microsserviços `fcg-users-api`, `fcg-catalog-api` e `fcg-payments-api`: taxa de requisições por status code, latência p50/p95/p99, taxa de erros e requisições em andamento.
- **Métricas do runtime .NET**: uso de memória, coletas de GC por geração.
- **Métricas de infraestrutura Kubernetes**: consumo de CPU/memória por pod, saúde dos nós, kubelet — via `kube-state-metrics` e `node-exporter`.

Alertmanager está **desabilitado** por não ser exigido pelo desafio.

# ⚙️ Configuração

Os arquivos da stack estão em:

```text
k8s/infrastructure/observability/
├── namespace.yaml
├── kustomization.yaml
├── servicemonitor-fcg.yaml
├── values-kube-prometheus-stack.yaml
└── grafana-dashboards/
    └── fcg-overview.json
```

### Componentes

| Componente | Origem |
|------------|--------|
| Prometheus | Chart `kube-prometheus-stack` (Helm) |
| Grafana | Chart `kube-prometheus-stack` (Helm) |
| kube-state-metrics | Chart `kube-prometheus-stack` (Helm) |
| node-exporter | Chart `kube-prometheus-stack` (Helm) |
| ServiceMonitor `fcg-services` | Manifesto próprio (descobre APIs automaticamente) |
| Dashboard "FCG — Visão geral" | ConfigMap provisionado via Grafana sidecar |

### Namespace

Toda a stack roda no namespace dedicado `observability`, isolando-a dos microsserviços que ficam em `fcg-platform`.

### Values do Helm

Os valores customizados estão em `values-kube-prometheus-stack.yaml`. Pontos-chave:

- Retenção de 6h (in-memory, sem PVC — apropriado para dev/demo).
- Grafana com `adminPassword: CHANGE_ME_BEFORE_PROD` — **deve ser sobrescrito** em ambientes compartilhados.
- Grafana sidecar habilitado para provisionar dashboards a partir de ConfigMaps com label `grafana_dashboard=1`.
- Componentes do control plane (`kubeControllerManager`, `kubeScheduler`, `kubeEtcd`, `kubeProxy`) desabilitados por não serem acessíveis em clusters gerenciados.

# 🚀 Deploy

## Pré-requisitos

- Cluster Kubernetes acessível via `kubectl`.
- [Helm 3](https://helm.sh/) instalado.

## Passo a passo

```bash
# 1. Namespace + ServiceMonitor + dashboard (via kustomize)
kubectl apply -k k8s/infrastructure/observability/

# 2. Adicionar o repo do kube-prometheus-stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 3. Instalar/atualizar a stack (CRDs + Prometheus + Grafana + exporters)
#
# Sobrescreva a senha do Grafana em qualquer ambiente compartilhado.
helm upgrade --install kube-prom prometheus-community/kube-prometheus-stack \
  --namespace observability \
  --values k8s/infrastructure/observability/values-kube-prometheus-stack.yaml \
  --set grafana.adminPassword="$GRAFANA_ADMIN_PASSWORD" \
  --wait
```

O script de deploy completo da plataforma também realiza automaticamente a instalação da stack de observabilidade:

```bash
./scripts/deploy.sh
```

# 🔎 Acesso

```bash
# Grafana (usuário: admin — senha: a que foi passada no install)
kubectl port-forward -n observability svc/kube-prom-grafana 3000:80

# Prometheus UI (inspeção de targets e query builder)
kubectl port-forward -n observability svc/kube-prom-prometheus 9090:9090
```

Abra:

- Grafana → `http://localhost:3000`
- Prometheus → `http://localhost:9090/targets`

# ✅ Validação

1. No Prometheus → **Status → Targets**, os pods do `fcg-services` ServiceMonitor devem aparecer como `UP`.
2. No Grafana, abrir o dashboard **FCG — Visão geral** (uid `fcg-overview`) — provisionado automaticamente pelo sidecar.
3. Gerar carga contra o Kong:

   ```bash
   kubectl port-forward -n fcg-platform svc/kong-proxy 8000:80
   hey -z 60s -c 20 http://localhost:8000/api/games
   ```

   Latência p95 e request rate devem responder em <15 s no dashboard.

# 📊 Dashboard "FCG — Visão geral"

14 painéis distribuídos em 4 seções:

| Seção | Painéis |
|-------|---------|
| Visão geral | Request rate, taxa de erros, latência p95, requisições em andamento |
| Tráfego | Request rate por serviço e status HTTP, percentis de latência (p50/p95/p99) |
| Erros e detalhe por serviço | Taxa de erros % por serviço, latência p95 por serviço |
| Runtime .NET | Memória em uso, coletas de GC por geração |

O JSON do dashboard está em `k8s/infrastructure/observability/grafana-dashboards/fcg-overview.json` e é carregado no Grafana via ConfigMap + sidecar.

# 🧩 Contrato de descoberta

O `ServiceMonitor` `fcg-services` seleciona automaticamente qualquer `Service` no namespace `fcg-platform` que atenda a:

- Label `app.kubernetes.io/part-of: fcg-platform`
- Label `app.kubernetes.io/component: api`
- Porta nomeada `http` (onde `/metrics` é exposto)

Novos microsserviços que sigam esse padrão são coletados **sem alteração** no ServiceMonitor.

# 🧹 Remoção

```bash
helm uninstall kube-prom -n observability
kubectl delete -k k8s/infrastructure/observability/
```

A stack também é removida automaticamente pelo script de cleanup:

```bash
./scripts/cleanup.sh
```

# 🛠 Troubleshooting

### Login inválido no Grafana com a senha correta

Sintoma: browser mostra `Invalid username or password`. Logs do pod mostram:

```text
too many consecutive incorrect login attempts for user - login for user temporarily blocked
```

Causa: Grafana bloqueia o usuário por ~5 min após 5 tentativas erradas seguidas. Bloqueio é em memória.

Fix: recriar o pod (o DB do Grafana é efêmero via `emptyDir`, contador zera):

```bash
kubectl delete pod -n observability -l app.kubernetes.io/name=grafana
```

### Grafana `OOMKilled`

Sintoma: pod reiniciando com `reason: OOMKilled` em `kubectl describe pod`.

Fix: aumentar `grafana.resources.limits.memory` em `values-kube-prometheus-stack.yaml` e rodar `helm upgrade`.

### `helm upgrade` falha com "another operation in progress"

Fix: rollback para a última revisão saudável:

```bash
helm history kube-prom -n observability
helm rollback kube-prom <REVISION> -n observability --wait
```

### ServiceMonitor `fcg-services` sem alvos

Causas comuns:

1. Microsserviços ainda não implantados no namespace `fcg-platform`. Para validar sem K8s, use o `docker-compose` (já traz Prometheus e Grafana integrados — ver [Docker Compose](../../docker-compose.md)).
2. `Service` do microsserviço sem as labels exigidas.
3. Porta do `Service` não nomeada `http`.

Diagnóstico:

```bash
kubectl get svc -n fcg-platform --show-labels
kubectl get servicemonitor fcg-services -n observability -o yaml
```

### Alteração no dashboard não aparece no Grafana

Causa: o sidecar do Grafana faz polling de ConfigMaps (~15 s). Se ainda assim não atualizar, force refresh no browser (Ctrl+F5) ou abra em janela anônima. Verifique também se o novo ConfigMap foi criado:

```bash
kubectl get cm -n observability -l grafana_dashboard=1
```

# ℹ️ Nota sobre `fcg-notifications`

É um Worker (sem HTTP), sendo migrado para Lambda na Parte 2 do Tech Challenge. A instrumentação Prometheus foi intencionalmente deferida — a função serverless será observada via CloudWatch nativamente.
