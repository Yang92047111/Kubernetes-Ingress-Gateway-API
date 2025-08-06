#!/bin/bash

set -e

echo "🔨 Building and deploying Go app for Ingress..."

# Build Docker image
echo "🐳 Building Docker image..."
cd go-app
docker build -t go-app:latest .
cd ..

# Load image into Kind cluster
echo "📦 Loading image into Kind cluster..."
kind load docker-image go-app:latest --name routing-exp

# Deploy namespace and app
echo "🚀 Deploying namespace and application..."
kubectl apply -f k8s/namespace.yaml

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --namespace routing-experiment \
  --for=condition=available deployment/go-app \
  --timeout=300s

# Check if NGINX Ingress Controller is ready
echo "🔍 Checking NGINX Ingress Controller readiness..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

# Wait for the admission webhook to be ready
echo "⏳ Waiting for NGINX admission webhook to be ready..."
timeout=120
counter=0
while ! kubectl get validatingwebhookconfiguration ingress-nginx-admission >/dev/null 2>&1; do
    if [ $counter -ge $timeout ]; then
        echo "⚠️  Admission webhook not found, but continuing..."
        break
    fi
    echo "   Waiting for admission webhook... ($counter/$timeout)"
    sleep 5
    counter=$((counter + 5))
done

# Test webhook connectivity
echo "🧪 Testing webhook connectivity..."
sleep 10

# Deploy Ingress with retry logic
echo "🌐 Deploying Ingress..."
max_retries=3
retry_count=0

while [ $retry_count -lt $max_retries ]; do
    if kubectl apply -f k8s/ingress/ingress.yaml; then
        echo "✅ Ingress deployed successfully!"
        break
    else
        retry_count=$((retry_count + 1))
        echo "⚠️  Ingress deployment failed (attempt $retry_count/$max_retries)"
        if [ $retry_count -lt $max_retries ]; then
            echo "   Waiting 15 seconds before retry..."
            sleep 15
        else
            echo "❌ Failed to deploy Ingress after $max_retries attempts"
            exit 1
        fi
    fi
done

echo "⏳ Waiting for Ingress to be ready..."
sleep 15

echo "✅ Ingress deployment complete!"
echo "🔍 Ingress status:"
kubectl get ingress -n routing-experiment

echo "🧪 Testing Ingress endpoints:"
echo "Health: curl http://localhost/healthz"
echo "Version: curl http://localhost/version"
echo "Root: curl http://localhost/"