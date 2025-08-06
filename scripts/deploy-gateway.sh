#!/bin/bash

set -e

echo "🔨 Deploying Go app for Gateway API..."

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

# Deploy namespace and app (if not already deployed)
echo "🚀 Ensuring namespace and application are deployed..."
kubectl apply -f k8s/namespace.yaml

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --namespace routing-experiment \
  --for=condition=available deployment/go-app \
  --timeout=300s

# Deploy Gateway resources
echo "🌉 Deploying Gateway and HTTPRoute..."
kubectl apply -f k8s/gateway/gateway.yaml
kubectl apply -f k8s/gateway/httproute.yaml

echo "⏳ Waiting for Gateway to be ready..."
sleep 15

echo "✅ Gateway deployment complete!"
echo "🔍 Gateway status:"
kubectl get gateway -n routing-experiment
kubectl get httproute -n routing-experiment

echo "🧪 Testing Gateway endpoints:"
echo "Health: curl http://localhost:8080/healthz"
echo "Version: curl http://localhost:8080/version"
echo "Root: curl http://localhost:8080/"