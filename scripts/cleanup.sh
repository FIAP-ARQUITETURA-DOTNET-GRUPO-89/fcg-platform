#!/usr/bin/env bash

set -e

NAMESPACE="fcg-platform"

echo "🚀 Iniciando deploy da plataforma..."

echo ""
echo "📦 Criando namespace..."
kubectl apply -f k8s/namespace.yaml

echo ""
echo "🐘 Deploy do PostgreSQL..."
kubectl apply -f k8s/infrastructure/postgres/

echo ""
echo "🐇 Deploy do RabbitMQ..."
kubectl apply -f k8s/infrastructure/rabbitmq/

echo ""
echo "👤 Deploy do FCG Users API..."
kubectl apply -f microservices/fcg-users/k8s/api/

echo ""
echo "👷 Deploy do FCG Users Worker..."
kubectl apply -f microservices/fcg-users/k8s/worker/

echo ""
echo "📋 Recursos implantados:"
kubectl get all -n "${NAMESPACE}"

echo ""
echo "✅ Deploy concluído com sucesso."