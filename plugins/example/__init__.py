"""
Example NUNA Plugin

This is an example plugin that demonstrates the structure and capabilities
of the NUNA plugin system.
"""


def initialize():
    """Initialize the plugin."""
    print("Example plugin initialized")


def main():
    """Main entry point for the plugin."""
    print("Example plugin running")
    return {"status": "success", "message": "Example plugin executed"}


def get_info():
    """Return plugin information."""
    return {
        "name": "Example Plugin",
        "version": "1.0.0",
        "capabilities": ["demo", "example"]
    }
