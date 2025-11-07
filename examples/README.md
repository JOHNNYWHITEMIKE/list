# Example Agent Configurations

This directory contains example configurations showing how different types of agents integrate with the API gateway.

## Examples Included

1. **agentacc-batch-test** - Reference implementation in list1/agents/agentacc-batch-test
   - Shows basic Python agent setup
   - Demonstrates API gateway integration
   - Includes Python client library usage

## Key Configuration Elements

All agents must include these elements for API gateway routing:

### 1. Docker Compose Network Configuration

```yaml
services:
  your-agent:
    networks:
      - agent-network
    environment:
      - OPENAI_API_BASE=http://api-gateway:80
      - OLLAMA_API_BASE=http://api-gateway:80/api
    depends_on:
      - api-gateway

networks:
  agent-network:
    external: true
    name: agent-network
```

### 2. Python Code Integration

```python
from api_gateway_client import init_gateway

# Initialize gateway - this forces all API calls through gateway
gateway = init_gateway(verify_connection=True)

# All subsequent API calls will route to Copilot/Ollama
```

### 3. Environment Variables

```bash
OPENAI_API_BASE=http://api-gateway:80
OLLAMA_API_BASE=http://api-gateway:80/api
API_GATEWAY_HOST=api-gateway
API_GATEWAY_PORT=80
```

## Creating a New Agent

1. **Start from template**:
```bash
# Use agentacc-batch-test as a template
cp -r list1/agents/agentacc-batch-test list1/agents/my-new-agent
cd list1/agents/my-new-agent
```

2. **Update configuration**:
```bash
# Edit docker-compose.yml - change service name
# Edit config/config.yaml - update agent name
# Edit src/main.py - implement your logic
```

3. **Start the agent**:
```bash
# Make sure gateway is running first
docker-compose -f ../../docker-compose.gateway.yml up -d

# Start your agent
docker-compose up -d
```

## Verification

After starting an agent, verify it's connected to the gateway:

```bash
# Check agent is on the network
docker network inspect agent-network

# Check agent logs for gateway initialization
docker-compose logs | grep "API Gateway"

# Should see:
# ✓ API Gateway is reachable at http://api-gateway:80
# OpenAI/Copilot calls → http://api-gateway:80
# Ollama calls         → http://api-gateway:80/api
```

## Additional Resources

- [API Gateway README](../api-gateway/README.md)
- [Gateway Setup Guide](../GATEWAY_SETUP.md)
- [Main Repository README](../README.md)
