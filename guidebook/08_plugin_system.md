# Plugin System Documentation

## Overview
The plugin system allows extending the bridge functionality without modifying core code.

## Navigation
- [Creating Plugins](#creating-plugins)
- [Plugin API](#plugin-api)
- [Loading Plugins](#loading-plugins)

## Creating Plugins
Plugins should be placed in the `plugins/` directory. Each plugin must implement
the base class interface.

## Plugin API
The API provides hooks for data processing and event handling.

## Loading Plugins
Plugins are discovered automatically at startup.
