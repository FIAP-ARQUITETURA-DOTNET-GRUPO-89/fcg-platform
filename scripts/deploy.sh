#!/usr/bin/env bash

set -e

NAMESPACE="fcg-platform"

echo "🚀 Iniciando deploy da plataforma..."

echo ""
echo "📦 Criando namespace..."
kubectl apply -f k8s/namespace.yaml

echo ""
echo "🐘 Deploy do PostgreSQL..."
kubectl apply -f k8s/infrastructure/postgres/configmap.yaml
kubectl apply -f k8s/infrastructure/postgres/secret.yaml
kubectl apply -f k8s/infrastructure/postgres/pvc.yaml
kubectl apply -f k8s/infrastructure/postgres/deployment.yaml
kubectl apply -f k8s/infrastructure/postgres/service.yaml

echo ""
echo "🐇 Deploy do RabbitMQ..."
kubectl apply -f k8s/infrastructure/rabbitmq/configmap.yaml
kubectl apply -f k8s/infrastructure/rabbitmq/secret.yaml
kubectl apply -f k8s/infrastructure/rabbitmq/pvc.yaml
kubectl apply -f k8s/infrastructure/rabbitmq/deployment.yaml
kubectl apply -f k8s/infrastructure/rabbitmq/service.yaml

echo ""
echo "⏳ Aguardando PostgreSQL..."
kubectl rollout status deployment/postgres -n "${NAMESPACE}"

echo ""
echo "⏳ Aguardando RabbitMQ..."
kubectl rollout status deployment/rabbitmq -n "${NAMESPACE}"

echo ""
echo "👤 Deploy do FCG Users API..."
kubectl apply -f microservices/fcg-users/k8s/api/

echo ""
echo "👷 Deploy do FCG Notifications Worker..."
kubectl apply -f microservices/fcg-notifications/k8s/worker/

echo ""
echo "🎮 Deploy do FCG Catalog API..."
kubectl apply -f microservices/fcg-catalog/k8s/api/

echo ""
echo "👷 Deploy do FCG Catalog Worker..."
kubectl apply -f microservices/fcg-catalog/k8s/worker/

echo ""
echo "💳 Deploy do FCG Payments API..."
kubectl apply -f microservices/fcg-payments/k8s/api/

echo ""
echo "👷 Deploy do FCG Payments Worker..."
kubectl apply -f microservices/fcg-payments/k8s/worker/

echo ""
echo "📋 Recursos implantados:"
kubectl get all -n "${NAMESPACE}"

echo ""
echo "✅ Deploy concluído com sucesso."