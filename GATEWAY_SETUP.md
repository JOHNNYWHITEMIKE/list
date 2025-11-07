# API Gateway Setup Guide

This guide explains how to configure all agents to route API calls exclusively through the API gateway to GitHub Copilot and Ollama cloud models.

## Overview

The API Gateway ensures that:
- **All OpenAI-compatible API calls** are routed to **GitHub Copilot**
- **All Ollama API calls** are routed to **Ollama Cloud**
- **No agents can make direct external API calls**

This is achieved through:
1. A centralized NGINX reverse proxy (API Gateway)
2. Docker network isolation
3. Environment variable configuration
4. Python client library for enforcement

## Quick Setup

### Option 1: Automated Setup (Recommended)

```bash
# 1. Update all agents to use the gateway
./update-agents-gateway.sh

# 2. Start the API gateway
docker-compose -f docker-compose.gateway.yml up -d

# 3. Verify gateway is running
curl http://localhost:8080/health
# Expected output: "healthy"

# 4. Start any agent - it will automatically use the gateway
cd list1/agents/your-agent
docker-compose up -d
```

### Option 2: Manual Setup

#### Step 1: Start the API Gateway

```bash
# Create the shared network
docker network create agent-network

# Start the gateway
docker-compose -f docker-compose.gateway.yml up -d

# Verify it's running
docker ps | grep api-gateway
curl http://localhost:8080/health
```

#### Step 2: Update an Agent's docker-compose.yml

Edit your agent's `docker-compose.yml` to include:

```yaml
version: '3.8'

services:
  your-agent:
    build: .
    container_name: your-agent
    environment:
      - AGENT_NAME=your-agent
      # API Gateway configuration
      - OPENAI_API_BASE=http://api-gateway:80
      - OLLAMA_API_BASE=http://api-gateway:80/api
      - API_GATEWAY_HOST=api-gateway
      - API_GATEWAY_PORT=80
    volumes:
      - ./config:/app/config
      - ./data:/app/data
    networks:
      - agent-network
    depends_on:
      - api-gateway
    restart: unless-stopped

  # Include API gateway in agent's compose file
  api-gateway:
    image: nginx:alpine
    container_name: api-gateway
    volumes:
      - ../../../api-gateway/nginx.conf:/etc/nginx/nginx.conf:ro
      - ../../../api-gateway/api-routes.conf:/etc/nginx/conf.d/default.conf:ro
    environment:
      - OLLAMA_API_HOST=${OLLAMA_API_HOST:-ollama.ai}
      - OLLAMA_API_PORT=${OLLAMA_API_PORT:-443}
    networks:
      - agent-network
    restart: unless-stopped

networks:
  agent-network:
    name: agent-network
    driver: bridge
```

#### Step 3: Update Agent Code

Add the gateway client to your agent's `main.py`:

```python
import sys
from pathlib import Path

# Add API gateway client to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent.parent / "api-gateway"))

from api_gateway_client import init_gateway

# Initialize gateway - enforces routing to Copilot and Ollama
gateway = init_gateway(verify_connection=True)

# Now all API calls will route through the gateway
```

#### Step 4: Start the Agent

```bash
cd list1/agents/your-agent
docker-compose up -d
```

## Configuration

### Environment Variables

Edit `.env.gateway` to configure endpoints:

```bash
# Ollama Cloud API
OLLAMA_API_HOST=ollama.ai
OLLAMA_API_PORT=443

# GitHub Copilot API
COPILOT_API_HOST=copilot.github.com
COPILOT_API_PORT=443

# API Gateway
API_GATEWAY_HOST=api-gateway
API_GATEWAY_PORT=80
```

### API Keys

Add your API keys to `.env.gateway`:

```bash
GITHUB_TOKEN=your_github_token
COPILOT_API_KEY=your_copilot_key
```

**Important**: Never commit real API keys to git. Use `.gitignore` to exclude `.env` files.

## Using the Gateway in Agent Code

### OpenAI/Copilot Usage

```python
from api_gateway_client import get_openai_client

# Get client configured to use gateway (routes to Copilot)
client = get_openai_client()

# Make API calls - these will go through gateway to Copilot
response = client.chat.completions.create(
    model="gpt-4",
    messages=[{"role": "user", "content": "Hello from agent!"}]
)
```

### Ollama Usage

```python
from api_gateway_client import get_ollama_client

# Get client configured to use gateway (routes to Ollama Cloud)
client = get_ollama_client()

# Make API calls - these will go through gateway to Ollama Cloud
response = client.generate(
    model='llama2',
    prompt='Hello from agent!'
)
```

### Manual Configuration

```python
from api_gateway_client import APIGatewayConfig

config = APIGatewayConfig()

# Get the base URLs
openai_base = config.openai_base_url  # http://api-gateway:80
ollama_base = config.ollama_base_url  # http://api-gateway:80/api

# Use these in your client configurations
```

