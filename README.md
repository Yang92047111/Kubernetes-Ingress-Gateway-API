# 🔬 Experiment: Kubernetes Ingress vs Gateway API

## 📌 Objective

This experiment compares Kubernetes Ingress and the Gateway API by deploying and routing a simple Go-based HTTP service in a local Kind cluster. The focus includes setup complexity, flexibility, protocol support, and testability (unit and integration).

## 🚀 Quick Start

**Option 1: Complete Experiment (Recommended)**
```bash
# Run everything in one command
make all
```

**Option 2: Step by Step**
```bash
# 1. Setup Kind cluster with NGINX Ingress
make setup

# 2. Build and load the Go application
make build-and-load

# 3. Run unit tests
make test-unit

# 4. Deploy with Ingress
make deploy-ingress

# 5. Install Gateway API and deploy
make install-gateway
make deploy-gateway

# 6. Test both routing approaches
make test-routing
```

**Option 3: Quick Testing**
```bash
# Test individual endpoints
make test-endpoints
```

---

## 🛠️ Technology Stack

| Component      | Version / Tool             |
|----------------|----------------------------|
| Kubernetes     | Kind (v0.20+)              |
| Gateway API    | v1.0.0 (Standard CRDs)     |
| Ingress        | NGINX Ingress Controller   |
| Gateway        | Envoy Gateway v0.6.0       |
| Go             | 1.21+                      |
| Test Framework | Go built-in `testing`      |
| Tools          | Docker, kubectl, curl      |

---

## 🧱 Folder Structure

```text
k8s-ingress-gateway-api/
├── go-app/
│   ├── main.go              # HTTP server with health/version endpoints
│   ├── handler.go           # HTTP request handlers
│   ├── handler_test.go      # Unit tests
│   ├── go.mod & go.sum      # Go module files
│   └── Dockerfile           # Multi-stage Docker build
├── k8s/
│   ├── namespace.yaml       # Namespace, Deployment, and Service
│   ├── ingress/
│   │   └── ingress.yaml     # NGINX Ingress configuration
│   └── gateway/
│       ├── gateway.yaml     # Gateway API Gateway
│       └── httproute.yaml   # Gateway API HTTPRoute
├── scripts/
│   ├── setup-kind-simple.sh    # Kind cluster setup with NGINX
│   ├── deploy-ingress-simple.sh # Deploy with Ingress
│   ├── deploy-gateway.sh        # Deploy with Gateway API
│   └── test-routing.sh          # Test both approaches
├── Makefile                 # Automation targets
├── README.md               # This file
└── TUTORIAL.md             # Step-by-step guide
````

---

## ✅ Implementation Status

### ⚙️ Setup
* ✅ Kind cluster with necessary ports exposed
* ✅ NGINX Ingress controller installation
* ✅ Gateway API CRDs installation
* ✅ Envoy Gateway deployment (optional)

### 🔨 Application
* ✅ Go HTTP service with health, version, and root endpoints
* ✅ Comprehensive unit tests
* ✅ Multi-stage Dockerfile for optimized builds

### 📦 Kubernetes Resources
* ✅ Namespace, Deployment, and Service manifests
* ✅ Ingress manifest with proper annotations
* ✅ Gateway, GatewayClass, and HTTPRoute resources

### 🧪 Testing
* ✅ Go unit tests for all HTTP handlers
* ✅ Shell integration tests with curl
* ✅ Performance comparison and latency testing
* ✅ Automated test scripts with colored output

### 🧹 Automation
* ✅ Complete Makefile with all targets
* ✅ Robust setup and deployment scripts
* ✅ Error handling and retry logic

---

## 🎯 Available Make Targets

| Target | Description |
|--------|-------------|
| `make all` | **🚀 Run complete experiment (recommended)** |
| `make setup` | Create Kind cluster with NGINX Ingress |
| `make build` | Build Go application Docker image |
| `make build-and-load` | Build and load image into Kind cluster |
| `make test-unit` | Run Go unit tests |
| `make deploy-ingress` | Deploy app with Ingress routing |
| `make deploy-gateway` | Deploy app with Gateway API routing |
| `make install-gateway` | Install Envoy Gateway for Gateway API |
| `make test-routing` | Test both Ingress and Gateway routing |
| `make test-endpoints` | Quick test of both endpoints |
| `make status` | Show cluster and resource status |
| `make logs` | Show application logs |
| `make clean` | Clean up Kind cluster and images |

---

## 🧪 Testing Endpoints

The application exposes three endpoints:

- **Health Check**: `GET /healthz` - Returns service health status
- **Version Info**: `GET /version` - Returns version and build information  
- **Root**: `GET /` - Returns request details and welcome message

### Test with Ingress (port 80):
```bash
curl http://localhost/healthz
curl http://localhost/version
curl http://localhost/
```

### Test with Gateway API (port 8080):
```bash
curl http://localhost:8080/healthz
curl http://localhost:8080/version
curl http://localhost:8080/
```

---

## 🔧 Troubleshooting

### Common Issues and Solutions

**1. NGINX Ingress Controller not ready:**
```bash
# Check controller status
kubectl get pods -n ingress-nginx

# Check if node has required label
kubectl get nodes --show-labels | grep ingress-ready

# Manual fix if needed
kubectl label node routing-exp-control-plane ingress-ready=true
```

**2. Port conflicts:**
```bash
# Check if ports 80/8080 are in use
lsof -i :80
lsof -i :8080

