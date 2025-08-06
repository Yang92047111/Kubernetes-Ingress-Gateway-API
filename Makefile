.PHONY: help setup build test-unit deploy-ingress deploy-gateway test-routing clean

# Default target
help:
	@echo "🔬 Kubernetes Ingress vs Gateway API Experiment"
	@echo "=============================================="
	@echo ""
	@echo "Available targets:"
	@echo "  setup           - Create Kind cluster with NGINX (recommended)"
	@echo "  setup-full      - Create Kind cluster with all controllers"
	@echo "  build           - Build Go application Docker image"
	@echo "  build-and-load  - Build and load image into Kind cluster"
	@echo "  test-unit       - Run Go unit tests"
	@echo "  deploy-ingress  - Deploy app with Ingress routing (recommended)"
	@echo "  deploy-ingress-alt - Deploy with Ingress (alternative method)"
	@echo "  deploy-gateway  - Deploy app with Gateway API routing"
	@echo "  test-routing    - Test both Ingress and Gateway routing"
	@echo "  test-endpoints  - Quick test of both Ingress and Gateway"
	@echo "  install-gateway - Install Gateway API support (if needed)"
	@echo "  clean           - Clean up Kind cluster and Docker images"
	@echo "  reset           - Clean and setup fresh environment"
	@echo "  logs            - Show application logs"
	@echo "  status          - Show cluster and resource status"
	@echo "  all             - Run complete experiment (setup + deploy + test)"
	@echo ""

# Setup Kind cluster and install controllers (recommended)
setup:
	@echo "🚀 Setting up experiment environment..."
	chmod +x scripts/*.sh
	./scripts/setup-kind-simple.sh

# Setup Kind cluster with all controllers (may have timing issues)
setup-full:
	@echo "🚀 Setting up experiment environment (full)..."
	chmod +x scripts/*.sh
	./scripts/setup-kind.sh

# Build Go application
build:
	@echo "🔨 Building Go application..."
	cd go-app && go mod tidy
	cd go-app && docker build -t go-app:latest .

# Build and load into Kind cluster (requires cluster to exist)
build-and-load: build
	@echo "📦 Loading image into Kind cluster..."
	kind load docker-image go-app:latest --name routing-exp

# Run unit tests
test-unit:
	@echo "🧪 Running Go unit tests..."
	cd go-app && go test -v ./...

# Deploy with Ingress (recommended)
deploy-ingress:
	@echo "🌐 Deploying with Ingress..."
	./scripts/deploy-ingress-simple.sh

# Deploy with Ingress (alternative with webhook handling)
deploy-ingress-alt:
	@echo "🌐 Deploying with Ingress (alternative)..."
	./scripts/deploy-ingress.sh

# Deploy with Gateway API
deploy-gateway:
	@echo "🌉 Deploying with Gateway API..."
	./scripts/deploy-gateway.sh

# Test routing for both approaches
test-routing:
	@echo "🧪 Testing routing..."
	./scripts/test-routing.sh

# Clean up everything
clean:
	@echo "🧹 Cleaning up..."
	-kind delete cluster --name routing-exp
	-docker rmi go-app:latest

# Run complete experiment
all: setup build-and-load test-unit deploy-ingress deploy-gateway test-routing
	@echo "✅ Complete experiment finished!"

# Individual cleanup targets
clean-deployments:
	@echo "🧹 Cleaning up deployments..."
	-kubectl delete namespace routing-experiment

# Show cluster status
status:
	@echo "📊 Cluster Status"
	@echo "================"
	@kubectl cluster-info --context kind-routing-exp
	@echo ""
	@echo "Namespaces:"
	@kubectl get namespaces
	@echo ""
	@echo "Routing Experiment Resources:"
	@kubectl get all -n routing-experiment 2>/dev/null || echo "No resources in routing-experiment namespace"

# Show logs
logs:
	@echo "📋 Application Logs"
	@echo "=================="
	@kubectl logs -n routing-experiment -l app=go-app --tail=50

# Quick test endpoints
test-endpoints:
	@echo "🧪 Testing Endpoints"
	@echo "==================="
	@echo "Testing Ingress (port 80):"
	@curl -s http://localhost/healthz | jq . || echo "❌ Ingress not responding"
	@echo ""
	@echo "Testing Gateway (port 8080):"
	@curl -s http://localhost:8080/healthz | jq . || echo "❌ Gateway not responding"

# Install Gateway API support (run after setup if needed)
install-gateway:
	@echo "🚪 Installing Envoy Gateway..."
	kubectl apply -f https://github.com/envoyproxy/gateway/releases/download/v0.6.0/install.yaml
	kubectl wait --namespace envoy-gateway-system \
	  --for=condition=available deployment/envoy-gateway \
	  --timeout=300s

# Reset experiment (clean + setup)
reset: clean setup
	@echo "🔄 Experiment environment reset complete!"