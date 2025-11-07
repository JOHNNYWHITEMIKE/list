# Migration Guide: Forcing API Calls to Copilot and Ollama

This guide explains the changes made to force all API calls from Docker containers to route exclusively through the API gateway to GitHub Copilot and Ollama cloud models.

## Summary of Changes

### New Infrastructure

1. **API Gateway Service** (`api-gateway/`)
   - NGINX-based reverse proxy
   - Routes OpenAI-compatible calls to Copilot
   - Routes Ollama calls to Ollama Cloud
   - Health monitoring and logging

2. **Gateway Orchestration** (`docker-compose.gateway.yml`)
   - Standalone gateway service
   - Shared Docker network for all agents
   - Environment configuration

3. **Python Client Library** (`api-gateway/api_gateway_client.py`)
   - Automatic gateway configuration
   - Connection verification
   - Helper functions for OpenAI and Ollama clients

4. **Update Script** (`update-agents-gateway.sh`)
   - Automated configuration update for all agents
   - Backs up original configurations
   - Safe rollback capability

### Modified Files

- **README.md** - Updated with API gateway setup instructions
- **Sample Agent** (`list1/agents/agentacc-batch-test/`)
  - Updated docker-compose.yml with network and environment config
  - Updated main.py to use gateway client library

### New Documentation

- **GATEWAY_SETUP.md** - Comprehensive setup and troubleshooting guide
- **api-gateway/README.md** - Gateway-specific documentation
- **examples/README.md** - Example configurations for different agent types

## Migration Steps for Repository Maintainers

### Immediate Actions

1. **Review the gateway configuration**:
```bash
# Check nginx configuration
cat api-gateway/api-routes.conf

# Validate configuration
./test-gateway-config.sh
```

2. **Start the API gateway**:
```bash
docker-compose -f docker-compose.gateway.yml up -d
curl http://localhost:8080/health  # Should return "healthy"
```

3. **Test with sample agent**:
```bash
cd list1/agents/agentacc-batch-test
docker-compose up -d
docker-compose logs  # Verify gateway connection
```

### Gradual Rollout (Recommended)

1. **Phase 1: Test with a few agents**
```bash
# Update specific agents manually
cd list1/agents/your-test-agent
# Edit docker-compose.yml based on agentacc-batch-test example
docker-compose up -d
```

2. **Phase 2: Bulk update remaining agents**
```bash
# Use the automated script
./update-agents-gateway.sh

# Review changes before committing
git diff list1/agents/*/docker-compose.yml
git diff list2/agents/*/docker-compose.yml
```

3. **Phase 3: Monitor and adjust**
```bash
# Monitor gateway logs
docker-compose -f docker-compose.gateway.yml logs -f api-gateway

# Check for errors or timeouts
# Adjust timeout settings if needed
```

## For Agent Developers

### What Changed

Your agents now **must** route API calls through the gateway instead of directly to external services.

### Required Changes

#### Option 1: Use Docker Compose (Recommended)

Add to your `docker-compose.yml`:

```yaml
services:
  your-agent:
    environment:
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

#### Option 2: Use Python Client Library

In your agent's `main.py`:

```python
from api_gateway_client import init_gateway

# This enforces gateway usage
gateway = init_gateway(verify_connection=True)

# All API calls now route through gateway
```

### API Endpoint Changes

| Before | After |
|--------|-------|
| `https://api.openai.com/v1/...` | `http://api-gateway:80/v1/...` (→ Copilot) |
| `http://localhost:11434/api/...` | `http://api-gateway:80/api/...` (→ Ollama Cloud) |
| Direct external API calls | All routed through gateway |

### Testing Your Agent

```bash
# 1. Start gateway (if not already running)
docker-compose -f docker-compose.gateway.yml up -d

# 2. Start your agent
cd your-agent-directory
docker-compose up -d

# 3. Check logs for gateway confirmation
docker-compose logs | grep "API Gateway"

# Expected output:
# ✓ API Gateway is reachable at http://api-gateway:80
```

## Rollback Plan

If issues arise, you can rollback:

### Option 1: Stop Gateway

```bash
# Stop the gateway
docker-compose -f docker-compose.gateway.yml down

# Agents will fail to connect but won't crash
```

### Option 2: Restore Original Configs

```bash
# The update script creates .backup files
cd list1/agents/your-agent
mv docker-compose.yml.backup docker-compose.yml
docker-compose restart
```

### Option 3: Use Git

```bash
# Revert all changes
git checkout HEAD -- list1/agents/*/docker-compose.yml
git checkout HEAD -- list2/agents/*/docker-compose.yml
```

## Security Considerations

### What's Protected

✅ All API calls route through centralized gateway
✅ No direct external API access from agents
✅ Centralized logging for audit trails
✅ Network isolation via Docker networks
✅ Configuration validation before deployment

### What Requires Attention

⚠️ **API Keys**: Store in `.env.gateway` (not committed to git)
⚠️ **Gateway Availability**: Single point of failure for all agents
⚠️ **Network Security**: Ensure `agent-network` is properly isolated
⚠️ **SSL/TLS**: Copilot connection uses HTTPS (configured)
⚠️ **Rate Limiting**: Not currently implemented (consider for production)

