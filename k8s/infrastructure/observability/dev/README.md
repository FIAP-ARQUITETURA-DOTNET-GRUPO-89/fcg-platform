# Overlays de desenvolvimento — NÃO USAR EM PRODUÇÃO

Arquivos aqui existem apenas para reproduzir a stack localmente quando os microsserviços estão rodando via `docker-compose` (fora do cluster K8s).

## `values-local-docker-compose.yaml`

Adiciona jobs de scrape estáticos apontando para `host.docker.internal:7010/7030/7040` — endpoints válidos apenas no Docker Desktop, onde o cluster K8s consegue resolver o host.

Uso:

```bash
helm upgrade --install kube-prom prometheus-community/kube-prometheus-stack \
  --namespace observability \
  -f k8s/infrastructure/observability/values-kube-prometheus-stack.yaml \
  -f k8s/infrastructure/observability/dev/values-local-docker-compose.yaml
```

Em qualquer ambiente que não seja Docker Desktop local:

- Não passe `-f dev/values-local-docker-compose.yaml`.
- Os alvos serão descobertos automaticamente pelo `ServiceMonitor` `fcg-services`, desde que os microsserviços estejam implantados no cluster com as labels padrão.
