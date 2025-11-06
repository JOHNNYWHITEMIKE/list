#!/bin/bash

# Script to run docker compose up, wait, then down for all agent folders
# Usage: ./run-agents.sh

# Don't exit on error - we want to continue processing even if one agent fails
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SLEEP_AFTER_UP=100
SLEEP_AFTER_DOWN=10
FAILED_AGENTS=()
SUCCESS_COUNT=0
FAIL_COUNT=0

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
            
            # Navigate to agent directory using pushd for safety
            pushd "$agent_dir" > /dev/null || {
                echo "  -> Failed: $agent_name (unable to access directory)"
                FAILED_AGENTS+=("$agent_name")
                FAIL_COUNT=$((FAIL_COUNT + 1))
                continue
            }
            
            # Run docker compose up
            echo "  -> Running docker compose up..."
            if docker compose up -d 2>&1; then
                # Sleep for specified duration
                echo "  -> Waiting ${SLEEP_AFTER_UP} seconds..."
                sleep ${SLEEP_AFTER_UP}
                
                # Run docker compose down
                echo "  -> Running docker compose down..."
                if docker compose down 2>&1; then
                    echo "  -> Completed: $agent_name"
                    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
                else
                    echo "  -> Failed: $agent_name (docker compose down failed)"
                    FAILED_AGENTS+=("$agent_name")
                    FAIL_COUNT=$((FAIL_COUNT + 1))
                fi
                
                # Sleep for specified duration
                echo "  -> Waiting ${SLEEP_AFTER_DOWN} seconds..."
                sleep ${SLEEP_AFTER_DOWN}
            else
                echo "  -> Failed: $agent_name (docker compose up failed)"
                FAILED_AGENTS+=("$agent_name")
                FAIL_COUNT=$((FAIL_COUNT + 1))
            fi
            
            # Return to previous directory
            popd > /dev/null
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

echo "========================================="
echo "Processing complete!"
echo "Success: $SUCCESS_COUNT agents"
echo "Failed: $FAIL_COUNT agents"

if [ ${#FAILED_AGENTS[@]} -gt 0 ]; then
    echo ""
    echo "Failed agents:"
    for agent in "${FAILED_AGENTS[@]}"; do
        echo "  - $agent"
    done
fi
echo "========================================="
