#!/bin/bash

set -e

echo "🚀 Setting up Kind cluster for routing experiment..."

# Check if cluster already exists
if kind get clusters | grep -q "routing-exp"; then
    echo "⚠️  Cluster 'routing-exp' already exists. Deleting and recreating..."
    kind delete cluster --name routing-exp
fi

# Create Kind cluster with port mappings
echo "🏗️  Creating Kind cluster..."
kind create cluster --name routing-exp --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 8080
    hostPort: 8080
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF

echo "⏳ Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo "📦 Installing Gateway API CRDs..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

echo "🌐 Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/kind/deploy.yaml

echo "⏳ Waiting for NGINX Ingress namespace to be created..."
kubectl wait --for=condition=Ready --timeout=60s namespace/ingress-nginx || true

echo "⏳ Waiting for NGINX Ingress deployment to be available..."
kubectl wait --namespace ingress-nginx \
  --for=condition=available deployment/ingress-nginx-controller \
  --timeout=600s

echo "⏳ Waiting for NGINX Ingress Controller pod to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=600s

echo "🔍 Checking NGINX Ingress Controller status..."
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

echo "🚪 Installing Envoy Gateway..."
kubectl apply -f https://github.com/envoyproxy/gateway/releases/download/v0.6.0/install.yaml

echo "⏳ Waiting for Envoy Gateway to be ready..."
kubectl wait --namespace envoy-gateway-system \
  --for=condition=available deployment/envoy-gateway \
  --timeout=300s

echo "✅ Kind cluster setup complete!"
echo "📋 Cluster info:"
kubectl cluster-info --context kind-routing-exp