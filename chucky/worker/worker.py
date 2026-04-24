import redis
import json
import docker
import time
import os
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
log = logging.getLogger(__name__)

REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))

r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)
client = docker.from_env()


def run_agent(image, task_id, payload):
    try:
        container = client.containers.run(
            image,
            detach=True,
            environment={"PAYLOAD": json.dumps(payload), "TASK_ID": task_id},
            remove=True,
            mem_limit="512m",
            cpu_period=100000,
            cpu_quota=25000,
        )
        log.info(f"Started container {container.short_id} for task {task_id}")
        return {"status": "success", "container_id": container.short_id}
    except docker.errors.ImageNotFound:
        log.error(f"Image not found: {image}")
        return {"status": "error", "error": f"Image not found: {image}"}
    except docker.errors.APIError as e:
        log.error(f"Docker API error for task {task_id}: {e}")
        return {"status": "error", "error": str(e)}
    except Exception as e:
        log.error(f"Unexpected error for task {task_id}: {e}")
        return {"status": "error", "error": str(e)}


def main():
    log.info("Worker started, waiting for tasks on dispatch_queue...")
    while True:
        try:
            task_raw = r.brpop("dispatch_queue", timeout=5)
            if not task_raw:
                continue

            task = json.loads(task_raw[1])
            task_id = task.get("task_id", "unknown")
            image = task.get("image")
            payload = task.get("payload", {})

            if not image:
                log.warning(f"Task {task_id} has no image assigned — skipping")
                continue

            log.info(f"Processing task {task_id} with image {image}")
            result = run_agent(image, task_id, payload)
            log.info(f"Task {task_id} result: {result}")

            r.rpush("results", json.dumps({"task_id": task_id, "result": result}))

        except redis.exceptions.ConnectionError as e:
            log.error(f"Redis connection error: {e} — retrying in 5s")
            time.sleep(5)
        except Exception as e:
            log.error(f"Worker loop error: {e}")
            time.sleep(1)


if __name__ == "__main__":
    main()
