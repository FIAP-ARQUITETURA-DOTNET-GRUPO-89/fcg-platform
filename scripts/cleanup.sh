#!/usr/bin/env bash

set -e

echo "🧹 Removendo recursos da plataforma..."

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