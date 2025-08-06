#!/bin/bash

set -e

echo "🚀 Setting up Kind cluster (simplified approach)..."

# Check if cluster already exists
if kind get clusters | grep -q "routing-exp"; then
    echo "⚠️  Cluster 'routing-exp' already exists. Using existing cluster..."
else
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
fi

echo "⏳ Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo "📦 Installing Gateway API CRDs..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

echo "🌐 Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/kind/deploy.yaml

echo "⏳ Waiting for NGINX Ingress Controller (this may take a few minutes)..."
echo "   Checking deployment status..."

# Wait for deployment to exist
timeout=300
counter=0
while ! kubectl get deployment ingress-nginx-controller -n ingress-nginx >/dev/null 2>&1; do
    if [ $counter -ge $timeout ]; then
        echo "❌ Timeout waiting for NGINX deployment to be created"
        exit 1
    fi
    echo "   Still waiting for deployment to be created... ($counter/$timeout)"
    sleep 5
    counter=$((counter + 5))
done

echo "   Deployment found, waiting for it to be available..."
kubectl wait --namespace ingress-nginx \
  --for=condition=available deployment/ingress-nginx-controller \
  --timeout=600s

echo "✅ NGINX Ingress Controller is ready!"

# Skip Envoy Gateway for now to simplify setup
echo "⚠️  Skipping Envoy Gateway installation for simplified setup"
echo "   You can install it later if needed for Gateway API testing"

echo "✅ Kind cluster setup complete!"
echo "📋 Cluster info:"
kubectl cluster-info --context kind-routing-exp

echo "🔍 Installed components:"
kubectl get pods -A | grep -E "(ingress|gateway)"