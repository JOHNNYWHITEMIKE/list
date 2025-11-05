# Migration Guide: Repository Restructuring

## Overview

This repository has been restructured from a flat documentation structure into two Docker-ready agent collections.

## What Changed

### Before
```
agents/
  agent-name.md
  another-agent.md
  ...
```

### After
```
list1/
  agents/
    agent-name/
      Dockerfile
      docker-compose.yml
      config/
      src/
      data/
      README.md
    ...

list2/
  agents/
    agent-name/
      Dockerfile
      docker-compose.yml
      config/
      src/
      data/
      README.md
    ...

agents/              # Original .md files preserved
  agent-name.md
  ...
```

## Key Changes

1. **Split into Two Collections**: 1423 agents split into:
   - **list1**: 711 agents (01 through instructor)
   - **list2**: 712 agents (instrukt through zorow)

2. **Docker Infrastructure**: Each agent now includes:
   - `Dockerfile` - Container definition with Python 3.11
   - `docker-compose.yml` - Service orchestration
   - `requirements.txt` - Python dependencies
   - `config/config.yaml` - Configuration file
   - `src/main.py` - Main entry point template
   - `data/` - Runtime data directory
   - `README.md` - Original documentation

3. **Original Files Preserved**: All original `.md` files remain in `agents/` directory

## Using the New Structure

### Running an Agent

```bash
# Navigate to agent directory
cd list1/agents/autogpt

# Start the agent
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the agent
docker-compose down
```

### Customizing an Agent

1. **Edit Configuration**: Modify `config/config.yaml`
2. **Add Dependencies**: Update `requirements.txt`
3. **Implement Logic**: Edit `src/main.py`
4. **Rebuild**: Run `docker-compose build`
5. **Test**: Run `docker-compose up`

### Development Workflow

```bash
# Make changes to your agent
cd list1/agents/your-agent

# Edit files
nano src/main.py
nano config/config.yaml

# Rebuild and test
docker-compose build
docker-compose up

# View output
docker-compose logs -f
```

## File Structure Explained

### Dockerfile
- Base image: `python:3.11-slim`
- Copies source code and configuration
- Installs dependencies from `requirements.txt`
- Runs `src/main.py` as the main process

### docker-compose.yml
- Defines the service
- Sets environment variables
- Mounts `config/` and `data/` volumes
- Configures restart policy

### config/config.yaml
- Agent-specific configuration
- Loaded by `src/main.py` at runtime
- Editable without rebuilding

### src/main.py
- Main entry point template
- Loads configuration
- Contains placeholder for agent logic

### requirements.txt
- Python package dependencies
- Add packages as needed (e.g., `openai>=1.0.0`)

## Migration Checklist

If you were using the old structure:

- [ ] Update documentation references from `agents/name.md` to `list1/agents/name/README.md` or `list2/agents/name/README.md`
- [ ] Install Docker if you plan to run agents
- [ ] Review the new agent structure in `list1/` and `list2/`
- [ ] Test running a sample agent with docker-compose
- [ ] Update any automation or scripts to use the new paths

## Benefits of New Structure

1. **Containerization**: Each agent runs in isolated environment
2. **Standardization**: Consistent structure across all agents
3. **Easy Deployment**: Simple `docker-compose up` to run any agent
4. **Configuration Management**: Centralized config files
5. **Scalability**: Each agent can be deployed independently
6. **Development Ready**: Template code for quick implementation

## Finding an Agent

Agents are split alphabetically:
- **list1**: Agents starting with 0-9, A-I
- **list2**: Agents starting with J-Z

Use search or browse the directories:
```bash
# Search for an agent
find list1/agents list2/agents -name "*autogpt*" -type d

# List all agents in list1
ls -1 list1/agents/

# List all agents in list2
ls -1 list2/agents/
```

## Support

For questions or issues:
1. Check the agent's `README.md` for specific documentation
2. Review the root `README.md` for general guidance
3. Refer to original `agents/*.md` files for historical context
4. Open an issue in the repository

## Rollback

Original markdown files are preserved in `agents/` directory if you need to reference the old structure.
