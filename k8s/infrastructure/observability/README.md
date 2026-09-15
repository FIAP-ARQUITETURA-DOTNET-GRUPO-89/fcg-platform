# Observabilidade — Prometheus + Grafana (Kubernetes)

Stack de observabilidade da FCG Platform para o cluster Kubernetes.

- **Prometheus** coleta métricas dos microsserviços via `ServiceMonitor` no formato Prometheus.
- **Grafana** exibe dashboards em tempo real (latência, request rate, error rate).
- **kube-state-metrics** e **node-exporter** cobrem métricas de infraestrutura K8s.

Alertmanager está desabilitado por não ser exigido pelo desafio.

> Para desenvolvimento local via `docker-compose`, os serviços `prometheus` e `grafana` já estão inclusos em `docker-compose.yml` e `docker-compose-development.yml` — basta `docker compose up` e acessar `http://localhost:3000` (admin / admin). Os arquivos de configuração ficam em `docker/infrastructure/prometheus/` e `docker/infrastructure/grafana/`.

## Pré-requisitos

- Cluster Kubernetes acessível via `kubectl`.
- [Helm 3](https://helm.sh/) instalado.
- Namespace `fcg-platform` com os microsserviços (`fcg-users-api`, `fcg-catalog-api`, `fcg-payments-api`) já implantados e expondo `/metrics`.

## Instalação

```bash
# 1. Namespace + ServiceMonitor (via kustomize)
kubectl apply -k k8s/infrastructure/observability/

# 2. Repo Helm do kube-prometheus-stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 3. Instalar o stack (CRDs + Prometheus + Grafana + exporters)
#
# IMPORTANTE: sobrescreva a senha padrão do Grafana com --set ou um values file
# adicional. O placeholder CHANGE_ME_BEFORE_PROD no values-kube-prometheus-stack
# NÃO deve chegar em nenhum ambiente compartilhado.
helm upgrade --install kube-prom prometheus-community/kube-prometheus-stack \
  --namespace observability \
  --values k8s/infrastructure/observability/values-kube-prometheus-stack.yaml \
  --set grafana.adminPassword="$GRAFANA_ADMIN_PASSWORD" \
  --wait
```

## Acesso

```bash
# Grafana — usuário: admin  senha: a que foi passada no install/upgrade
kubectl port-forward -n observability svc/kube-prom-grafana 3000:80

# Prometheus UI (para inspecionar targets)
kubectl port-forward -n observability svc/kube-prom-kube-prom-prometheus 9090:9090
```

Abrir `http://localhost:3000` (Grafana) e `http://localhost:9090/targets` (Prometheus).

## Validação

1. Em Prometheus → **Status → Targets**, os pods do `fcg-services` ServiceMonitor devem aparecer `UP`.
2. Em Grafana, abrir o dashboard **FCG — Visão geral** (uid `fcg-overview`) — provisionado automaticamente pelo sidecar a partir de `grafana-dashboards/fcg-overview.json`.
3. Gerar carga contra o Kong:
   ```bash
   kubectl port-forward -n fcg-platform svc/kong-proxy 8000:80
   hey -z 60s -c 20 http://localhost:8000/users/api/games
   ```
   Latência p95 e request rate devem responder em <15s no dashboard.

## Contrato de descoberta

O `ServiceMonitor` `fcg-services` seleciona automaticamente qualquer `Service` no namespace `fcg-platform` que atenda a:

- `app.kubernetes.io/part-of: fcg-platform`
- `app.kubernetes.io/component: api`
- porta nomeada `http` (onde `/metrics` é exposto)

Novos microsserviços que sigam esse padrão são coletados sem alteração aqui.

## Nota sobre `fcg-notifications`

É um Worker (sem HTTP), sendo migrado para Lambda na Parte 2. A instrumentação Prometheus foi intencionalmente deferida — a função serverless será observada via CloudWatch nativamente.

## Uninstall

```bash
helm uninstall kube-prom -n observability
kubectl delete -k k8s/infrastructure/observability/
```

## Troubleshooting

### Login inválido no Grafana com a senha correta

Sintoma: browser mostra "Invalid username or password" mesmo com `admin / admin`. Logs do pod (`kubectl logs -n observability <grafana-pod> -c grafana`) mostram:

```
"too many consecutive incorrect login attempts for user - login for user temporarily blocked"
```

Causa: Grafana bloqueia o usuário por ~5 min após 5 tentativas erradas seguidas. Bloqueio é em memória.

Fix: recriar o pod, o que zera o contador (DB do Grafana é efêmero via `emptyDir`):

```bash
kubectl delete pod -n observability -l app.kubernetes.io/name=grafana
```

### Grafana `OOMKilled`

Sintoma: pod fica reiniciando, `kubectl describe pod` mostra `reason: OOMKilled` no `lastState`.

Causa: o limite padrão de 512Mi ainda pode ser insuficiente se você habilitar muitos plugins ou rodar `grafana-cli` dentro do container (o CLI Java consome memória extra).

Fix: aumentar `grafana.resources.limits.memory` em `values-kube-prometheus-stack.yaml` e rodar `helm upgrade`.

### `port-forward` falha com "Only one usage of each socket address"

Sintoma:

```
Unable to listen on port 3000: bind: Only one usage of each socket address ... is normally permitted
```

Causa: outro processo (ou um `kubectl port-forward` órfão) já está ocupando a porta local.

Fix (Windows PowerShell):

```powershell
# Descobrir PID
Get-NetTCPConnection -LocalPort 3000 -State Listen | Select-Object OwningProcess

# Matar
Stop-Process -Id <PID> -Force
```

Ou apenas escolher outra porta local: `kubectl port-forward ... 3001:80`.

### `helm upgrade` falha com "another operation in progress"

Sintoma:

```
Error: UPGRADE FAILED: another operation (install/upgrade/rollback) is in progress
```

Causa: um `helm upgrade` anterior foi interrompido (Ctrl+C, timeout) e o release ficou com status `pending-upgrade`.

Fix: fazer rollback para a última revisão saudável:

```bash
helm history kube-prom -n observability
# identificar a última com STATUS=deployed
helm rollback kube-prom <REVISION> -n observability --wait
```

Depois pode reexecutar o `helm upgrade` normalmente.

### ServiceMonitor `fcg-services` sem alvos

Sintoma: `Prometheus → Status → Targets` não lista `fcg-services`, ou lista com "0 / 0 up".

Causas comuns:
1. Microsserviços ainda não foram implantados no namespace `fcg-platform`. Para validar localmente sem K8s, use o `docker-compose` (já traz Prometheus e Grafana integrados).
2. Service do microsserviço não tem as labels exigidas (`app.kubernetes.io/part-of: fcg-platform` + `component: api`).
3. Porta do Service não está nomeada `http`.

Diagnóstico:

```bash
kubectl get svc -n fcg-platform --show-labels
kubectl get servicemonitor fcg-services -n observability -o yaml
```

### Alteração no dashboard não aparece no Grafana

Sintoma: editou o JSON, aplicou o kustomize, mas o dashboard no browser continua igual.

Causa: o sidecar do Grafana faz polling de ConfigMaps (~15 s). Se ainda assim não atualizar, o browser pode estar cacheando; force refresh (Ctrl+F5) ou abra em janela anônima.

Também verifique se o novo ConfigMap foi criado e o antigo (com hash diferente) pode ser removido:

```bash
kubectl get cm -n observability -l grafana_dashboard=1
kubectl delete cm <configmap-antigo> -n observability
```
