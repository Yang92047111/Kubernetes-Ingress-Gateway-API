# 🔬 Experiment: Kubernetes Ingress vs Gateway API

## 📌 Objective

This experiment compares Kubernetes Ingress and the Gateway API by deploying and routing a simple Go-based HTTP service in a local Kind cluster. The focus includes setup complexity, flexibility, protocol support, and testability (unit and integration).

## 🚀 Quick Start

```bash
# 1. Setup Kind cluster with NGINX Ingress
make setup

# 2. Build and load the Go application
make build-and-load

# 3. Run unit tests
make test-unit

# 4. Deploy with Ingress
make deploy-ingress

# 5. Install Gateway API, Deploy and test
make install-gateway
make deploy-gateway

# 6. Test the endpoints
make test-endpoints
```

---

## 🛠️ Technology Stack

| Component      | Version / Tool             |
|----------------|----------------------------|
| Kubernetes     | Kind (v0.23+)              |
| Gateway API    | v1.0.0 (Standard CRDs)     |
| Ingress        | NGINX Ingress Controller   |
| Gateway        | Envoy Gateway or Istio     |
| Go             | 1.21+                      |
| Test Framework | `testing`, `httptest`      |
| Scripting      | Bash + Curl + kubectl      |

---

## 🧱 Folder Structure

```text
k8s-routing-experiment/
├── go-app/
│   ├── main.go
│   ├── handler.go
│   ├── handler_test.go
│   └── Dockerfile
├── k8s/
│   ├── ingress/
│   │   └── ingress.yaml
│   ├── gateway/
│   │   ├── gateway.yaml
│   │   └── httproute.yaml
│   └── namespace.yaml
├── scripts/
│   ├── setup-kind.sh
│   ├── deploy-ingress.sh
│   ├── deploy-gateway.sh
│   └── test-routing.sh
├── Makefile
└── README.md
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
| `make setup` | Create Kind cluster with NGINX (recommended) |
| `make setup-full` | Create Kind cluster with all controllers |
| `make build` | Build Go application Docker image |
| `make build-and-load` | Build and load image into Kind cluster |
| `make test-unit` | Run Go unit tests |
| `make deploy-ingress` | Deploy app with Ingress routing |
| `make deploy-gateway` | Deploy app with Gateway API routing |
| `make test-routing` | Test both Ingress and Gateway routing |
| `make test-endpoints` | Quick test of endpoints |
| `make install-gateway` | Install Gateway API support |
| `make clean` | Clean up Kind cluster and images |
| `make reset` | Clean and setup fresh environment |
| `make all` | Run complete experiment |

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
kubectl describe pod -n ingress-nginx -l app.kubernetes.io/component=controller

# Use alternative setup if needed
make setup-full
```

**2. Webhook admission errors:**
```bash
# Use alternative deployment method
make deploy-ingress-alt
```

**3. Port conflicts:**
```bash
# Check if ports 80/8080 are in use
lsof -i :80
lsof -i :8080

# Clean and restart
make reset
```

**4. Image not found in Kind:**
```bash
# Rebuild and reload image
make build-and-load
```

---

## 📊 Experiment Results

### Setup Complexity Comparison

| Aspect | Ingress | Gateway API |
|--------|---------|-------------|
| **Initial Setup** | ✅ Simple (1 controller) | ⚠️ Moderate (CRDs + controller) |
| **Resource Count** | 1 (Ingress) | 3 (GatewayClass, Gateway, HTTPRoute) |
| **Learning Curve** | ✅ Low | ⚠️ Medium |
| **Documentation** | ✅ Mature | ⚠️ Evolving |

### Routing Flexibility

| Feature | Ingress | Gateway API |
|---------|---------|-------------|
| **Path Routing** | ✅ Basic | ✅ Advanced |
| **Header Matching** | ⚠️ Annotations | ✅ Native |
| **Traffic Splitting** | ❌ Limited | ✅ Built-in |
| **Protocol Support** | HTTP/HTTPS | HTTP/HTTPS/TCP/gRPC |
| **Cross-namespace** | ❌ No | ✅ Yes |

## 🔍 Key Learnings

### Ingress Advantages
- **Simplicity**: Single resource type, familiar to most developers
- **Maturity**: Well-established with extensive documentation
- **Tooling**: Excellent IDE support and debugging tools
- **Performance**: Lower overhead for simple routing scenarios

### Gateway API Advantages  
- **Expressiveness**: Rich matching and filtering capabilities
- **Extensibility**: Built for future protocol and feature additions
- **Role Separation**: Clear boundaries between infrastructure and application teams
- **Standardization**: Vendor-neutral specification across implementations

### Real-World Considerations
- **Migration Path**: Gateway API provides smooth migration from Ingress
- **Complexity Trade-off**: More power comes with increased complexity
- **Team Structure**: Gateway API shines in larger, multi-team environments
- **Use Case Fit**: Choose based on current needs vs future requirements

---

## 📊 Final Comparison

| Criteria | Ingress | Gateway API | Winner |
|----------|---------|-------------|---------|
| **Setup Complexity** | ✅ Simple (1 controller) | ⚠️ Moderate (CRDs + controller) | Ingress |
| **Routing Flexibility** | ⚠️ Limited (annotations) | ✅ Rich (native matching) | Gateway API |
| **Multi-Protocol** | ⚠️ HTTP/HTTPS only | ✅ HTTP/HTTPS/TCP/gRPC | Gateway API |
| **Team Separation** | ❌ Single resource | ✅ Role-based separation | Gateway API |
| **Maturity** | ✅ Stable, widely adopted | ⚠️ Newer, evolving | Ingress |
| **Learning Curve** | ✅ Low | ⚠️ Medium | Ingress |
| **Future-Proofing** | ⚠️ Limited evolution | ✅ Designed for growth | Gateway API |

### 🏆 Recommendation

- **Use Ingress** for: Simple HTTP routing, quick setup, existing expertise
- **Use Gateway API** for: Complex routing, multi-protocol, future-proofing, team separation

---

## 📃 License

This experiment is open-sourced under the **MIT License**.

---

## 🎯 Conclusion

This experiment demonstrates that both Ingress and Gateway API have their place in the Kubernetes ecosystem:

- **Ingress** remains the go-to choice for straightforward HTTP routing with minimal setup overhead
- **Gateway API** offers superior flexibility and future-proofing for complex routing requirements

The choice depends on your specific needs, team structure, and long-term architectural goals.

## 🤝 Contributions

Feel free to open issues or PRs for improvements, fixes, or different ingress/gateway controller examples!

