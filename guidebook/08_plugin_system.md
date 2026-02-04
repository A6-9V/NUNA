# Plugin System Guide

## Overview

The NUNA plugin system provides a flexible framework for extending functionality through modular plugins. This guide covers plugin development, integration, and management.

## Table of Contents

1. [Plugin Architecture](#plugin-architecture)
2. [Creating Plugins](#creating-plugins)
3. [Plugin API](#plugin-api)
4. [Loading and Managing Plugins](#loading-and-managing-plugins)
5. [External Plugin Integration](#external-plugin-integration)
6. [Best Practices](#best-practices)

## Plugin Architecture

### Directory Structure

```
NUNA/
├── plugins/                    # Plugin directory
│   ├── __init__.py            # Plugin system initialization
│   ├── README.md              # Plugin documentation
│   ├── example/               # Example plugin
│   │   ├── __init__.py        # Plugin code
│   │   ├── plugin.json        # Plugin metadata
│   │   └── README.md          # Plugin-specific docs
│   └── your_plugin/           # Your custom plugin
│       ├── __init__.py
│       └── plugin.json
├── plugin_loader.py           # Plugin loader utility
└── plugin_config.example.json # Plugin configuration template
```

### Plugin Components

Each plugin consists of:

1. **Plugin Directory**: A folder under `plugins/` containing all plugin files
2. **__init__.py**: Main plugin code with required functions
3. **plugin.json**: Metadata describing the plugin (optional but recommended)
4. **README.md**: Plugin documentation (optional)

## Creating Plugins

### Basic Plugin Template

Create a new directory under `plugins/` with the following structure:

**plugins/my_plugin/__init__.py:**
```python
"""
My Plugin - Description of what it does
"""

def initialize():
    """
    Called when plugin is first loaded.
    Use for setup, configuration, or initialization.
    """
    print("My plugin initialized")

def main():
    """
    Main entry point for plugin execution.
    
    Returns:
        dict: Result of plugin execution
    """
    # Your plugin logic here
    result = perform_plugin_task()
    return {"status": "success", "data": result}

def get_info():
    """
    Returns information about the plugin.
    
    Returns:
        dict: Plugin information
    """
    return {
        "name": "My Plugin",
        "version": "1.0.0",
        "capabilities": ["feature1", "feature2"],
        "author": "Your Name"
    }

def perform_plugin_task():
    """Helper functions for your plugin logic."""
    return "Plugin executed successfully"
```

**plugins/my_plugin/plugin.json:**
```json
{
  "name": "my_plugin",
  "version": "1.0.0",
  "description": "Brief description of what the plugin does",
  "author": "Your Name",
  "entry_point": "main",
  "dependencies": [],
  "requires": {
    "python": ">=3.8"
  }
}
```

## Plugin API

### Required Functions

Every plugin must implement these functions:

#### `initialize()`
Called when the plugin is first loaded. Use for:
- Loading configuration
- Setting up resources
- Initializing state

```python
def initialize():
    """Initialize the plugin."""
    # Load config
    config = load_plugin_config()
    # Setup
    setup_resources()
```

#### `main()`
The main entry point for plugin execution. Should:
- Perform the plugin's primary function
- Return a dictionary with status and results

```python
def main():
    """Main plugin execution."""
    try:
        result = do_work()
        return {"status": "success", "data": result}
    except Exception as e:
        return {"status": "error", "message": str(e)}
```

#### `get_info()`
Returns metadata about the plugin.

```python
def get_info():
    """Return plugin information."""
    return {
        "name": "Plugin Name",
        "version": "1.0.0",
        "capabilities": ["list", "of", "features"]
    }
```

### Optional Functions

Additional functions you might implement:

```python
def cleanup():
    """Called when plugin is unloaded."""
    pass

def configure(settings):
    """Apply configuration to plugin."""
    pass

def health_check():
    """Check if plugin is functioning correctly."""
    return {"healthy": True}
```

## Loading and Managing Plugins

### Using Python API

```python
from plugin_loader import PluginLoader

# Initialize loader
loader = PluginLoader()

# Discover available plugins
available = loader.discover_plugins()
print(f"Available plugins: {available}")

# Load a specific plugin
plugin = loader.load_plugin("my_plugin")
if plugin:
    # Initialize
    plugin.initialize()
    
    # Execute
    result = plugin.main()
    print(f"Result: {result}")
    
    # Get info
    info = plugin.get_info()
    print(f"Plugin info: {info}")

# Load all plugins at once
all_plugins = loader.load_all_plugins()

# Get a previously loaded plugin
plugin = loader.get_plugin("my_plugin")
```

### Using Command Line

```bash
# List available plugins
python plugin_loader.py list

# Load a specific plugin
python plugin_loader.py load --plugin my_plugin

# Get plugin information
python plugin_loader.py info --plugin my_plugin

# Use custom plugin directory
python plugin_loader.py list --plugin-dir /path/to/plugins
```

## External Plugin Integration

### Adding External Repositories

To integrate plugins from external sources (like Mouy-leng/nuna):

```bash
# 1. Add the remote repository
git remote add mouy-leng https://github.com/Mouy-leng/nuna.git

# 2. Fetch the external content
git fetch mouy-leng

# 3. List available remotes
git remote -v
```

### Installing External Plugins

**Option 1: Copy Plugin Files**
```bash
# Copy plugin from external source
cp -r /path/to/external/plugin plugins/external_plugin

# Verify plugin structure
ls -la plugins/external_plugin
```

**Option 2: Symbolic Link**
```bash
# Create symlink to external plugin
ln -s /path/to/external/plugin plugins/external_plugin
```

**Option 3: Git Subtree**
```bash
# Add external plugin as subtree
git subtree add --prefix=plugins/external_plugin \
  https://github.com/user/plugin.git main --squash
```

### Plugin Configuration

Create `plugin_config.json` from the example:

```bash
cp plugin_config.example.json plugin_config.json
```

Edit to enable/configure plugins:

```json
{
  "plugin_directory": "plugins",
  "auto_load": false,
  "enabled_plugins": [
    "example",
    "my_plugin"
  ],
  "plugin_config": {
    "my_plugin": {
      "enabled": true,
      "settings": {
        "api_key": "your-api-key",
        "debug": false
      }
    }
  }
}
```

## Best Practices

### Development Guidelines

1. **Keep Plugins Independent**
   - Plugins should not depend on other plugins
   - Use well-defined interfaces
   - Handle missing dependencies gracefully

2. **Error Handling**
   ```python
   def main():
       try:
           result = risky_operation()
           return {"status": "success", "data": result}
       except ValueError as e:
           return {"status": "error", "type": "validation", "message": str(e)}
       except Exception as e:
           return {"status": "error", "type": "unexpected", "message": str(e)}
   ```

3. **Logging**
   ```python
   import logging
   
   logger = logging.getLogger(__name__)
   
   def main():
       logger.info("Plugin execution started")
       # ... plugin logic
       logger.info("Plugin execution completed")
   ```

4. **Configuration Management**
   ```python
   import json
   from pathlib import Path
   
   def load_config():
       config_file = Path(__file__).parent / "config.json"
       if config_file.exists():
           with open(config_file) as f:
               return json.load(f)
       return {}
   ```

### Security Considerations

1. **Validate Input**: Always validate and sanitize input data
2. **Limit Permissions**: Request only necessary permissions
3. **Secure Storage**: Don't hardcode credentials
4. **Review Code**: Review plugin code before installation
5. **Sandboxing**: Consider running untrusted plugins in containers

### Testing

Create tests for your plugins:

```python
# test_my_plugin.py
import unittest
from plugins.my_plugin import initialize, main, get_info

class TestMyPlugin(unittest.TestCase):
    def test_initialize(self):
        """Test plugin initialization."""
        result = initialize()
        self.assertIsNone(result)
    
    def test_main(self):
        """Test main execution."""
        result = main()
        self.assertEqual(result["status"], "success")
    
    def test_get_info(self):
        """Test plugin info."""
        info = get_info()
        self.assertIn("name", info)
        self.assertIn("version", info)

if __name__ == '__main__':
    unittest.main()
```

### Documentation

Document your plugin thoroughly:

```markdown
# My Plugin

## Description
Brief description of what the plugin does.

## Installation
Installation instructions.

## Configuration
Configuration options and examples.

## Usage
Usage examples and common scenarios.

## API Reference
Detailed API documentation.

## Troubleshooting
Common issues and solutions.
```

## Examples

### Simple Data Processing Plugin

```python
"""Data Processing Plugin"""

import pandas as pd

def initialize():
    print("Data processor initialized")

def main():
    # Process data
    data = {"values": [1, 2, 3, 4, 5]}
    df = pd.DataFrame(data)
    
    result = {
        "mean": df["values"].mean(),
        "sum": df["values"].sum(),
        "count": len(df)
    }
    
    return {"status": "success", "data": result}

def get_info():
    return {
        "name": "Data Processor",
        "version": "1.0.0",
        "capabilities": ["statistics", "processing"]
    }
```

### API Integration Plugin

```python
"""API Integration Plugin"""

import requests

def initialize():
    """Initialize API connection."""
    global api_url, api_key
    api_url = "https://api.example.com"
    api_key = load_api_key()

def main():
    """Fetch data from API."""
    response = requests.get(
        f"{api_url}/data",
        headers={"Authorization": f"Bearer {api_key}"}
    )
    
    if response.status_code == 200:
        return {"status": "success", "data": response.json()}
    else:
        return {"status": "error", "message": f"API returned {response.status_code}"}

def get_info():
    return {
        "name": "API Integrator",
        "version": "1.0.0",
        "capabilities": ["api", "integration"]
    }

def load_api_key():
    """Load API key from secure storage."""
    # Implementation
    pass
```

## Troubleshooting

### Common Issues

**Plugin Not Found**
- Verify plugin directory exists under `plugins/`
- Check that plugin has `__init__.py`
- Ensure directory name doesn't start with underscore

**Import Errors**
- Install required dependencies: `pip install -r requirements.txt`
- Check Python version compatibility
- Verify PYTHONPATH includes plugin directory

**Plugin Fails to Load**
- Check for syntax errors in plugin code
- Review plugin logs for error messages
- Validate plugin.json format

## Additional Resources

- [Plugin README](../plugins/README.md) - Detailed plugin documentation
- [Example Plugin](../plugins/example/) - Working example implementation
- [Plugin Loader Source](../plugin_loader.py) - Loader implementation

## Support

For questions or issues:
1. Check existing documentation
2. Review example plugins
3. Open an issue on GitHub
4. Contact the NUNA team
