# CHUCKY Minimal Control System

A governed, distributed agent execution system. Routes tasks to capable agents via a central Redis queue, executes them as Docker containers, and validates results.

## Architecture

```
Input → Enqueue → Dispatch → Execute (Docker) → Result
```

**Components:**
- **Redis** — central task queue (`task_queue` → `dispatch_queue` → `results`)
- **Orchestrator** (FastAPI) — accepts tasks, matches agents by capability, dispatches
- **Worker** (Python) — pulls dispatched tasks, runs agent Docker containers
- **Registry** — YAML file mapping agent IDs, images, and capabilities

## Quick Start

```bash
cd chucky
docker-compose up --build
```

## Send a Task

```bash
curl -X POST http://localhost:8000/enqueue \
  -H "Content-Type: application/json" \
  -d '{"task_id":"t1","capability":"text.summarize","payload":{"text":"hello world"}}'
```

Then trigger dispatch:

```bash
curl http://localhost:8000/dispatch
```

## Bulk Load Tasks from File

```bash
curl -X POST http://localhost:8000/bulk-enqueue \
  -H "Content-Type: application/json" \
  -d @tasks/tasks.json
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check |
| POST | `/enqueue` | Queue a single task |
| POST | `/bulk-enqueue` | Queue multiple tasks |
| GET | `/dispatch` | Dispatch next task to an agent |
| GET | `/queue/size` | Current queue depths |
| GET | `/agents` | List registered agents |

## Adding Agents

Edit `registry/agents.yaml`:

```yaml
agents:
  - id: my-agent
    image: myorg/my-agent:latest
    capabilities:
      - my.capability
    resources:
      cpu: "0.5"
      memory: "1Gi"
    status: active
```

Only agents with `status: active` receive tasks.

## Validation

- Tasks with no matching active agent are rejected (`no-agent` status)
- Container failures are logged and recorded in the `results` queue
- Workers reconnect automatically on Redis connection loss

## Scale Workers

```bash
docker-compose up --scale worker=5
```
