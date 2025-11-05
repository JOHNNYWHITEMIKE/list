# List2 - AI Agents Collection

This directory contains 712 AI agents, each with Docker containerization support.

## Structure

Each agent is organized as:
```
agents/
  agent-name/
    Dockerfile
    docker-compose.yml
    config/
      config.yaml
    src/
      main.py
    data/
    README.md
```

## Usage

To run an agent:
```bash
cd agents/agent-name
docker-compose up -d
```

To stop an agent:
```bash
cd agents/agent-name
docker-compose down
```

## Agents

Total: 712 agents