# Clean and restart
make clean
make all
```

**3. Image not found in Kind:**
```bash
# Rebuild and reload image
make build-and-load
```

**4. Gateway not ready:**
```bash
# Check Gateway status
kubectl get gateway -n routing-experiment
kubectl get httproute -n routing-experiment

# Check Envoy Gateway installation
kubectl get pods -n envoy-gateway-system
```

### Recent Improvements

This experiment has been updated to address common issues:

1. **Fixed Ingress path routing**: Reordered paths so specific routes (`/healthz`, `/version`) are matched before the generic root path (`/`)
2. **Automated node labeling**: Added automatic `ingress-ready=true` labeling for NGINX controller scheduling
3. **Cleaned up Makefile**: Removed duplicate and unused targets for better maintainability
4. **Enhanced error handling**: Improved setup scripts with better error detection and recovery

---

## 📊 Experiment Results

### Setup Complexity Comparison

| Aspect | Ingress | Gateway API |
|--------|---------|-------------|
| **Initial Setup** | ✅ Simple (1 controller) | ⚠️ Moderate (CRDs + controller) |
| **Resource Count** | 1 (Ingress) | 3 (GatewayClass, Gateway, HTTPRoute) |
| **Learning Curve** | ✅ Low | ⚠️ Medium |
| **Documentation** | ✅ Mature | ✅ Growing rapidly |
| **Configuration** | ✅ Single resource | ⚠️ Multiple resources |

### Routing Flexibility

| Feature | Ingress | Gateway API |
|---------|---------|-------------|
| **Path Routing** | ✅ Basic patterns | ✅ Advanced matching |
| **Header Matching** | ⚠️ Via annotations | ✅ Native support |
| **Traffic Splitting** | ❌ Very limited | ✅ Built-in weights |
| **Protocol Support** | HTTP/HTTPS only | HTTP/HTTPS/TCP/gRPC |
| **Cross-namespace** | ❌ No | ✅ Yes with ReferenceGrant |
| **Multi-cluster** | ❌ No | ✅ Designed for it |

## 🔍 Key Learnings

### Ingress Advantages
- **Simplicity**: Single resource, familiar API
- **Maturity**: Well-established, extensive ecosystem
- **Tooling**: Excellent IDE support and debugging tools
- **Performance**: Lower overhead for basic routing
- **Quick Setup**: Minimal configuration required

### Gateway API Advantages  
- **Expressiveness**: Rich matching and routing capabilities
- **Extensibility**: Built for future protocols and features
- **Role Separation**: Clear boundaries between infrastructure and application teams
- **Standardization**: Vendor-neutral specification
- **Advanced Features**: Traffic splitting, header manipulation, etc.

### Real-World Considerations
- **Migration Path**: Gateway API provides smooth migration from Ingress
- **Complexity Trade-off**: More power requires more configuration
- **Team Structure**: Gateway API excels in larger, multi-team environments
- **Use Case Fit**: Choose based on current needs vs future requirements
- **Vendor Lock-in**: Gateway API reduces dependency on specific implementations

---

## 📊 Final Comparison

| Criteria | Ingress | Gateway API | Winner |
|----------|---------|-------------|---------|
| **Setup Complexity** | ✅ Simple (1 controller) | ⚠️ Moderate (CRDs + controller) | Ingress |
| **Routing Flexibility** | ⚠️ Limited (annotations) | ✅ Rich (native matching) | Gateway API |
| **Multi-Protocol** | ⚠️ HTTP/HTTPS only | ✅ HTTP/HTTPS/TCP/gRPC | Gateway API |
| **Team Separation** | ❌ Single resource | ✅ Role-based separation | Gateway API |
| **Maturity & Stability** | ✅ Very stable, widely adopted | ✅ Stable (v1.0), growing adoption | Tie |
| **Learning Curve** | ✅ Low | ⚠️ Medium | Ingress |
| **Future-Proofing** | ⚠️ Limited evolution path | ✅ Designed for extensibility | Gateway API |
| **Performance** | ✅ Lower overhead | ⚠️ Slight overhead | Ingress |

### 🏆 Recommendation

**Choose Ingress when:**
- Simple HTTP routing is sufficient
- Quick setup is priority
- Team has existing Ingress expertise
- Single-team environment
- Basic load balancing needs

**Choose Gateway API when:**
- Complex routing requirements
- Multi-protocol support needed
- Planning for future growth
- Multi-team environments
- Advanced traffic management features required

---

## 📃 License

This experiment is open-sourced under the **MIT License**.

---

## 🎯 Conclusion

This experiment demonstrates that both Ingress and Gateway API are valuable tools in the Kubernetes ecosystem:

- **Ingress** remains excellent for straightforward HTTP routing with minimal complexity
- **Gateway API** provides superior flexibility and extensibility for advanced use cases

Both approaches work reliably when properly configured. The choice should be based on your specific requirements, team expertise, and architectural goals.

### Key Takeaways
1. **Both solutions work well** for basic HTTP routing
2. **Path ordering matters** in Ingress configurations (specific paths before generic ones)
3. **Node labeling is critical** for NGINX Ingress Controller scheduling
4. **Gateway API offers more granular control** at the cost of increased complexity
5. **Migration path exists** from Ingress to Gateway API when needs evolve

## 🤝 Contributions

Contributions are welcome! Feel free to:
- Open issues for bugs or improvements
- Submit PRs for additional controller examples
- Add more test scenarios
- Improve documentation

**Areas for expansion:**
- Istio Gateway integration
- TLS/SSL configuration examples
- Performance benchmarking
- Multi-cluster scenarios

