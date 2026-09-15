#!/usr/bin/env bash

set -e

echo "🧹 Removendo recursos da plataforma..."

echo ""
echo "📈 Removendo stack de observabilidade..."
if command -v helm >/dev/null 2>&1; then
  helm uninstall kube-prom -n observability --ignore-not-found >/dev/null 2>&1 || true
else
  echo "⚠️  Helm não encontrado. Pule este passo ou remova o release manualmente."
fi
kubectl delete -k k8s/infrastructure/observability/ --ignore-not-found
kubectl delete namespace observability --ignore-not-found

echo ""
echo "🚪 Removendo Kong API Gateway..."
kubectl delete -k k8s/infrastructure/kong/ --ignore-not-found

echo ""
echo "💳 Removendo FCG Payments Worker..."
kubectl delete -f microservices/fcg-payments/k8s/worker/ --ignore-not-found

echo ""
echo "💳 Removendo FCG Payments API..."
kubectl delete -f microservices/fcg-payments/k8s/api/ --ignore-not-found

echo ""
echo "🎮 Removendo FCG Catalog Worker..."
kubectl delete -f microservices/fcg-catalog/k8s/worker/ --ignore-not-found

echo ""
echo "🎮 Removendo FCG Catalog API..."
kubectl delete -f microservices/fcg-catalog/k8s/api/ --ignore-not-found

echo ""
echo "🔔 Removendo FCG Notifications Worker..."
kubectl delete -f microservices/fcg-notifications/k8s/worker/ --ignore-not-found

echo ""
echo "👤 Removendo FCG Users API..."
kubectl delete -f microservices/fcg-users/k8s/api/ --ignore-not-found

echo ""
echo "🔴 Removendo Redis..."
kubectl delete -f k8s/infrastructure/redis/ --ignore-not-found

echo ""
echo "🍃 Removendo MongoDB..."
kubectl delete -f k8s/infrastructure/mongodb/ --ignore-not-found

echo ""
echo "🐇 Removendo RabbitMQ..."
kubectl delete -f k8s/infrastructure/rabbitmq/ --ignore-not-found

echo ""
echo "🐘 Removendo PostgreSQL..."
kubectl delete -f k8s/infrastructure/postgres/ --ignore-not-found

echo ""
echo "📦 Removendo namespace..."
kubectl delete -f k8s/namespace.yaml --ignore-not-found

echo ""
echo "✅ Limpeza concluída."