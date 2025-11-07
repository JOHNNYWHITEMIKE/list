#!/bin/bash
# Test script for API Gateway configuration

set -e

echo "=========================================="
echo "API Gateway Configuration Test"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

echo "Test 1: Checking nginx configuration files exist"
if [ -f "api-gateway/nginx.conf" ] && [ -f "api-gateway/api-routes.conf" ]; then
    print_result 0 "Configuration files exist"
else
    print_result 1 "Configuration files missing"
    exit 1
fi

echo ""
echo "Test 2: Checking Dockerfile exists"
if [ -f "api-gateway/Dockerfile" ]; then
    print_result 0 "Dockerfile exists"
else
    print_result 1 "Dockerfile missing"
    exit 1
fi

echo ""
echo "Test 3: Checking docker-compose.gateway.yml exists"
if [ -f "docker-compose.gateway.yml" ]; then
    print_result 0 "docker-compose.gateway.yml exists"
else
    print_result 1 "docker-compose.gateway.yml missing"
    exit 1
fi

echo ""
echo "Test 4: Validating nginx configuration syntax"
# Create a temporary container to test nginx config
docker run --rm -v "$(pwd)/api-gateway/nginx.conf:/etc/nginx/nginx.conf:ro" \
    -v "$(pwd)/api-gateway/api-routes.conf:/etc/nginx/conf.d/default.conf:ro" \
    nginx:alpine nginx -t > /dev/null 2>&1

if [ $? -eq 0 ]; then
    print_result 0 "Nginx configuration syntax is valid"
else
    print_result 1 "Nginx configuration syntax has errors"
    docker run --rm -v "$(pwd)/api-gateway/nginx.conf:/etc/nginx/nginx.conf:ro" \
        -v "$(pwd)/api-gateway/api-routes.conf:/etc/nginx/conf.d/default.conf:ro" \
        nginx:alpine nginx -t
    exit 1
fi

echo ""
echo "Test 5: Checking Python client library exists"
if [ -f "api-gateway/api_gateway_client.py" ]; then
    print_result 0 "Python client library exists"
else
    print_result 1 "Python client library missing"
    exit 1
fi

echo ""
echo "Test 6: Checking update script exists and is executable"
if [ -x "update-agents-gateway.sh" ]; then
    print_result 0 "Update script exists and is executable"
else
    print_result 1 "Update script missing or not executable"
    exit 1
fi

echo ""
echo "Test 7: Checking sample agent configuration"
if [ -f "list1/agents/agentacc-batch-test/docker-compose.yml" ]; then
    if grep -q "agent-network" "list1/agents/agentacc-batch-test/docker-compose.yml"; then
        print_result 0 "Sample agent has network configuration"
    else
        print_result 1 "Sample agent missing network configuration"
    fi
else
    print_result 1 "Sample agent docker-compose.yml not found"
fi

echo ""
echo "Test 8: Checking documentation files"
docs_ok=0
if [ -f "api-gateway/README.md" ]; then
    ((docs_ok++))
fi
if [ -f "GATEWAY_SETUP.md" ]; then
    ((docs_ok++))
fi

if [ $docs_ok -eq 2 ]; then
    print_result 0 "All documentation files present"
else
    print_result 1 "Some documentation files missing"
fi

echo ""
echo "=========================================="
echo "All basic tests passed!"
echo "=========================================="
echo ""
echo "Next steps to test the gateway:"
echo "1. Build the gateway: docker-compose -f docker-compose.gateway.yml build"
echo "2. Start the gateway: docker-compose -f docker-compose.gateway.yml up -d"
echo "3. Test health endpoint: curl http://localhost:8080/health"
echo ""
