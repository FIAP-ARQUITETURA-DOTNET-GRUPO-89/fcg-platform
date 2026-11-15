#!/usr/bin/env bash

set -e

NAMESPACE="fcg-platform"

# Aplica os manifestos de uma pasta, exceto secret*.yaml: as credenciais vêm do
# .env (scripts/secrets.sh k8s) e nunca de arquivos versionados.
apply_dir() {
  local file
  for file in "$1"/*.yaml; do
    case "$(basename "$file")" in
      secret*.yaml) echo "   ⏭️  ignorando $file (credenciais vêm do .env)" ;;
      *) kubectl apply -f "$file" ;;
    esac
  done
}

echo "🚀 Iniciando deploy da plataforma..."

echo ""
echo "📦 Criando namespace..."
kubectl apply -f k8s/namespace.yaml

echo ""
echo "🔐 Criando Secrets a partir do .env..."
bash scripts/secrets.sh k8s

echo ""
echo "🐘 Deploy do PostgreSQL..."
kubectl apply -f k8s/infrastructure/postgres/configmap.yaml
kubectl apply -f k8s/infrastructure/postgres/pvc.yaml
kubectl apply -f k8s/infrastructure/postgres/deployment.yaml
kubectl apply -f k8s/infrastructure/postgres/service.yaml

echo ""
echo "🐇 Deploy do RabbitMQ..."
kubectl apply -f k8s/infrastructure/rabbitmq/configmap.yaml
kubectl apply -f k8s/infrastructure/rabbitmq/pvc.yaml
kubectl apply -f k8s/infrastructure/rabbitmq/deployment.yaml
kubectl apply -f k8s/infrastructure/rabbitmq/service.yaml

echo ""
echo "🔴 Deploy do Redis..."
kubectl apply -f k8s/infrastructure/redis/deployment.yaml
kubectl apply -f k8s/infrastructure/redis/service.yaml

echo ""
echo "🍃 Deploy do MongoDB..."
kubectl apply -f k8s/infrastructure/mongodb/pvc.yaml
kubectl apply -f k8s/infrastructure/mongodb/deployment.yaml
kubectl apply -f k8s/infrastructure/mongodb/service.yaml

echo ""
echo "🔎 Deploy do OpenSearch..."
kubectl apply -f k8s/infrastructure/opensearch/deployment.yaml
kubectl apply -f k8s/infrastructure/opensearch/service.yaml

echo ""
echo "⏳ Aguardando PostgreSQL..."
kubectl rollout status deployment/postgres -n "${NAMESPACE}"

echo ""
echo "⏳ Aguardando RabbitMQ..."
kubectl rollout status deployment/rabbitmq -n "${NAMESPACE}"

echo ""
echo "⏳ Aguardando Redis..."
kubectl rollout status deployment/fcg-redis -n "${NAMESPACE}"

echo ""
echo "⏳ Aguardando MongoDB..."
kubectl rollout status deployment/mongodb -n "${NAMESPACE}"

echo ""
echo "⏳ Aguardando OpenSearch..."
kubectl rollout status deployment/fcg-opensearch -n "${NAMESPACE}"

echo ""
echo "👤 Deploy do FCG Users API..."
apply_dir microservices/fcg-users/k8s/api

echo ""
echo "👷 Deploy do FCG Notifications Worker..."
apply_dir microservices/fcg-notifications/k8s/worker

echo ""
echo "🎮 Deploy do FCG Catalog API..."
apply_dir microservices/fcg-catalog/k8s/api

echo ""
echo "👷 Deploy do FCG Catalog Worker..."
apply_dir microservices/fcg-catalog/k8s/worker

echo ""
echo "💳 Deploy do FCG Payments API..."
apply_dir microservices/fcg-payments/k8s/api

echo ""
echo "👷 Deploy do FCG Payments Worker..."
apply_dir microservices/fcg-payments/k8s/worker

echo ""
echo "🚪 Deploy do Kong API Gateway..."
kubectl apply -k k8s/infrastructure/kong/

echo ""
echo "⏳ Aguardando Kong API Gateway..."
kubectl rollout status deployment/kong -n "${NAMESPACE}"

echo ""
echo "📈 Deploy da stack de observabilidade (Prometheus + Grafana)..."

if ! command -v helm >/dev/null 2>&1; then
  echo "⚠️  Helm não encontrado. Pulando a instalação da stack de observabilidade."
  echo "    Instale o Helm 3 (https://helm.sh/) e reexecute o script para provisioná-la."
else
  kubectl apply -k k8s/infrastructure/observability/

  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null
  helm repo update >/dev/null

  helm upgrade --install kube-prom prometheus-community/kube-prometheus-stack \
    --namespace observability \
    --values k8s/infrastructure/observability/values-kube-prometheus-stack.yaml \
    --wait

  echo ""
  echo "🔑 Grafana admin: usuário e senha definidos em GRAFANA_ADMIN_USER / GRAFANA_ADMIN_PASSWORD no .env."
fi

echo ""
echo "📋 Recursos implantados:"
kubectl get all -n "${NAMESPACE}"

echo ""
echo "✅ Deploy concluído com sucesso."