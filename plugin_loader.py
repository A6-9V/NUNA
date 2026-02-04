"""
Plugin Loader for NUNA

This module provides functionality to load and manage external plugins
for the NUNA system.
"""

import os
import sys
import importlib.util
import json
from pathlib import Path
from typing import Dict, List, Any, Optional


class PluginLoader:
    """Manages loading and execution of NUNA plugins."""
    
    def __init__(self, plugin_dir: str = "plugins"):
        """
        Initialize the plugin loader.
        
        Args:
            plugin_dir: Directory containing plugins (default: "plugins")
        """
        self.plugin_dir = Path(plugin_dir)
        self.loaded_plugins: Dict[str, Any] = {}
        
    def discover_plugins(self) -> List[str]:
        """
        Discover available plugins in the plugin directory.
        
        Returns:
            List of plugin names
        """
        if not self.plugin_dir.exists():
            return []
            
        plugins = []
        for item in self.plugin_dir.iterdir():
            if item.is_dir() and not item.name.startswith('_'):
                # Check for plugin.json or __init__.py
                if (item / "plugin.json").exists() or (item / "__init__.py").exists():
                    plugins.append(item.name)
        return plugins
    
    def load_plugin(self, plugin_name: str) -> Optional[Any]:
        """
        Load a specific plugin.
        
        Args:
            plugin_name: Name of the plugin to load
            
        Returns:
            The loaded plugin module or None if loading failed
        """
        plugin_path = self.plugin_dir / plugin_name
        
        if not plugin_path.exists():
            print(f"Plugin '{plugin_name}' not found at {plugin_path}")
            return None
            
        # Try to load plugin metadata
        metadata_file = plugin_path / "plugin.json"
        metadata = {}
        if metadata_file.exists():
            with open(metadata_file, 'r') as f:
                metadata = json.load(f)
                
        # Load the plugin module
        init_file = plugin_path / "__init__.py"
        if init_file.exists():
            spec = importlib.util.spec_from_file_location(
                f"plugins.{plugin_name}",
                init_file
            )
            if spec and spec.loader:
                module = importlib.util.module_from_spec(spec)
                sys.modules[spec.name] = module
                spec.loader.exec_module(module)
                
                # Store plugin with metadata
                self.loaded_plugins[plugin_name] = {
                    'module': module,
                    'metadata': metadata,
                    'path': str(plugin_path)
                }
                
                print(f"✓ Loaded plugin: {plugin_name}")
                if metadata.get('description'):
                    print(f"  Description: {metadata['description']}")
                    
                return module
        
        print(f"Plugin '{plugin_name}' missing __init__.py")
        return None
    
    def load_all_plugins(self) -> Dict[str, Any]:
        """
        Load all discovered plugins.
        
        Returns:
            Dictionary of loaded plugins
        """
        plugins = self.discover_plugins()
        for plugin_name in plugins:
            self.load_plugin(plugin_name)
        return self.loaded_plugins
    
    def get_plugin(self, plugin_name: str) -> Optional[Any]:
        """
        Get a loaded plugin by name.
        
        Args:
            plugin_name: Name of the plugin
            
        Returns:
            The plugin module or None if not loaded
        """
        plugin_info = self.loaded_plugins.get(plugin_name)
        return plugin_info['module'] if plugin_info else None
    
    def list_loaded_plugins(self) -> List[str]:
        """
        Get list of currently loaded plugins.
        
        Returns:
            List of loaded plugin names
        """
        return list(self.loaded_plugins.keys())


def main():
    """CLI interface for plugin management."""
    import argparse
    
    parser = argparse.ArgumentParser(description='NUNA Plugin Loader')
    parser.add_argument('action', choices=['list', 'load', 'info'],
                       help='Action to perform')
    parser.add_argument('--plugin', help='Plugin name (for load/info actions)')
    parser.add_argument('--plugin-dir', default='plugins',
                       help='Plugin directory (default: plugins)')
    
    args = parser.parse_args()
    
    loader = PluginLoader(args.plugin_dir)
    
    if args.action == 'list':
        print("Available plugins:")
        plugins = loader.discover_plugins()
        if plugins:
            for plugin in plugins:
                print(f"  - {plugin}")
        else:
            print("  No plugins found")
            
    elif args.action == 'load':
        if not args.plugin:
            print("Error: --plugin required for load action")
            return 1
        loader.load_plugin(args.plugin)
        
    elif args.action == 'info':
        if not args.plugin:
            print("Error: --plugin required for info action")
            return 1
            
        plugin_path = Path(args.plugin_dir) / args.plugin
        metadata_file = plugin_path / "plugin.json"
        
        if metadata_file.exists():
            with open(metadata_file, 'r') as f:
                metadata = json.load(f)
            print(f"Plugin: {args.plugin}")
            for key, value in metadata.items():
                print(f"  {key}: {value}")
        else:
            print(f"No metadata found for plugin '{args.plugin}'")
    
    return 0


if __name__ == '__main__':
    sys.exit(main())
