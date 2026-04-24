from fastapi import FastAPI, HTTPException
import redis
import json
import yaml
import os

app = FastAPI(title="CHUCKY Orchestrator")

REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
REGISTRY_PATH = "/app/registry/agents.yaml"

r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)


def load_registry():
    with open(REGISTRY_PATH) as f:
        return yaml.safe_load(f)["agents"]


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/enqueue")
def enqueue(task: dict):
    if "task_id" not in task or "capability" not in task:
        raise HTTPException(status_code=400, detail="task_id and capability are required")
    r.rpush("task_queue", json.dumps(task))
    return {"status": "queued", "task_id": task["task_id"]}


@app.get("/dispatch")
def dispatch():
    task_raw = r.lpop("task_queue")
    if not task_raw:
        return {"status": "empty"}

    task = json.loads(task_raw)
    agents = load_registry()

    for agent in agents:
        if agent.get("status") != "active":
            continue
        if task["capability"] in agent["capabilities"]:
            task["image"] = agent["image"]
            task["agent_id"] = agent["id"]
            r.rpush("dispatch_queue", json.dumps(task))
            return {"status": "dispatched", "task_id": task["task_id"], "agent": agent["id"]}

    return {"status": "no-agent", "capability": task["capability"]}


@app.get("/queue/size")
def queue_size():
    return {
        "task_queue": r.llen("task_queue"),
        "dispatch_queue": r.llen("dispatch_queue"),
    }


@app.get("/agents")
def list_agents():
    agents = load_registry()
    return {"agents": agents, "total": len(agents)}


@app.post("/bulk-enqueue")
def bulk_enqueue(tasks: list):
    queued = []
    errors = []
    for task in tasks:
        if "task_id" not in task or "capability" not in task:
            errors.append(task)
            continue
        r.rpush("task_queue", json.dumps(task))
        queued.append(task["task_id"])
    return {"queued": queued, "errors": errors}