## Verification

### Check Gateway Status

```bash
# Health check
curl http://localhost:8080/health

# Check gateway logs
docker-compose -f docker-compose.gateway.yml logs -f api-gateway

# Check what agents are connected
docker network inspect agent-network
```

### Test API Routing

```bash
# From within an agent container
docker exec your-agent python -c "from api_gateway_client import init_gateway; init_gateway()"

# Should output:
# ✓ API Gateway is reachable at http://api-gateway:80
# OpenAI/Copilot calls → http://api-gateway:80
# Ollama calls         → http://api-gateway:80/api
```

### Monitor API Calls

Gateway logs show all routed API calls:

```bash
docker-compose -f docker-compose.gateway.yml logs -f api-gateway

# Example output:
# 172.18.0.3 - - [07/Nov/2024:16:44:38 +0000] "POST /v1/chat/completions HTTP/1.1" 200
```

## Troubleshooting

### Agent Can't Connect to Gateway

**Symptom**: Agent fails to start or can't make API calls

**Solution**:
```bash
# 1. Check if gateway is running
docker ps | grep api-gateway

# 2. Check if agent is on the correct network
docker network inspect agent-network

# 3. Restart gateway if needed
docker-compose -f docker-compose.gateway.yml restart
```

### API Calls Timing Out

**Symptom**: Long-running API calls timeout

**Solution**: Increase timeout in `api-gateway/api-routes.conf`:

```nginx
location /api/ {
    # Increase timeout for long operations
    proxy_read_timeout 1200s;  # 20 minutes
    # ...
}
```

Then restart the gateway:
```bash
docker-compose -f docker-compose.gateway.yml restart
```

### Gateway Not Routing Correctly

**Symptom**: API calls fail or route to wrong endpoint

**Solution**:
1. Check nginx configuration syntax:
```bash
docker exec api-gateway nginx -t
```

2. View gateway error logs:
```bash
docker-compose -f docker-compose.gateway.yml logs api-gateway | grep error
```

3. Verify environment variables:
```bash
docker exec api-gateway env | grep -E "(OLLAMA|COPILOT|API_GATEWAY)"
```

### Network Issues

**Symptom**: Containers can't communicate

**Solution**:
```bash
# Recreate the network
docker network rm agent-network
docker network create agent-network

# Restart gateway
docker-compose -f docker-compose.gateway.yml down
docker-compose -f docker-compose.gateway.yml up -d

# Restart agents
cd list1/agents/your-agent
docker-compose restart
```

## Advanced Configuration

### Custom Routing Rules

Edit `api-gateway/api-routes.conf` to add custom endpoints:

```nginx
# Route specific endpoints differently
location /custom-api/ {
    proxy_pass http://custom-backend:8080/;
    # proxy settings...
}
```

### Load Balancing

Configure multiple backend servers:

```nginx
upstream ollama_api {
    server ollama1.ai:443 weight=3;
    server ollama2.ai:443 weight=1;
    keepalive 32;
}
```

### Rate Limiting

Add rate limits to prevent API abuse:

```nginx
http {
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    
    server {
        location / {
            limit_req zone=api_limit burst=20 nodelay;
            # ...
        }
    }
}
```

### SSL/TLS Termination

For production, add SSL certificates:

```nginx
server {
    listen 443 ssl;
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    # ...
}
```

## Security Best Practices

1. **Never commit API keys** - Use `.gitignore` for `.env` files
2. **Use secrets management** - Consider Docker secrets or Vault
3. **Network isolation** - Keep agents on isolated network
4. **Monitor logs** - Regularly check for unauthorized access
5. **Update regularly** - Keep gateway and agent images updated
6. **Limit access** - Only expose necessary ports

## Performance Optimization

1. **Enable caching** - Cache responses for repeated queries
2. **Connection pooling** - Use `keepalive` in nginx upstream
3. **Compress responses** - Enable gzip compression
4. **Resource limits** - Set memory/CPU limits in docker-compose

## Production Deployment

For production use:

1. Use production-grade Ollama endpoint
2. Obtain GitHub Copilot Enterprise license
3. Set up monitoring (Prometheus, Grafana)
4. Configure log aggregation (ELK stack)
5. Implement backup and disaster recovery
6. Set up health monitoring and alerts

## Support

For issues or questions:
1. Check the [API Gateway README](api-gateway/README.md)
2. Review gateway logs: `docker-compose -f docker-compose.gateway.yml logs`
3. Check agent logs: `docker-compose logs` in agent directory
4. Open an issue in the repository

## References

- [API Gateway README](api-gateway/README.md)
- [NGINX Reverse Proxy Guide](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
- [Docker Compose Networking](https://docs.docker.com/compose/networking/)
- [GitHub Copilot Documentation](https://docs.github.com/en/copilot)
- [Ollama API Documentation](https://github.com/ollama/ollama/blob/main/docs/api.md)
