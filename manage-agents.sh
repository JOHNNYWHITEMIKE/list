#!/bin/bash

# Agent Management Script
# This script helps manage Docker containers for multiple agents

set -e

AGENTS_DIR="./agents"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Function to list all agents
list_agents() {
    echo "Available agents:"
    cd "$AGENTS_DIR"
    ls -d */ | sed 's|/||' | nl
}

# Function to build a specific agent
build_agent() {
    local agent_name=$1
    local agent_path="$AGENTS_DIR/$agent_name"
    
    if [ ! -d "$agent_path" ]; then
        print_error "Agent '$agent_name' not found"
        exit 1
    fi
    
    print_info "Building agent: $agent_name"
    cd "$agent_path"
    docker-compose build
    print_success "Agent '$agent_name' built successfully"
}

# Function to start a specific agent
start_agent() {
    local agent_name=$1
    local agent_path="$AGENTS_DIR/$agent_name"
    
    if [ ! -d "$agent_path" ]; then
        print_error "Agent '$agent_name' not found"
        exit 1
    fi
    
    print_info "Starting agent: $agent_name"
    cd "$agent_path"
    docker-compose up -d
    print_success "Agent '$agent_name' started successfully"
}

# Function to stop a specific agent
stop_agent() {
    local agent_name=$1
    local agent_path="$AGENTS_DIR/$agent_name"
    
    if [ ! -d "$agent_path" ]; then
        print_error "Agent '$agent_name' not found"
        exit 1
    fi
    
    print_info "Stopping agent: $agent_name"
    cd "$agent_path"
    docker-compose down
    print_success "Agent '$agent_name' stopped successfully"
}

# Function to view logs for a specific agent
logs_agent() {
    local agent_name=$1
    local agent_path="$AGENTS_DIR/$agent_name"
    
    if [ ! -d "$agent_path" ]; then
        print_error "Agent '$agent_name' not found"
        exit 1
    fi
    
    print_info "Showing logs for agent: $agent_name"
    cd "$agent_path"
    docker-compose logs -f
}

# Function to check status of all agents
status_agents() {
    print_info "Checking status of all agents..."
    docker ps --filter "network=agent-network" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Function to stop all agents
stop_all() {
    print_info "Stopping all agents..."
    cd "$AGENTS_DIR"
    for agent_dir in */; do
        agent_name="${agent_dir%/}"
        if [ -f "$agent_dir/docker-compose.yaml" ]; then
            cd "$agent_dir"
            docker-compose down 2>/dev/null || true
            cd ..
            print_success "Stopped $agent_name"
        fi
    done
}

# Function to build all agents
build_all() {
    print_info "Building all agents..."
    cd "$AGENTS_DIR"
    local count=0
    for agent_dir in */; do
        agent_name="${agent_dir%/}"
        if [ -f "$agent_dir/docker-compose.yaml" ]; then
            cd "$agent_dir"
            echo -n "Building $agent_name... "
            if docker-compose build > /dev/null 2>&1; then
                print_success "done"
                ((count++))
            else
                print_error "failed"
            fi
            cd ..
        fi
    done
    print_success "Built $count agents successfully"
}

# Function to display help
show_help() {
    cat << EOF
Agent Management Script

Usage: $0 <command> [agent-name]

Commands:
  list                  List all available agents
  build <agent-name>    Build a specific agent's Docker image
  build-all            Build all agents (may take a while)
  start <agent-name>    Start a specific agent
  stop <agent-name>     Stop a specific agent
  stop-all             Stop all running agents
  logs <agent-name>     View logs for a specific agent
  status               Show status of all running agents
  help                 Show this help message

Examples:
  $0 list
  $0 build aider
  $0 start autogpt
  $0 logs langchain
  $0 stop crewai
  $0 status
  $0 stop-all

EOF
}

# Main script logic
main() {
    cd "$SCRIPT_DIR"
    
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    case "$1" in
        list)
            list_agents
            ;;
        build)
            if [ -z "$2" ]; then
                print_error "Please specify an agent name"
                exit 1
            fi
            build_agent "$2"
            ;;
        build-all)
            build_all
            ;;
        start)
            if [ -z "$2" ]; then
                print_error "Please specify an agent name"
                exit 1
            fi
            start_agent "$2"
            ;;
        stop)
            if [ -z "$2" ]; then
                print_error "Please specify an agent name"
                exit 1
            fi
            stop_agent "$2"
            ;;
        stop-all)
            stop_all
            ;;
        logs)
            if [ -z "$2" ]; then
                print_error "Please specify an agent name"
                exit 1
            fi
            logs_agent "$2"
            ;;
        status)
            status_agents
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
