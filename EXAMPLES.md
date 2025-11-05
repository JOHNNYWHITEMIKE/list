# Docker Container Examples

This document provides practical examples of using the Docker containers for AI agents in this repository.

## Example 1: Running a Single Agent (Aider)

### Step 1: Navigate to the agent directory
```bash
cd agents/aider
```

### Step 2: Build the Docker image
```bash
docker-compose build
```

### Step 3: Run the agent
```bash
docker-compose up
```

Expected output:
```
Starting Aider agent...
Agent is running...
```

### Step 4: Stop the agent
```bash
docker-compose down
```

## Example 2: Using the Management Script

### List all available agents
```bash
./manage-agents.sh list
```

### Build a specific agent
```bash
./manage-agents.sh build autogpt
```

### Start an agent in the background
```bash
./manage-agents.sh start langchain
```

### Check status of running agents
```bash
./manage-agents.sh status
```

### View logs for an agent
```bash
./manage-agents.sh logs crewai
```

### Stop a running agent
```bash
./manage-agents.sh stop autogpt
```

### Stop all running agents
```bash
./manage-agents.sh stop-all
```

## Example 3: Customizing an Agent

### 1. Navigate to agent directory
```bash
cd agents/langchain
```

### 2. Edit the configuration
```bash
nano config/config.yaml
```

Add your custom configuration:
```yaml
agent:
  name: "LangChain"
  description: "LangChain agent with custom settings"
  
api_keys:
  openai: "your-api-key-here"
  
custom_settings:
  model: "gpt-4"
  temperature: 0.7
```

### 3. Modify the source code
```bash
nano src/main.py
```

Example implementation:
```python
#!/usr/bin/env python3
"""
Main entry point for LangChain agent
"""
import os
import yaml

def load_config():
    with open('config/config.yaml', 'r') as f:
        return yaml.safe_load(f)

def main():
    config = load_config()
    agent_name = config['agent']['name']
    print(f"Starting {agent_name} agent...")
    
    # Your LangChain implementation here
    # Example: Initialize LangChain components
    # from langchain import ...
    
    print("Agent is running...")

if __name__ == "__main__":
    main()
```

### 4. Add Python dependencies
```bash
cat > requirements.txt << EOF
langchain==0.1.0
openai==1.0.0
python-dotenv==1.0.0
PyYAML==6.0
EOF
```

### 5: Rebuild and run
```bash
docker-compose build
docker-compose up
```

## Example 4: Running Multiple Agents Together

### Start multiple agents
```bash
./manage-agents.sh start autogpt
./manage-agents.sh start langchain
./manage-agents.sh start crewai
```

### Check all running agents
```bash
./manage-agents.sh status
```

### View logs from all agents
```bash
docker ps --filter "network=agent-network" --format "{{.Names}}" | while read agent; do
    echo "=== Logs for $agent ==="
    docker logs --tail 10 $agent
    echo ""
done
```

### Stop all agents
```bash
./manage-agents.sh stop-all
```

## Example 5: Inter-Agent Communication

Since all agents share the `agent-network`, they can communicate with each other.

### Agent A (Producer)
```python
# agents/agent-a/src/main.py
import socket
import json

def send_message(target_host, message):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((target_host, 8080))
        s.sendall(json.dumps(message).encode())

# Send message to agent-b
send_message('agent-b', {'task': 'process_data', 'data': [1, 2, 3]})
```

### Agent B (Consumer)
```python
# agents/agent-b/src/main.py
import socket
import json

def listen_for_messages():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(('0.0.0.0', 8080))
        s.listen()
        conn, addr = s.accept()
        with conn:
            data = conn.recv(1024)
            message = json.loads(data.decode())
            print(f"Received: {message}")
            # Process the message
```

Update docker-compose.yaml to expose ports:
```yaml
services:
  agent-b:
    # ... other config ...
    ports:
      - "8080:8080"
```

## Example 6: Persisting Data

### Add a data directory
```bash
cd agents/langchain
mkdir -p data
```

### Mount the data directory
The docker-compose.yaml already includes:
```yaml
volumes:
  - ./data:/app/data
```

### Use the data directory
```python
# agents/langchain/src/main.py
import json

def save_results(results):
    with open('/app/data/results.json', 'w') as f:
        json.dump(results, f)

def load_results():
    try:
        with open('/app/data/results.json', 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        return {}
```

## Example 7: Environment Variables

### Set environment variables in docker-compose.yaml
```yaml
services:
  langchain:
    environment:
      - AGENT_NAME=LangChain
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - DEBUG=true
      - LOG_LEVEL=info
```

### Create a .env file
```bash
cd agents/langchain
cat > .env << EOF
OPENAI_API_KEY=sk-your-api-key-here
DEBUG=true
LOG_LEVEL=info
EOF
```

### Access in Python
```python
import os

api_key = os.environ.get('OPENAI_API_KEY')
debug = os.environ.get('DEBUG', 'false').lower() == 'true'
log_level = os.environ.get('LOG_LEVEL', 'info')
```

## Example 8: Building All Agents (Advanced)

**Warning:** This will build all 1423 agents and may take hours.

```bash
./manage-agents.sh build-all
```

For selective building, create a list:
```bash
cat > agents_to_build.txt << EOF
aider
autogpt
langchain
crewai
openai-swarm
EOF

while read agent; do
    ./manage-agents.sh build "$agent"
done < agents_to_build.txt
```

## Troubleshooting

### Problem: Port already in use
**Solution:** Check what's using the port and stop it, or change the port in docker-compose.yaml

```bash
# Find process using port 8080
lsof -i :8080

# Change port in docker-compose.yaml
ports:
  - "8081:8080"  # External:Internal
```

### Problem: Permission denied
**Solution:** Adjust file permissions

```bash
chmod -R 755 src config
```

### Problem: Container keeps restarting
**Solution:** Check logs to identify the issue

```bash
docker logs <container-name>
# or
./manage-agents.sh logs <agent-name>
```

### Problem: Cannot connect to other agents
**Solution:** Ensure all agents are on the same network

```bash
docker network ls
docker network inspect agent-network
```

## Best Practices

1. **Always test agents individually first** before running multiple agents
2. **Use .env files** for sensitive information (don't commit them!)
3. **Monitor resource usage** when running multiple agents
4. **Keep logs** for debugging by mounting a log directory
5. **Version your agent images** using tags
6. **Document your customizations** in the agent's README.md

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Python Docker Best Practices](https://docs.docker.com/language/python/)
- Main documentation: [DOCKER_USAGE.md](DOCKER_USAGE.md)
