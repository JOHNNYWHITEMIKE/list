#!/bin/bash

# Script to run docker compose up, wait, then down for all agent folders
# Usage: ./run-agents.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SLEEP_AFTER_UP=100
SLEEP_AFTER_DOWN=10

echo "Starting docker compose cycle for all agent folders..."
echo "Sleep after up: ${SLEEP_AFTER_UP}s, Sleep after down: ${SLEEP_AFTER_DOWN}s"
echo ""

# Function to process agents in a directory
process_agents() {
    local base_dir=$1
    local agent_count=0
    
    if [ ! -d "$base_dir" ]; then
        echo "Directory $base_dir does not exist, skipping..."
        return
    fi
    
    echo "Processing agents in: $base_dir"
    
    # Loop through each agent directory
    for agent_dir in "$base_dir"/*/; do
        if [ -f "$agent_dir/docker-compose.yml" ]; then
            agent_count=$((agent_count + 1))
            agent_name=$(basename "$agent_dir")
            
            echo "[$agent_count] Processing agent: $agent_name"
            
            # Navigate to agent directory
            cd "$agent_dir"
            
            # Run docker compose up
            echo "  -> Running docker compose up..."
            docker compose up -d
            
            # Sleep for specified duration
            echo "  -> Waiting ${SLEEP_AFTER_UP} seconds..."
            sleep ${SLEEP_AFTER_UP}
            
            # Run docker compose down
            echo "  -> Running docker compose down..."
            docker compose down
            
            # Sleep for specified duration
            echo "  -> Waiting ${SLEEP_AFTER_DOWN} seconds..."
            sleep ${SLEEP_AFTER_DOWN}
            
            echo "  -> Completed: $agent_name"
            echo ""
        fi
    done
    
    echo "Processed $agent_count agents in $base_dir"
    echo ""
}

# Process list1 agents
process_agents "$SCRIPT_DIR/list1/agents"

# Process list2 agents
process_agents "$SCRIPT_DIR/list2/agents"

echo "All agents processed successfully!"
