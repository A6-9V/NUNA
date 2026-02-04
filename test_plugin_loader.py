"""
Unit tests for the NUNA plugin loader
"""

import unittest
import tempfile
import shutil
import json
from pathlib import Path
from plugin_loader import PluginLoader


class TestPluginLoader(unittest.TestCase):
    """Test cases for PluginLoader class."""
    
    def setUp(self):
        """Create a temporary plugin directory for testing."""
        self.test_dir = tempfile.mkdtemp()
        self.plugin_dir = Path(self.test_dir) / "plugins"
        self.plugin_dir.mkdir()
        
    def tearDown(self):
        """Clean up temporary directory."""
        shutil.rmtree(self.test_dir)
    
    def _create_test_plugin(self, name, with_metadata=True, with_init=True):
        """Helper method to create a test plugin."""
        plugin_path = self.plugin_dir / name
        plugin_path.mkdir()
        
        if with_metadata:
            metadata = {
                "name": name,
                "version": "1.0.0",
                "description": f"Test plugin {name}",
                "author": "Test"
            }
            with open(plugin_path / "plugin.json", 'w') as f:
                json.dump(metadata, f)
        
        if with_init:
            init_content = '''
def initialize():
    return "initialized"

def main():
    return {"status": "success"}

def get_info():
    return {"name": "Test Plugin"}
'''
            with open(plugin_path / "__init__.py", 'w') as f:
                f.write(init_content)
    
    def test_discover_plugins_empty(self):
        """Test discovering plugins in an empty directory."""
        loader = PluginLoader(str(self.plugin_dir))
        plugins = loader.discover_plugins()
        self.assertEqual(plugins, [])
    
    def test_discover_plugins_with_plugin(self):
        """Test discovering a single plugin."""
        self._create_test_plugin("test_plugin")
        loader = PluginLoader(str(self.plugin_dir))
        plugins = loader.discover_plugins()
        self.assertIn("test_plugin", plugins)
    
    def test_discover_multiple_plugins(self):
        """Test discovering multiple plugins."""
        self._create_test_plugin("plugin1")
        self._create_test_plugin("plugin2")
        loader = PluginLoader(str(self.plugin_dir))
        plugins = loader.discover_plugins()
        self.assertEqual(len(plugins), 2)
        self.assertIn("plugin1", plugins)
        self.assertIn("plugin2", plugins)
    
    def test_load_plugin_success(self):
        """Test successfully loading a plugin."""
        self._create_test_plugin("test_plugin")
        loader = PluginLoader(str(self.plugin_dir))
        plugin = loader.load_plugin("test_plugin")
        self.assertIsNotNone(plugin)
        self.assertTrue(hasattr(plugin, 'initialize'))
        self.assertTrue(hasattr(plugin, 'main'))
    
    def test_load_plugin_not_found(self):
        """Test loading a non-existent plugin."""
        loader = PluginLoader(str(self.plugin_dir))
        plugin = loader.load_plugin("nonexistent")
        self.assertIsNone(plugin)
    
    def test_load_plugin_without_init(self):
        """Test loading a plugin without __init__.py."""
        self._create_test_plugin("bad_plugin", with_init=False)
        loader = PluginLoader(str(self.plugin_dir))
        plugin = loader.load_plugin("bad_plugin")
        self.assertIsNone(plugin)
    
    def test_load_all_plugins(self):
        """Test loading all plugins."""
        self._create_test_plugin("plugin1")
        self._create_test_plugin("plugin2")
        loader = PluginLoader(str(self.plugin_dir))
        loaded = loader.load_all_plugins()
        self.assertEqual(len(loaded), 2)
        self.assertIn("plugin1", loaded)
        self.assertIn("plugin2", loaded)
    
    def test_get_plugin(self):
        """Test retrieving a loaded plugin."""
        self._create_test_plugin("test_plugin")
        loader = PluginLoader(str(self.plugin_dir))
        loader.load_plugin("test_plugin")
        plugin = loader.get_plugin("test_plugin")
        self.assertIsNotNone(plugin)
    
    def test_get_plugin_not_loaded(self):
        """Test retrieving a plugin that hasn't been loaded."""
        loader = PluginLoader(str(self.plugin_dir))
        plugin = loader.get_plugin("nonexistent")
        self.assertIsNone(plugin)
    
    def test_list_loaded_plugins(self):
        """Test listing loaded plugins."""
        self._create_test_plugin("plugin1")
        self._create_test_plugin("plugin2")
        loader = PluginLoader(str(self.plugin_dir))
        loader.load_plugin("plugin1")
        loaded = loader.list_loaded_plugins()
        self.assertEqual(len(loaded), 1)
        self.assertIn("plugin1", loaded)
    
    def test_plugin_with_metadata(self):
        """Test that plugin metadata is loaded correctly."""
        self._create_test_plugin("test_plugin", with_metadata=True)
        loader = PluginLoader(str(self.plugin_dir))
        loader.load_plugin("test_plugin")
        plugin_info = loader.loaded_plugins["test_plugin"]
        self.assertIn("metadata", plugin_info)
        self.assertEqual(plugin_info["metadata"]["name"], "test_plugin")
    
    def test_plugin_without_metadata(self):
        """Test loading a plugin without metadata."""
        self._create_test_plugin("test_plugin", with_metadata=False)
        loader = PluginLoader(str(self.plugin_dir))
        plugin = loader.load_plugin("test_plugin")
        self.assertIsNotNone(plugin)


if __name__ == '__main__':
    unittest.main()
