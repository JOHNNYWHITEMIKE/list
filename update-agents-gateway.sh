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

# Check if yq is available for robust YAML parsing
if command -v yq &> /dev/null; then
    USE_YQ=true
    echo "✓ Using yq for robust YAML parsing"
else
    USE_YQ=false
    echo "⚠ yq not found - using basic sed (less robust)"
    echo "  Install yq for better results: https://github.com/mikefarah/yq"
fi
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
    
    # Check if file already has environment configuration
    if grep -q "OPENAI_API_BASE.*api-gateway" "$compose_file"; then
        echo "  ✓ Already configured (skipping)"
        rm "${compose_file}.backup"
        return 0
    fi
    
    if [ "$USE_YQ" = true ]; then
        # Use yq for robust YAML manipulation
        update_with_yq "$compose_file"
    else
        # Fallback to basic sed
        update_with_sed "$compose_file"
    fi
    
    echo "  ✓ Updated successfully"
}

# Function to update using yq (robust)
update_with_yq() {
    local compose_file="$1"
    
    # Get first service name
    local service_name=$(yq eval '.services | keys | .[0]' "$compose_file")
    
    if [ -z "$service_name" ] || [ "$service_name" = "null" ]; then
        echo "  ✗ Could not detect service name (skipping)"
        mv "${compose_file}.backup" "$compose_file"
        return 1
    fi
    
    # Add environment variables (merge with existing)
    yq eval -i ".services.$service_name.environment += [
        \"OPENAI_API_BASE=http://api-gateway:80\",
        \"OLLAMA_API_BASE=http://api-gateway:80/api\",
        \"API_GATEWAY_HOST=api-gateway\",
        \"API_GATEWAY_PORT=80\"
    ]" "$compose_file"
    
    # Add network (merge with existing)
    yq eval -i ".services.$service_name.networks += [\"agent-network\"]" "$compose_file"
    
    # Add top-level networks section
    yq eval -i '.networks.agent-network.external = true' "$compose_file"
    yq eval -i '.networks.agent-network.name = "agent-network"' "$compose_file"
}

# Function to update using sed (fallback)
update_with_sed() {
    local compose_file="$1"
    
    # Extract service name (first service after 'services:')
    local service_name=$(grep -A 1 "^services:" "$compose_file" | tail -1 | sed 's/://g' | sed 's/^[[:space:]]*//')
    
    if [ -z "$service_name" ]; then
        echo "  ✗ Could not detect service name (skipping)"
        mv "${compose_file}.backup" "$compose_file"
        return 1
    fi
    
    # Create a temporary Python script for safer YAML manipulation
    python3 << EOF
import yaml
import sys

with open("$compose_file", 'r') as f:
    config = yaml.safe_load(f)

# Get first service
service_name = "$service_name"
if service_name not in config.get('services', {}):
    services = list(config.get('services', {}).keys())
    if services:
        service_name = services[0]
    else:
        print("  ✗ No services found in docker-compose.yml", file=sys.stderr)
        sys.exit(1)

# Add environment variables
if 'environment' not in config['services'][service_name]:
    config['services'][service_name]['environment'] = []

env = config['services'][service_name]['environment']
if isinstance(env, list):
    env.extend([
        'OPENAI_API_BASE=http://api-gateway:80',
        'OLLAMA_API_BASE=http://api-gateway:80/api',
        'API_GATEWAY_HOST=api-gateway',
        'API_GATEWAY_PORT=80'
    ])
else:
    # Environment is a dict
    env.update({
        'OPENAI_API_BASE': 'http://api-gateway:80',
        'OLLAMA_API_BASE': 'http://api-gateway:80/api',
        'API_GATEWAY_HOST': 'api-gateway',
        'API_GATEWAY_PORT': '80'
    })

# Add networks
if 'networks' not in config['services'][service_name]:
    config['services'][service_name]['networks'] = []
if 'agent-network' not in config['services'][service_name]['networks']:
    config['services'][service_name]['networks'].append('agent-network')

# Add top-level networks
if 'networks' not in config:
    config['networks'] = {}
config['networks']['agent-network'] = {
    'external': True,
    'name': 'agent-network'
}

# Write back
with open("$compose_file", 'w') as f:
    yaml.dump(config, f, default_flow_style=False, sort_keys=False)
EOF
    
    if [ $? -ne 0 ]; then
        echo "  ✗ Failed to update (restoring backup)"
        mv "${compose_file}.backup" "$compose_file"
        return 1
    fi
}

# Function to process all agents in a directory
process_agents() {
    local base_dir="$1"
    local count=0
    local failed=0
    
    if [ ! -d "$base_dir/agents" ]; then
        echo "Warning: $base_dir/agents not found, skipping..."
        return 0
    fi
    
    for agent_dir in "$base_dir/agents"/*; do
        if [ -d "$agent_dir" ]; then
            local compose_file="$agent_dir/docker-compose.yml"
            if [ -f "$compose_file" ]; then
                if update_docker_compose "$compose_file"; then
                    ((count++))
                else
                    ((failed++))
                fi
            fi
        fi
    done
    
    echo "Processed $count agents in $base_dir ($failed failed)"
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
    echo "1. Review changes: git diff list1/agents/*/docker-compose.yml"
    echo "2. Start the API gateway:"
    echo "   docker-compose -f docker-compose.gateway.yml up -d"
    echo ""
    echo "3. Start any agent:"
    echo "   cd list1/agents/your-agent && docker-compose up -d"
    echo ""
    echo "4. All API calls will now route through the gateway to Copilot and Ollama"
    echo ""
    echo "Backup files: *.backup (delete after verification)"
    echo ""
}

# Run main function
main
