# Docker Container Usage Guide

This repository now includes Docker container configurations for all 1423 AI agents. Each agent has its own directory with a complete Docker setup.

## Directory Structure

Each agent directory follows this standardized structure:

```
agents/
  agent-name/
    ├── Dockerfile              # Docker image configuration
    ├── docker-compose.yaml     # Docker Compose orchestration
    ├── config/
    │   └── config.yaml        # Agent configuration
    ├── src/
    │   └── main.py            # Main entry point
    └── README.md              # Agent documentation
```

## Quick Start

### Running a Single Agent

To run a specific agent using Docker Compose:

```bash
cd agents/agent-name
docker-compose up
```

To run in detached mode:

```bash
cd agents/agent-name
docker-compose up -d
```

### Building the Docker Image

To build the Docker image for an agent:

```bash
cd agents/agent-name
docker build -t agent-name:latest .
```

### Running with Docker

To run the container directly:

```bash
cd agents/agent-name
docker run -v $(pwd)/config:/app/config -v $(pwd)/data:/app/data agent-name:latest
```

## Configuration

Each agent has a `config/config.yaml` file that contains:
- Agent name
- Agent description
- GitHub URL (if available)
- Custom configuration options

You can modify this file to customize the agent's behavior.

## Customization

### Adding Dependencies

To add Python dependencies for an agent:

1. Create a `requirements.txt` file in the agent directory
2. Add your dependencies
3. Rebuild the Docker image

Example:
```bash
cd agents/agent-name
echo "requests==2.31.0" > requirements.txt
docker-compose build
```

### Modifying the Agent Code

The main agent logic is in `src/main.py`. You can:
1. Edit this file to implement the agent's functionality
2. Add additional Python modules in the `src/` directory
3. The changes will be reflected when you rebuild the container

### Environment Variables

You can set environment variables in the `docker-compose.yaml` file:

```yaml
environment:
  - AGENT_NAME=MyAgent
  - API_KEY=your-api-key
  - DEBUG=true
```

## Networking

All agents are configured to use a shared Docker network called `agent-network`. This allows multiple agents to communicate with each other.

To run multiple agents together:

```bash
cd agents/agent-name-1
docker-compose up -d

cd ../agent-name-2
docker-compose up -d
```

They will automatically be on the same network and can communicate using their container names.

## Volume Mounts

Each agent has the following volumes mounted:
- `./src:/app/src` - Source code (for development)
- `./config:/app/config` - Configuration files
- `./data:/app/data` - Data directory (create this if needed)

## Stopping Agents

To stop a running agent:

```bash
cd agents/agent-name
docker-compose down
```

To stop and remove volumes:

```bash
cd agents/agent-name
docker-compose down -v
```

## Logs

To view agent logs:

```bash
cd agents/agent-name
docker-compose logs
```

To follow logs in real-time:

```bash
cd agents/agent-name
docker-compose logs -f
```

## Common Issues

### Port Conflicts

If you need to expose ports, add them to the `docker-compose.yaml`:

```yaml
ports:
  - "8080:8080"
```

### Permission Issues

If you encounter permission issues with mounted volumes, you may need to adjust file permissions:

```bash
chmod -R 755 src config
```

## Next Steps

1. Choose an agent from the `agents/` directory
2. Review its `README.md` for specific implementation details
3. Customize the `config/config.yaml` as needed
4. Implement the agent logic in `src/main.py`
5. Build and run using Docker Compose

## Contributing

When implementing an agent:
1. Follow the existing structure
2. Update the `README.md` with specific instructions
3. Add any required dependencies to `requirements.txt`
4. Test the Docker build and run process
5. Document any special configuration requirements

For more information about specific agents, refer to their individual README.md files.
