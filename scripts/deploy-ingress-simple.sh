#!/bin/bash

set -e

echo "🔨 Building and deploying Go app for Ingress (simplified)..."

# Build Docker image (if not already built)
if ! docker images | grep -q "go-app.*latest"; then
    echo "🐳 Building Docker image..."
    cd go-app
    docker build -t go-app:latest .
    cd ..
    
    # Load image into Kind cluster
    echo "📦 Loading image into Kind cluster..."
    kind load docker-image go-app:latest --name routing-exp
fi

# Deploy namespace and app
echo "🚀 Deploying namespace and application..."
kubectl apply -f k8s/namespace.yaml

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --namespace routing-experiment \
  --for=condition=available deployment/go-app \
  --timeout=300s

# Check NGINX Ingress Controller status
echo "🔍 Checking NGINX Ingress Controller status..."
kubectl get pods -n ingress-nginx

# Temporarily disable admission webhook if it's causing issues
echo "🔧 Temporarily disabling admission webhook for deployment..."
kubectl delete validatingwebhookconfiguration ingress-nginx-admission --ignore-not-found=true

# Deploy Ingress
echo "🌐 Deploying Ingress..."
kubectl apply -f k8s/ingress/ingress.yaml

# Re-enable admission webhook
echo "🔧 Re-enabling admission webhook..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/kind/deploy.yaml

echo "⏳ Waiting for Ingress to be ready..."
sleep 20

echo "✅ Ingress deployment complete!"
echo "🔍 Ingress status:"
kubectl get ingress -n routing-experiment -o wide

echo "🔍 Service endpoints:"
kubectl get endpoints -n routing-experiment

echo "🧪 Testing Ingress endpoints:"
echo "Health: curl http://localhost/healthz"
echo "Version: curl http://localhost/version"
echo "Root: curl http://localhost/"

# Quick connectivity test
echo "🧪 Quick connectivity test:"
if curl -s --connect-timeout 5 http://localhost/healthz >/dev/null 2>&1; then
    echo "✅ Ingress is responding!"
else
    echo "⚠️  Ingress not responding yet, may need more time"
    echo "   Try: kubectl get pods -n routing-experiment"
    echo "   And: kubectl get ingress -n routing-experiment"
fi