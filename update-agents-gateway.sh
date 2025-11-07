#!/bin/bash
# Script to update all agent docker-compose files to use the API gateway

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"

echo "=========================================="
echo "API Gateway Configuration Updater"
echo "=========================================="
echo ""
echo "This script updates all agent docker-compose.yml files"
echo "to route API calls through the API gateway to Copilot and Ollama."
echo ""

# Function to update a single docker-compose.yml file
update_docker_compose() {
    local compose_file="$1"
    local agent_dir="$(dirname "$compose_file")"
    local agent_name="$(basename "$agent_dir")"
    
    echo "Updating: $agent_name"
    
    # Backup original file
    cp "$compose_file" "${compose_file}.backup"
    
    # Check if file already has network configuration
    if grep -q "agent-network" "$compose_file"; then
        echo "  ✓ Already configured (skipping)"
        rm "${compose_file}.backup"
        return 0
    fi
    
    # Extract service name (usually the agent name or first service)
    local service_name=$(grep -A 1 "^services:" "$compose_file" | tail -1 | sed 's/://g' | xargs)
    
    if [ -z "$service_name" ]; then
        echo "  ✗ Could not detect service name (skipping)"
        rm "${compose_file}.backup"
        return 1
    fi
    
    # Create temporary file with updated configuration
    cat > "${compose_file}.tmp" << 'EOF'
version: '3.8'

services:
EOF
    
    # Add service configuration with gateway settings
    sed -n "/^services:/,\$p" "$compose_file" | sed '1d' | \
    sed "/^  $service_name:/a\\
    environment:\\
      - OPENAI_API_BASE=http://api-gateway:80\\
      - OLLAMA_API_BASE=http://api-gateway:80/api\\
      - API_GATEWAY_HOST=api-gateway\\
      - API_GATEWAY_PORT=80\\
    networks:\\
      - agent-network" >> "${compose_file}.tmp"
    
    # Add networks section if not present
    if ! grep -q "^networks:" "${compose_file}.tmp"; then
        cat >> "${compose_file}.tmp" << 'EOF'

networks:
  agent-network:
    external: true
    name: agent-network
EOF
    fi
    
    # Replace original file
    mv "${compose_file}.tmp" "$compose_file"
    echo "  ✓ Updated successfully"
}

# Function to process all agents in a directory
process_agents() {
    local base_dir="$1"
    local count=0
    
    if [ ! -d "$base_dir/agents" ]; then
        echo "Warning: $base_dir/agents not found, skipping..."
        return 0
    fi
    
    for agent_dir in "$base_dir/agents"/*; do
        if [ -d "$agent_dir" ]; then
            local compose_file="$agent_dir/docker-compose.yml"
            if [ -f "$compose_file" ]; then
                update_docker_compose "$compose_file"
                ((count++))
            fi
        fi
    done
    
    echo "Processed $count agents in $base_dir"
}

# Main execution
main() {
    echo "Starting update process..."
    echo ""
    
    # Process list1 agents
    echo "Processing list1 agents..."
    process_agents "$REPO_ROOT/list1"
    echo ""
    
    # Process list2 agents
    echo "Processing list2 agents..."
    process_agents "$REPO_ROOT/list2"
    echo ""
    
    echo "=========================================="
    echo "Update Complete!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "1. Start the API gateway:"
    echo "   docker-compose -f docker-compose.gateway.yml up -d"
    echo ""
    echo "2. Start any agent:"
    echo "   cd list1/agents/your-agent && docker-compose up -d"
    echo ""
    echo "3. All API calls will now route through the gateway to Copilot and Ollama"
    echo ""
}

# Run main function
main
