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

# Set up port forwarding for Gateway API in Kind
echo "🔗 Setting up port forwarding for Gateway API..."
# Kill any existing port forwarding on port 8080
pkill -f "port-forward.*8080:8080" || true
sleep 2

# Get the Gateway service name
GATEWAY_SERVICE=$(kubectl get service -n envoy-gateway-system -o name | grep envoy-routing-experiment | head -1)
if [ -n "$GATEWAY_SERVICE" ]; then
    echo "   Starting port forwarding: kubectl port-forward -n envoy-gateway-system $GATEWAY_SERVICE 8080:8080"
    kubectl port-forward -n envoy-gateway-system $GATEWAY_SERVICE 8080:8080 > /dev/null 2>&1 &
    sleep 3
    echo "✅ Port forwarding active on localhost:8080"
else
    echo "⚠️  Gateway service not found. Port forwarding not set up."
fi

echo "🧪 Testing Gateway endpoints:"
echo "Health: curl http://localhost:8080/healthz"
echo "Version: curl http://localhost:8080/version"
echo "Root: curl http://localhost:8080/"