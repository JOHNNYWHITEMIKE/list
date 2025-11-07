# API Gateway for Agent Routing

This API gateway ensures that **all API calls from all Docker containers are routed exclusively to GitHub Copilot and Ollama cloud models**.

## Overview

The API gateway acts as a reverse proxy that intercepts all API calls from agent containers and routes them to the appropriate cloud model endpoints:

- **OpenAI-compatible API calls** → GitHub Copilot
- **Ollama API calls** → Ollama Cloud
- **All other API calls** → Ollama Cloud (default)

## Architecture

```
[Agent Containers] → [API Gateway] → [Copilot / Ollama Cloud]
```

All agents are configured to route their API traffic through the gateway instead of directly to external services.

## Quick Start

### 1. Start the API Gateway

```bash
# From the repository root
docker-compose -f docker-compose.gateway.yml up -d
```

This creates:
- API Gateway container on port 8080
- Shared `agent-network` for all containers

### 2. Configure Agent to Use Gateway

Each agent needs to be configured to use the gateway. Add this to your agent's `docker-compose.yml`:

```yaml
version: '3.8'

services:
  your-agent:
    # ... your existing configuration ...
    environment:
      # Force API calls through gateway
      - OPENAI_API_BASE=http://api-gateway:80
      - OLLAMA_API_BASE=http://api-gateway:80/api
    networks:
      - agent-network
    depends_on:
      - api-gateway

networks:
  agent-network:
    external: true
    name: agent-network
```

### 3. Start Your Agent

```bash
cd list1/agents/your-agent
docker-compose up -d
```

## Configuration

### Environment Variables

Edit `.env.gateway` to configure endpoints:

```bash
# Ollama Cloud Configuration
OLLAMA_API_HOST=ollama.ai
OLLAMA_API_PORT=443

# GitHub Copilot Configuration
COPILOT_API_HOST=copilot.github.com
COPILOT_API_PORT=443

# API Gateway Configuration
API_GATEWAY_HOST=api-gateway
API_GATEWAY_PORT=80
```

### API Authentication

Add your API keys to `.env.gateway`:

```bash
GITHUB_TOKEN=your_github_token_here
COPILOT_API_KEY=your_copilot_api_key_here
```

**Important**: Do not commit actual API keys to version control. Use environment variables or secrets management.

## Routing Rules

The gateway uses the following routing logic:

1. **OpenAI API Endpoints** (`/v1/chat/completions`, `/v1/completions`, `/v1/embeddings`)
   - Routed to GitHub Copilot API
   - SSL/TLS enabled
   - Authorization headers forwarded

2. **Ollama API Endpoints** (`/api/*`)
   - Routed to Ollama Cloud API
   - Extended timeout for model operations (600s)

3. **Default Route** (All other paths)
   - Routed to Ollama Cloud API
   - Standard timeout (300s)

## Health Check

Check if the gateway is running:

```bash
curl http://localhost:8080/health
# Expected response: "healthy"
```

## Network Isolation

All agents must be on the `agent-network` to communicate with the gateway. This ensures:

- All API traffic goes through the gateway
- No direct external API access
- Centralized monitoring and logging

## Updating All Agents

To update all agents in `list1` and `list2` to use the gateway:

```bash
# Update all list1 agents
for dir in list1/agents/*/; do
  cd "$dir"
  # Add network and environment configuration
  # (Use the template as reference)
  cd ../../..
done
```

## Monitoring

Gateway logs are available via:

```bash
docker-compose -f docker-compose.gateway.yml logs -f api-gateway
```

## Troubleshooting

### Agent can't connect to gateway

```bash
# Check if gateway is running
docker ps | grep api-gateway

# Check if agent is on the correct network
docker network inspect agent-network
```

### API calls timing out

Check the nginx timeout settings in `api-gateway/api-routes.conf` and adjust:

```nginx
proxy_read_timeout 600s;  # Increase for long-running operations
```

### SSL/TLS issues with Copilot

Ensure the gateway container can resolve DNS and access GitHub:

```bash
docker exec api-gateway ping copilot.github.com
```

## Security Considerations

1. **API Key Management**: Never commit API keys to the repository
2. **Network Isolation**: Keep agents on the isolated `agent-network`
3. **HTTPS**: The gateway uses HTTPS for external API calls
4. **Logging**: Monitor gateway logs for unauthorized access attempts

## Advanced Configuration

### Custom Routing Rules

Edit `api-gateway/api-routes.conf` to add custom routing logic:

```nginx
location /custom-endpoint {
    proxy_pass http://your-custom-backend;
    # ... proxy settings ...
}
```

### Load Balancing

Add multiple upstream servers for high availability:

```nginx
upstream ollama_api {
    server ollama1.ai:443;
    server ollama2.ai:443;
    keepalive 32;
}
```

### Rate Limiting

Add rate limiting to prevent API abuse:

```nginx
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

server {
    location / {
        limit_req zone=api_limit burst=20 nodelay;
        # ... existing config ...
    }
}
```

## References

- [NGINX Reverse Proxy Documentation](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
- [Docker Compose Networking](https://docs.docker.com/compose/networking/)
- [GitHub Copilot API](https://docs.github.com/en/copilot)
- [Ollama API Documentation](https://github.com/ollama/ollama/blob/main/docs/api.md)
