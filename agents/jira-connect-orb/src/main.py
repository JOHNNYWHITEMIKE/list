#!/usr/bin/env python3
"""
Main entry point for Jira-Connect-Orb agent
"""
import os
import sys

def main():
    """Main function for the agent"""
    agent_name = os.environ.get('AGENT_NAME', 'Jira-Connect-Orb')
    print(f"Starting {agent_name} agent...")
    
    # Add your agent logic here
    print("Agent is running...")
    
    # For now, this is a placeholder
    # Refer to README.md for implementation details

if __name__ == "__main__":
    main()
