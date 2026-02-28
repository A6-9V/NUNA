# NUNA Plugin System

The NUNA plugin system allows you to extend the functionality of NUNA with
custom modules and integrations.

## Overview

Plugins are self-contained modules that can add new features, integrations, or
functionality to NUNA. Each plugin resides in its own directory under the
`plugins/` folder.

## Plugin Structure

A plugin should have the following structure:

```bash
plugins/
  └── my_plugin/
      ├── plugin.json       # Plugin metadata (optional but recommended)
      ├── **init**.py       # Main plugin code
      └── README.md         # Plugin documentation (optional)
```bash

### Plugin Metadata (plugin.json)

The `plugin.json` file contains metadata about your plugin:

```json
{
  "name": "my_plugin",
  "version": "1.0.0",
  "description": "Description of what the plugin does",
  "author": "Your Name",
  "entry_point": "main"
}
```bash

### Plugin Code (**init**.py)

The `**init**.py` file contains your plugin's code. At minimum, it should
define:

- `initialize()` - Called when the plugin is loaded
- `main()` - The main entry point for the plugin
- `get_info()` - Returns information about the plugin

Example:

```python
def initialize():
    """Initialize the plugin."""
    print("My plugin initialized")

def main():
    """Main entry point for the plugin."""
    # Your plugin logic here
    return {"status": "success"}

def get_info():
    """Return plugin information."""
    return {
        "name": "My Plugin",
        "version": "1.0.0",
        "capabilities": ["feature1", "feature2"]
    }
```bash

## Using the Plugin Loader

### Python API

```python
from plugin_loader import PluginLoader

# Create a loader instance
loader = PluginLoader()

# Discover available plugins
plugins = loader.discover_plugins()
print(f"Found plugins: {plugins}")

# Load a specific plugin
plugin = loader.load_plugin("my_plugin")
if plugin:
    plugin.initialize()
    result = plugin.main()

# Load all plugins
loader.load_all_plugins()

# Get a loaded plugin
plugin = loader.get_plugin("my_plugin")
```bash

### Command Line Interface

```bash
# List available plugins
python plugin_loader.py list

# Load a specific plugin
python plugin_loader.py load --plugin my_plugin

# Get plugin information
python plugin_loader.py info --plugin my_plugin
```bash

## External Plugin Integration

To integrate external plugins (e.g., from the Mouy-leng/nuna repository):

1. **Add the remote repository:**

```bash
git remote add mouy-leng https://github.com/Mouy-leng/nuna.git
```bash

2. **Fetch the external plugins:**

```bash
git fetch mouy-leng
```bash

3. **Copy/link the plugin to your plugins directory:**

```bash
   # Option 1: Copy the plugin
cp -r /path/to/external/plugin plugins/

   # Option 2: Create a symbolic link
ln -s /path/to/external/plugin plugins/
```bash

4. **Load the plugin:**

```python
from plugin_loader import PluginLoader
loader = PluginLoader()
plugin = loader.load_plugin("external_plugin_name")
```bash

## Example Plugin

See the `plugins/example/` directory for a complete example plugin
implementation.

## Best Practices

1. **Keep plugins independent**: Plugins should not depend on other plugins
2. **Handle errors gracefully**: Use try-except blocks in your plugin code
3. **Document your plugin**: Include a README.md with usage instructions
4. **Version your plugins**: Use semantic versioning in plugin.json
5. **Test your plugins**: Write tests for your plugin functionality

## Security Considerations

- Only load plugins from trusted sources
- Review plugin code before loading
- Plugins have access to the same permissions as the main application
- Use virtual environments for plugin development

## Troubleshooting

### Plugin Not Found

If a plugin is not discovered:

- Check that the plugin directory exists under `plugins/`
- Ensure the plugin has an `**init**.py` file
- Verify the directory name doesn't start with underscore

### Plugin Load Errors

If a plugin fails to load:

- Check for syntax errors in the plugin code
- Verify all required dependencies are installed
- Review the error message for specific issues

## Contributing Plugins

To contribute a plugin to NUNA:

1. Create your plugin in the `plugins/` directory
2. Include complete documentation
3. Add tests if applicable
4. Submit a pull request

For questions or issues, please open an issue on the GitHub repository.
