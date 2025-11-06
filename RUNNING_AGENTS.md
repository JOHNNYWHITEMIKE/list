# Running Agents with Docker Compose

This repository includes automation scripts to run all AI agents in sequence.

## Quick Start

### Run All Agents

To run all 1423 agents sequentially with the default timing:

```bash
./run-agents.sh
```

This will:
1. Start each agent with `docker compose up -d`
2. Wait 100 seconds
3. Stop the agent with `docker compose down`
4. Wait 10 seconds
5. Move to the next agent

**Total estimated time:** ~2 hours for all agents

### Run Specific Agents

You can modify the script to run specific agents or lists:

```bash
# Run only list1 agents
cd list1/agents
for dir in */; do
  if [ -f "$dir/docker-compose.yml" ]; then
    cd "$dir"
    docker compose up -d
    sleep 100
    docker compose down
    sleep 10
    cd ..
  fi
done
```

### Customize Timing

Edit `run-agents.sh` and modify these variables:

```bash
SLEEP_AFTER_UP=100    # Seconds to wait after starting agent
SLEEP_AFTER_DOWN=10   # Seconds to wait after stopping agent
```

## Script Details

### run-agents.sh

The main automation script that:
- Processes all agents in `list1/agents/` (711 agents)
- Processes all agents in `list2/agents/` (712 agents)
- Logs progress for each agent
- Handles errors gracefully

### Requirements

- Docker Engine
- Docker Compose v2 (included with modern Docker installations)

### Troubleshooting

**Issue:** `docker compose: command not found`
- **Solution:** Install Docker Compose v2 or use `docker-compose` (v1) instead

**Issue:** Permission denied
- **Solution:** Make the script executable: `chmod +x run-agents.sh`

**Issue:** Out of disk space
- **Solution:** Clean up Docker: `docker system prune -a --volumes`

**Issue:** `non-string key in services` error for some agents
- **Cause:** Some agents (like "01") use numeric service names in their docker-compose.yml which are interpreted as numbers by YAML parsers
- **Impact:** These agents will fail to start but the script will continue with remaining agents
- **Solution:** Edit the affected agent's docker-compose.yml to quote the service name (e.g., `"01":` instead of `01:`)

## Advanced Usage

### Run Agents in Parallel (Advanced)

⚠️ **Warning:** Running multiple agents in parallel requires significant system resources.

```bash
# Run up to 5 agents at a time
cd list1/agents
ls -d */ | xargs -n1 -P5 -I{} bash -c 'cd {} && docker compose up -d && sleep 100 && docker compose down && sleep 10'
```

### Monitor Progress

You can monitor the output by redirecting to a log file:

```bash
./run-agents.sh 2>&1 | tee agents-run.log
```

### Skip Specific Agents

Edit `run-agents.sh` and add skip logic:

```bash
# Skip specific agents
if [[ "$agent_name" == "problematic-agent" ]]; then
    echo "  -> Skipping $agent_name"
    continue
fi
```
