# 📚 Kubernetes Ingress vs Gateway API: Complete Tutorial

## Table of Contents
1. [Introduction](#introduction)
2. [Kubernetes Ingress](#kubernetes-ingress)
3. [Gateway API](#gateway-api)
4. [Key Differences](#key-differences)
5. [Architecture Diagrams](#architecture-diagrams)
6. [Practical Examples](#practical-examples)
7. [Migration Path](#migration-path)
8. [Best Practices](#best-practices)
9. [Conclusion](#conclusion)

---

## Introduction

Kubernetes provides two main approaches for exposing services to external traffic: **Ingress** and the newer **Gateway API**. This tutorial explores both approaches, their differences, and when to use each one.

### What Problem Do They Solve?

Both Ingress and Gateway API solve the challenge of:
- Exposing internal Kubernetes services to external clients
- Managing HTTP/HTTPS routing
- Handling SSL termination
- Load balancing traffic
- Managing traffic policies

---

## Kubernetes Ingress

### Overview
Kubernetes Ingress is the traditional way to expose HTTP and HTTPS routes from outside the cluster to services within the cluster. It was introduced in Kubernetes 1.1 and has been the standard for years.

### Core Components

#### 1. Ingress Resource
Defines the routing rules and configuration:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: go-app-ingress
  namespace: routing-experiment
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: localhost
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: go-app
            port:
              number: 80
```

#### 2. Ingress Controller
The actual implementation that processes Ingress resources:
- **NGINX Ingress Controller** (most popular)
- **Traefik**
- **HAProxy**
- **Istio Gateway**
- **AWS Load Balancer Controller**

#### 3. IngressClass
Specifies which controller should handle the Ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx
spec:
  controller: k8s.io/ingress-nginx
```

### How Ingress Works

1. **Define Routes**: Create an Ingress resource with routing rules
2. **Controller Processing**: Ingress controller watches for Ingress resources
3. **Configuration Update**: Controller updates its configuration (e.g., NGINX config)
4. **Traffic Routing**: External traffic flows through the controller to services

### Ingress Capabilities

✅ **Strengths:**
- Simple and well-established
- Wide controller ecosystem
- Good for basic HTTP/HTTPS routing
- Mature tooling and documentation

❌ **Limitations:**
- Limited to HTTP/HTTPS only
- Controller-specific annotations for advanced features
- No native support for other protocols (TCP, UDP, gRPC)
- Configuration tied to implementation details
- Limited traffic splitting capabilities

---

## Gateway API

### Overview
Gateway API is the next-generation standard for service networking in Kubernetes. It's designed to be more expressive, extensible, and role-oriented than Ingress.

### Core Components

#### 1. GatewayClass
Defines the type of gateway and its controller:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: envoy-gateway
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
```

#### 2. Gateway
Represents the actual gateway instance:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: go-app-gateway
  namespace: routing-experiment
spec:
  gatewayClassName: envoy-gateway
  listeners:
  - name: http
    protocol: HTTP
    port: 8080
    allowedRoutes:
      namespaces:
        from: Same
```

#### 3. Route Resources
Define how requests are routed to services:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: go-app-route
  namespace: routing-experiment
spec:
  parentRefs:
  - name: go-app-gateway
  hostnames:
  - "localhost"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: go-app
      port: 80
```

### Route Types
- **HTTPRoute**: HTTP/HTTPS traffic
- **GRPCRoute**: gRPC traffic
- **TCPRoute**: TCP traffic
- **UDPRoute**: UDP traffic
- **TLSRoute**: TLS-encrypted traffic

### How Gateway API Works

1. **Install GatewayClass**: Define the gateway implementation
2. **Create Gateway**: Instantiate a gateway with listeners
3. **Configure Routes**: Create route resources that reference the gateway
4. **Traffic Flow**: External traffic flows through gateway to services

### Gateway API Capabilities

✅ **Strengths:**
- Protocol-agnostic (HTTP, gRPC, TCP, UDP, TLS)
- Role-oriented design (infrastructure vs application teams)
- Extensible without vendor-specific annotations
- Built-in support for advanced features (traffic splitting, header manipulation)
- Clear separation of concerns
- Standardized across implementations

❌ **Limitations:**
- Newer standard (less mature ecosystem)
- More complex for simple use cases
- Limited controller implementations (growing)

---

## Key Differences

| Aspect | Ingress | Gateway API |
|--------|---------|-------------|
| **Protocols** | HTTP/HTTPS only | HTTP, HTTPS, gRPC, TCP, UDP, TLS |
| **Extensibility** | Annotations (vendor-specific) | Native API fields (standardized) |
| **Role Separation** | Single resource | Multiple resources for different roles |
| **Traffic Management** | Basic routing | Advanced (splitting, mirroring, etc.) |
| **Maturity** | Stable, widely adopted | Beta/Stable, growing adoption |
| **Complexity** | Simple for basic use cases | More powerful but complex |
| **Multi-tenancy** | Limited | Built-in support |
| **Configuration** | Single Ingress resource | GatewayClass + Gateway + Routes |

---

## Architecture Diagrams

### Ingress Architecture

```
┌─────────────────┐    ┌───────────────────┐    ┌─────────────────┐
│   External      │    │   Ingress         │    │   Kubernetes    │
│   Client        │    │   Controller      │    │   Services      │
│                 │    │   (e.g., NGINX)   │    │                 │
├─────────────────┤    ├───────────────────┤    ├─────────────────┤
│                 │    │                   │    │                 │
│  HTTP Request   │───▶│  ┌─────────────┐  │───▶│  go-app:80      │
│  Host: localhost│    │  │   Ingress   │  │    │                 │
│  Path: /healthz │    │  │   Rules     │  │    │  ┌───────────┐  │
│                 │    │  │             │  │    │  │    Pod    │  │
│                 │    │  │ localhost/  │  │    │  │    Pod    │  │
│                 │    │  │ → go-app:80 │  │    │  │    Pod    │  │
│                 │    │  └─────────────┘  │    │  └───────────┘  │
└─────────────────┘    └───────────────────┘    └─────────────────┘

Flow:
1. Client sends HTTP request
2. Ingress Controller receives traffic
3. Controller applies Ingress rules
4. Traffic routed to appropriate service
5. Service forwards to pods
```

### Gateway API Architecture

```
┌─────────────────┐    ┌───────────────────┐    ┌─────────────────┐
│   External      │    │   Gateway         │    │   Kubernetes    │
│   Client        │    │   Implementation  │    │   Services      │
│                 │    │   (e.g., Envoy)   │    │                 │
├─────────────────┤    ├───────────────────┤    ├─────────────────┤
│                 │    │                   │    │                 │
│  HTTP Request   │───▶│  ┌─────────────┐  │───▶│  go-app:80      │
│  Host: localhost│    │  │   Gateway   │  │    │                 │
│  Path: /healthz │    │  │   :8080     │  │    │  ┌───────────┐  │
│                 │    │  │             │  │    │  │    Pod    │  │
│                 │    │  │ HTTPRoute   │  │    │  │    Pod    │  │
│                 │    │  │ Rules       │  │    │  │    Pod    │  │
│                 │    │  └─────────────┘  │    │  └───────────┘  │
└─────────────────┘    └───────────────────┘    └─────────────────┘

Components Relationship:
┌─────────────────┐
│  GatewayClass   │ ──┐
│  (Controller)   │   │
└─────────────────┘   │
                      ▼
┌─────────────────┐   ┌─────────────────┐
│    Gateway      │◄──│   HTTPRoute     │
│  (Listeners)    │   │   (Rules)       │
└─────────────────┘   └─────────────────┘

Flow:
1. GatewayClass defines the controller
2. Gateway creates listeners on specific ports
3. HTTPRoute defines routing rules
4. Client traffic flows through gateway to services
```

### Resource Relationships

#### Ingress Model
```
┌─────────────────┐
│  IngressClass   │
│                 │
│  controller:    │
│  k8s.io/        │
│  ingress-nginx  │
└─────────────────┘
         │
         ▼
┌─────────────────┐
│     Ingress     │
│                 │
│  ingressClass:  │
│  nginx          │
│                 │
│  rules:         │
│  - host: app.com│
│    paths: [/]   │
└─────────────────┘
```

#### Gateway API Model
```
┌─────────────────┐
│  GatewayClass   │
│                 │
│  controller:    │
│  envoy-gateway  │
└─────────────────┘
         │
         ▼
┌─────────────────┐    ┌─────────────────┐
│     Gateway     │◄───│   HTTPRoute     │
│                 │    │                 │
│  class: envoy   │    │  parentRefs:    │
│  listeners:     │    │  - gateway      │
│  - port: 8080   │    │                 │
│    protocol:HTTP│    │  rules:         │
└─────────────────┘    │  - matches: [/] │
                       └─────────────────┘
```

---

## Practical Examples

Let's examine the actual configurations from this project:

### Example 1: Basic HTTP Routing

#### Ingress Approach
```yaml
# Single resource handles everything
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: go-app-ingress
  namespace: routing-experiment
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: localhost
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: go-app
            port:
              number: 80
      - path: /healthz
        pathType: Exact
        backend:
          service:
            name: go-app
            port:
              number: 80
```

#### Gateway API Approach
```yaml
# 1. Gateway (Infrastructure team responsibility)
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: go-app-gateway
  namespace: routing-experiment
spec:
  gatewayClassName: envoy-gateway
  listeners:
  - name: http
    protocol: HTTP
    port: 8080

---
# 2. HTTPRoute (Application team responsibility)
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: go-app-route
  namespace: routing-experiment
spec:
  parentRefs:
  - name: go-app-gateway
  hostnames:
  - "localhost"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: go-app
      port: 80
  - matches:
    - path:
        type: Exact
        value: /healthz
    backendRefs:
    - name: go-app
      port: 80
```

### Example 2: Advanced Traffic Management

#### Traffic Splitting (Gateway API)
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: canary-route
spec:
  parentRefs:
  - name: go-app-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /api
    backendRefs:
    - name: go-app-v1
      port: 80
      weight: 90
    - name: go-app-v2
      port: 80
      weight: 10
```

#### Header-based Routing (Gateway API)
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: header-route
spec:
  parentRefs:
  - name: go-app-gateway
  rules:
  - matches:
    - headers:
      - name: x-version
        value: v2
    backendRefs:
    - name: go-app-v2
      port: 80
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: go-app-v1
      port: 80
```

### Example 3: Multi-Protocol Support

#### Gateway API with Multiple Protocols
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: multi-protocol-gateway
spec:
  gatewayClassName: envoy-gateway
  listeners:
  - name: http
    protocol: HTTP
    port: 80
  - name: https
    protocol: HTTPS
    port: 443
    tls:
      certificateRefs:
      - name: tls-cert
  - name: grpc
    protocol: HTTP
    port: 9090

---
# HTTP routes
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
spec:
  parentRefs:
  - name: multi-protocol-gateway
    sectionName: http
  rules:
  - backendRefs:
    - name: web-service
      port: 80

---
# gRPC routes
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: GRPCRoute
metadata:
  name: grpc-route
spec:
  parentRefs:
  - name: multi-protocol-gateway
    sectionName: grpc
  rules:
  - backendRefs:
    - name: grpc-service
      port: 9090
```

---

## Migration Path

### From Ingress to Gateway API

#### Step 1: Assess Current Setup
```bash
# List current ingresses
kubectl get ingress -A

# Check ingress controllers
kubectl get ingressclass
```

#### Step 2: Install Gateway API CRDs
```bash
# Install standard CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

# Install experimental CRDs (for advanced features)
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/experimental-install.yaml
```

#### Step 3: Install Gateway Controller
```bash
# Example: Envoy Gateway
kubectl apply -f https://github.com/envoyproxy/gateway/releases/download/v1.0.0/install.yaml

# Example: Istio Gateway
istioctl install --set values.pilot.env.EXTERNAL_ISTIOD=false
```

#### Step 4: Create Equivalent Gateway Resources
```bash
# Convert existing Ingress to Gateway API
# This varies by use case and requirements
```

#### Step 5: Test and Validate
```bash
# Test routing functionality
curl -H "Host: localhost" http://gateway-ip:8080/healthz

# Compare behavior with original Ingress
```

#### Step 6: Gradual Migration
- Run both systems in parallel
- Gradually move traffic to Gateway API
- Deprecate old Ingress resources

---

## Best Practices

### Ingress Best Practices

1. **Use IngressClass**
   ```yaml
   spec:
     ingressClassName: nginx  # Always specify
   ```

2. **Avoid Controller-Specific Annotations When Possible**
   ```yaml
   annotations:
     # Prefer standard annotations
     kubernetes.io/ingress.class: nginx
   ```

3. **Implement Health Checks**
   ```yaml
   annotations:
     nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
     nginx.ingress.kubernetes.io/healthcheck-path: "/healthz"
   ```

### Gateway API Best Practices

1. **Role-Based Resource Management**
   ```yaml
   # Infrastructure team manages
   - GatewayClass
   - Gateway
   
   # Application team manages
   - HTTPRoute
   - Service
   ```

2. **Use Appropriate Route Types**
   ```yaml
   # For HTTP services
   kind: HTTPRoute
   
   # For gRPC services
   kind: GRPCRoute
   
   # For TCP services
   kind: TCPRoute
   ```

3. **Implement Cross-Namespace References Carefully**
   ```yaml
   spec:
     parentRefs:
     - name: shared-gateway
       namespace: infrastructure
   ```

4. **Use ReferenceGrant for Cross-Namespace Access**
   ```yaml
   apiVersion: gateway.networking.k8s.io/v1beta1
   kind: ReferenceGrant
   metadata:
     name: allow-routes
     namespace: infrastructure
   spec:
     from:
     - group: gateway.networking.k8s.io
       kind: HTTPRoute
       namespace: applications
     to:
     - group: ""
       kind: Service
   ```

### Security Best Practices

1. **TLS Configuration**
   ```yaml
   # Gateway API
   listeners:
   - name: https
     protocol: HTTPS
     port: 443
     tls:
       mode: Terminate
       certificateRefs:
       - name: tls-secret
   ```

2. **Network Policies**
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: gateway-access
   spec:
     podSelector:
       matchLabels:
         app: gateway
     ingress:
     - from:
       - namespaceSelector:
           matchLabels:
             name: gateway-system
   ```

### Monitoring and Observability

1. **Metrics Collection**
   ```yaml
   # Prometheus annotations
   annotations:
     prometheus.io/scrape: "true"
     prometheus.io/port: "9090"
     prometheus.io/path: "/metrics"
   ```

2. **Logging Configuration**
   ```yaml
   # Structured logging
   annotations:
     nginx.ingress.kubernetes.io/enable-access-log: "true"
   ```

---

## Testing Your Setup

### Unit Testing (Go Application)
```go
func TestHealthHandler(t *testing.T) {
    req, err := http.NewRequest("GET", "/healthz", nil)
    if err != nil {
        t.Fatal(err)
    }

    rr := httptest.NewRecorder()
    handler := http.HandlerFunc(healthHandler)
    handler.ServeHTTP(rr, req)

    if status := rr.Code; status != http.StatusOK {
        t.Errorf("wrong status code: got %v want %v", status, http.StatusOK)
    }
}
```

### Integration Testing
```bash
# Test Ingress
curl -H "Host: localhost" http://localhost/healthz

# Test Gateway API
curl -H "Host: localhost" http://localhost:8080/healthz

# Load testing
hey -n 1000 -c 10 http://localhost/healthz
```

### Validation Scripts
```bash
#!/bin/bash
# test-routing.sh

echo "Testing Ingress routing..."
INGRESS_RESPONSE=$(curl -s -H "Host: localhost" http://localhost/healthz)
echo "Ingress response: $INGRESS_RESPONSE"

echo "Testing Gateway API routing..."
GATEWAY_RESPONSE=$(curl -s -H "Host: localhost" http://localhost:8080/healthz)
echo "Gateway response: $GATEWAY_RESPONSE"

if [ "$INGRESS_RESPONSE" = "$GATEWAY_RESPONSE" ]; then
    echo "✅ Both approaches return the same response"
else
    echo "❌ Responses differ"
fi
```

---

## Performance Considerations

### Ingress Performance
- **Pros**: Mature implementations, optimized for HTTP
- **Cons**: Limited protocol support, controller-specific optimizations

### Gateway API Performance
- **Pros**: Protocol-native optimizations, better resource separation
- **Cons**: Additional resource overhead, newer implementations

### Benchmarking
```bash
# Ingress performance test
ab -n 10000 -c 100 http://localhost/

# Gateway API performance test
ab -n 10000 -c 100 http://localhost:8080/

# Compare latency and throughput
```

---

## Troubleshooting

### Common Ingress Issues

1. **Controller Not Ready**
   ```bash
   kubectl get pods -n ingress-nginx
   kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
   ```

2. **Wrong IngressClass**
   ```bash
   kubectl get ingressclass
   kubectl describe ingress <name>
   ```

3. **DNS/Host Issues**
   ```bash
   # Add to /etc/hosts
   echo "127.0.0.1 localhost" >> /etc/hosts
   ```

### Common Gateway API Issues

1. **CRDs Not Installed**
   ```bash
   kubectl get crd | grep gateway
   ```

2. **Gateway Status**
   ```bash
   kubectl describe gateway <name>
   kubectl get gateway <name> -o yaml
   ```

3. **Route Configuration**
   ```bash
   kubectl describe httproute <name>
   ```

### Debug Commands
```bash
# Check gateway status
kubectl get gateways -A

# Check route status
kubectl get httproutes -A

# Check gateway class
kubectl get gatewayclasses

# Detailed route inspection
kubectl describe httproute <route-name>

# Controller logs
kubectl logs -n gateway-system deployment/gateway-controller
```

---

## Conclusion

### When to Use Ingress
- ✅ Simple HTTP/HTTPS routing needs
- ✅ Mature, well-understood requirements
- ✅ Existing infrastructure based on Ingress
- ✅ Small teams with limited complexity

### When to Use Gateway API
- ✅ Multi-protocol support needed (gRPC, TCP, UDP)
- ✅ Advanced traffic management requirements
- ✅ Large organizations with role separation
- ✅ Future-proof infrastructure investments
- ✅ Complex routing and traffic policies

### Migration Strategy
1. **Start Small**: Begin with new applications
2. **Learn Gradually**: Train teams on Gateway API concepts
3. **Parallel Implementation**: Run both systems during transition
4. **Measure Impact**: Compare performance and operational overhead
5. **Full Migration**: Move existing applications when ready

### Future Direction
The Kubernetes community is moving toward Gateway API as the standard for service networking. While Ingress remains stable and supported, Gateway API represents the future of Kubernetes networking with its:
- Enhanced expressiveness
- Protocol extensibility
- Role-oriented design
- Vendor-neutral approach

Both approaches solve real problems, and the choice depends on your specific requirements, team structure, and long-term strategy.

---

## Resources and Further Reading

### Official Documentation
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Gateway API](https://gateway-api.sigs.k8s.io/)
- [Gateway API Concepts](https://gateway-api.sigs.k8s.io/concepts/api-overview/)

### Implementation Guides
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Envoy Gateway](https://gateway.envoyproxy.io/)
- [Istio Gateway](https://istio.io/latest/docs/tasks/traffic-management/ingress/)

### Tools and Utilities
- [kubectl](https://kubernetes.io/docs/reference/kubectl/)
- [kind](https://kind.sigs.k8s.io/) (Kubernetes in Docker)
- [hey](https://github.com/rakyll/hey) (HTTP load testing)
- [curl](https://curl.se/) (HTTP client)

---

## Project Repository

The complete source code and examples for this tutorial can be found in the [Kubernetes-Ingress-Gateway-API GitHub Repository](https://github.com/Yang92047111/Kubernetes-Ingress-Gateway-API).