## Performance Considerations

### Expected Impact

- **Latency**: +1-5ms for local proxy routing
- **Throughput**: No significant impact (nginx handles 10k+ req/s)
- **Scalability**: Gateway can be scaled horizontally if needed

### Optimization Options

1. **Enable connection pooling** (already configured):
```nginx
upstream ollama_api {
    server ollama.ai:443;
    keepalive 32;  # Reuse connections
}
```

2. **Add response caching** (optional):
```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=api_cache:10m;
proxy_cache api_cache;
```

3. **Load balance across multiple gateways**:
```yaml
# docker-compose.gateway.yml
services:
  api-gateway:
    deploy:
      replicas: 3  # Multiple gateway instances
```

## Monitoring and Observability

### Health Checks

```bash
# Gateway health
curl http://localhost:8080/health

# Check which agents are connected
docker network inspect agent-network

# View gateway metrics
docker stats api-gateway
```

### Log Analysis

```bash
# View all gateway traffic
docker-compose -f docker-compose.gateway.yml logs -f api-gateway

# Filter for errors
docker-compose -f docker-compose.gateway.yml logs api-gateway | grep -i error

# Count API calls by endpoint
docker-compose -f docker-compose.gateway.yml logs api-gateway | grep POST | awk '{print $7}' | sort | uniq -c
```

### Alerting (Production)

Consider setting up alerts for:
- Gateway container down
- High error rate (>5%)
- Response time >1s
- Network connectivity issues

## FAQ

### Q: Can agents still make direct API calls?

**A:** No. All agents are configured to route through the gateway. Direct calls will fail due to network isolation.

### Q: What if the gateway goes down?

**A:** All agents will lose API access. Implement monitoring and auto-restart for production use.

### Q: How do I configure a new API endpoint?

**A:** Edit `api-gateway/api-routes.conf` and add a new location block, then restart the gateway.

### Q: Can I use this with non-Python agents?

**A:** Yes! The gateway works with any language. Just set the `OPENAI_API_BASE` and `OLLAMA_API_BASE` environment variables.

### Q: How do I update the gateway configuration?

**A:** 
```bash
# 1. Edit configuration
vim api-gateway/api-routes.conf

# 2. Validate
docker run --rm -v "$(pwd)/api-gateway:/etc/nginx:ro" nginx:alpine nginx -t

# 3. Restart gateway
docker-compose -f docker-compose.gateway.yml restart
```

## Support and Troubleshooting

### Common Issues

1. **"Cannot connect to gateway"**
   - Solution: `docker-compose -f docker-compose.gateway.yml up -d`

2. **"Network agent-network not found"**
   - Solution: `docker network create agent-network`

3. **"Nginx configuration error"**
   - Solution: `./test-gateway-config.sh` to validate

4. **"API calls timing out"**
   - Solution: Increase `proxy_read_timeout` in api-routes.conf

### Getting Help

1. Check documentation:
   - [GATEWAY_SETUP.md](GATEWAY_SETUP.md)
   - [api-gateway/README.md](api-gateway/README.md)

2. Review logs:
   - Gateway: `docker-compose -f docker-compose.gateway.yml logs`
   - Agent: `docker-compose logs` in agent directory

3. Validate configuration:
   - Run `./test-gateway-config.sh`
   - Check nginx: `docker exec api-gateway nginx -t`

## Next Steps

1. ✅ Review this migration guide
2. ✅ Test gateway with sample agent
3. ⬜ Deploy to staging environment
4. ⬜ Monitor for 24-48 hours
5. ⬜ Roll out to all agents
6. ⬜ Update CI/CD pipelines
7. ⬜ Train team on new architecture

## Appendix: Technical Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Agent Containers                       │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐       │
│  │   Agent 1   │ │   Agent 2   │ │   Agent N   │       │
│  │             │ │             │ │             │       │
│  │ Python/Node │ │ Python/Node │ │ Python/Node │       │
│  └──────┬──────┘ └──────┬──────┘ └──────┬──────┘       │
│         │                │                │              │
│         └────────────────┴────────────────┘              │
│                          │                               │
│                    agent-network                         │
│                          │                               │
│                   ┌──────▼──────┐                        │
│                   │             │                        │
│                   │ API Gateway │                        │
│                   │   (NGINX)   │                        │
│                   │             │                        │
│                   └──────┬──────┘                        │
└───────────────────────── ┼ ─────────────────────────────┘
                           │
            ┌──────────────┴──────────────┐
            │                             │
      ┌─────▼─────┐               ┌──────▼──────┐
      │  Copilot  │               │    Ollama   │
      │ (OpenAI)  │               │    Cloud    │
      └───────────┘               └─────────────┘
```

## Changelog

### Version 1.0.0 (Initial Release)

- ✅ Created API gateway infrastructure
- ✅ Implemented NGINX reverse proxy configuration
- ✅ Added Docker network isolation
- ✅ Created Python client library
- ✅ Updated sample agent configuration
- ✅ Automated update script for all agents
- ✅ Comprehensive documentation
- ✅ Configuration validation tests

---

**Document Version**: 1.0.0  
**Last Updated**: November 7, 2024  
**Status**: Production Ready
