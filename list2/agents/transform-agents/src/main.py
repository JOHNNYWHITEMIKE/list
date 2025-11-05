#!/usr/bin/env python3
"""
Main entry point for transform-agents agent.
"""

import os
import yaml
from pathlib import Path


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
    
    print(f"Starting transform-agents...")
    print("Agent is running. Implement your logic here.")
    
    # Add your agent implementation here
    

if __name__ == "__main__":
    main()
