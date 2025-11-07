#!/usr/bin/env python3
"""
Main entry point for agentacc-batch-test agent.
"""

import os
import sys
import yaml
from pathlib import Path

# Add API gateway client to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent.parent / "api-gateway"))

try:
    from api_gateway_client import init_gateway
    # Initialize gateway - this ensures all API calls route to Copilot and Ollama
    gateway = init_gateway(verify_connection=True)
except ImportError:
    print("⚠ Warning: API gateway client not available")
    print("  API calls may not be routed correctly")
    gateway = None


def load_config():
    """Load agent configuration."""
    config_path = Path(__file__).parent.parent / "config" / "config.yaml"
    if config_path.exists():
        with open(config_path, 'r') as f:
            return yaml.safe_load(f)
    return {}


def main():
    """Main agent logic."""
    config = load_config()
    agent_name = config.get('agent', {}).get('name', 'unknown')
    
    print(f"Starting {agent_name}...")
    
    if gateway:
        print(f"✓ All API calls will route through gateway to Copilot and Ollama")
    
    print("Agent is running. Implement your logic here.")
    
    # Example: Using OpenAI client (routes to Copilot via gateway)
    # from api_gateway_client import get_openai_client
    # client = get_openai_client()
    # response = client.chat.completions.create(
    #     model="gpt-4",
    #     messages=[{"role": "user", "content": "Hello"}]
    # )
    
    # Example: Using Ollama client (routes to Ollama Cloud via gateway)
    # from api_gateway_client import get_ollama_client
    # client = get_ollama_client()
    # response = client.generate(model='llama2', prompt='Hello')
    
    # Add your agent implementation here
    

if __name__ == "__main__":
    main()
