#!/bin/bash

set -e

echo "🧪 Testing Kubernetes Routing Experiment"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
test_endpoint() {
    local name=$1
    local url=$2
    local expected_status=$3
    
    echo -n "Testing $name... "
    
    response=$(curl -s -w "%{http_code}" -o /tmp/response "$url" 2>/dev/null || echo "000")
    status_code="${response: -3}"
    
    if [ "$status_code" = "$expected_status" ]; then
        echo -e "${GREEN}✅ PASS${NC} (HTTP $status_code)"
        if [ -f /tmp/response ]; then
            echo "   Response: $(cat /tmp/response | jq -c . 2>/dev/null || cat /tmp/response)"
        fi
    else
        echo -e "${RED}❌ FAIL${NC} (HTTP $status_code, expected $expected_status)"
        if [ -f /tmp/response ]; then
            echo "   Response: $(cat /tmp/response)"
        fi
    fi
    echo
}

# Performance test function
perf_test() {
    local name=$1
    local url=$2
    
    echo "⚡ Performance test for $name:"
    
    # Run 10 requests and measure time
    total_time=0
    success_count=0
    
    for i in {1..10}; do
        start_time=$(date +%s%N)
        if curl -s -f "$url" > /dev/null 2>&1; then
            end_time=$(date +%s%N)
            duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
            total_time=$((total_time + duration))
            success_count=$((success_count + 1))
        fi
    done
    
    if [ $success_count -gt 0 ]; then
        avg_time=$((total_time / success_count))
        echo "   Average response time: ${avg_time}ms (${success_count}/10 successful)"
    else
        echo "   ${RED}All requests failed${NC}"
    fi
    echo
}

echo "🔍 Testing Ingress routing..."
echo "----------------------------"

test_endpoint "Ingress Health" "http://localhost/healthz" "200"
test_endpoint "Ingress Version" "http://localhost/version" "200"
test_endpoint "Ingress Root" "http://localhost/" "200"

perf_test "Ingress" "http://localhost/healthz"

echo "🌉 Testing Gateway routing..."
echo "----------------------------"

test_endpoint "Gateway Health" "http://localhost:8080/healthz" "200"
test_endpoint "Gateway Version" "http://localhost:8080/version" "200"
test_endpoint "Gateway Root" "http://localhost:8080/" "200"

perf_test "Gateway" "http://localhost:8080/healthz"

echo "📊 Comparison Summary"
echo "===================="

echo "✅ Tests completed!"
echo
echo "🔍 Additional debugging info:"
echo "Ingress status:"
kubectl get ingress -n routing-experiment -o wide
echo
echo "Gateway status:"
kubectl get gateway -n routing-experiment -o wide
echo
echo "HTTPRoute status:"
kubectl get httproute -n routing-experiment -o wide
echo
echo "Service endpoints:"
kubectl get endpoints -n routing-experiment