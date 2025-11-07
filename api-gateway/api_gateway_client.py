"""
API Gateway Client Library
Ensures all API calls route through the gateway to Copilot and Ollama
"""

import os
from typing import Optional


class APIGatewayConfig:
    """Configuration for API Gateway routing"""
    
    def __init__(self):
        self.gateway_host = os.getenv('API_GATEWAY_HOST', 'api-gateway')
        self.gateway_port = os.getenv('API_GATEWAY_PORT', '80')
        self.gateway_url = f"http://{self.gateway_host}:{self.gateway_port}"
        
    @property
    def openai_base_url(self) -> str:
        """Get OpenAI API base URL (routes to Copilot via gateway)"""
        return os.getenv('OPENAI_API_BASE', self.gateway_url)
    
    @property
    def ollama_base_url(self) -> str:
        """Get Ollama API base URL (routes to Ollama Cloud via gateway)"""
        return os.getenv('OLLAMA_API_BASE', f"{self.gateway_url}/api")
    
    def configure_openai_client(self):
        """Configure OpenAI client to use gateway"""
        try:
            import openai
            openai.api_base = self.openai_base_url
            print(f"✓ OpenAI client configured to use gateway: {self.openai_base_url}")
            return True
        except ImportError:
            print("⚠ OpenAI library not installed, skipping configuration")
            return False
    
    def get_ollama_client_config(self) -> dict:
        """Get configuration for Ollama client"""
        return {
            'base_url': self.ollama_base_url,
            'timeout': 300,
        }
    
    def verify_gateway_connection(self) -> bool:
        """Verify connection to API gateway"""
        try:
            import requests
            response = requests.get(f"{self.gateway_url}/health", timeout=5)
            if response.status_code == 200:
                print(f"✓ API Gateway is reachable at {self.gateway_url}")
                return True
            else:
                print(f"✗ API Gateway returned status code: {response.status_code}")
                return False
        except Exception as e:
            print(f"✗ Cannot connect to API Gateway: {e}")
            print(f"  Make sure the gateway is running: docker-compose -f docker-compose.gateway.yml up -d")
            return False
    
    def enforce_gateway_usage(self):
        """
        Enforce that all API calls go through the gateway
        This prevents accidental direct API calls
        """
        # Override common API endpoint environment variables
        os.environ['OPENAI_API_BASE'] = self.openai_base_url
        os.environ['OLLAMA_HOST'] = self.ollama_base_url
        
        # Configure OpenAI if available
        self.configure_openai_client()
        
        print("\n" + "="*60)
        print("API GATEWAY ENFORCED")
        print("="*60)
        print(f"OpenAI/Copilot calls → {self.openai_base_url}")
        print(f"Ollama calls         → {self.ollama_base_url}")
        print("="*60 + "\n")


def init_gateway(verify_connection: bool = True) -> APIGatewayConfig:
    """
    Initialize API gateway configuration for the agent
    
    Args:
        verify_connection: Whether to verify gateway is reachable
        
    Returns:
        APIGatewayConfig instance
        
    Example:
        >>> from api_gateway_client import init_gateway
        >>> gateway = init_gateway()
        >>> # All API calls now route through gateway
    """
    config = APIGatewayConfig()
    config.enforce_gateway_usage()
    
    if verify_connection:
        if not config.verify_gateway_connection():
            print("\n⚠ WARNING: API Gateway is not reachable!")
            print("  Start it with: docker-compose -f docker-compose.gateway.yml up -d\n")
    
    return config


# Example usage for OpenAI
def get_openai_client():
    """Get OpenAI client configured to use gateway"""
    try:
        import openai
        config = APIGatewayConfig()
        
        # Get API key from environment, raise error if missing
        api_key = os.getenv('OPENAI_API_KEY') or os.getenv('GITHUB_TOKEN')
        if not api_key:
            raise ValueError(
                "No API key found. Set OPENAI_API_KEY or GITHUB_TOKEN environment variable. "
                "For GitHub Copilot, obtain a token from https://github.com/settings/tokens"
            )
        
        client = openai.OpenAI(
            api_key=api_key,
            base_url=config.openai_base_url
        )
        print(f"✓ OpenAI client created (routes to Copilot via gateway)")
        return client
    except ImportError:
        raise ImportError("openai library is required. Install with: pip install openai")


# Example usage for Ollama
def get_ollama_client():
    """Get Ollama client configured to use gateway"""
    try:
        import ollama
        config = APIGatewayConfig()
        client = ollama.Client(host=config.ollama_base_url)
        print(f"✓ Ollama client created (routes to Ollama Cloud via gateway)")
        return client
    except ImportError:
        raise ImportError("ollama library is required. Install with: pip install ollama")


if __name__ == "__main__":
    # Demo/test the configuration
    print("API Gateway Client Configuration Test\n")
    gateway = init_gateway(verify_connection=True)
    
    print("\nConfiguration:")
    print(f"  Gateway URL: {gateway.gateway_url}")
    print(f"  OpenAI Base: {gateway.openai_base_url}")
    print(f"  Ollama Base: {gateway.ollama_base_url}")
