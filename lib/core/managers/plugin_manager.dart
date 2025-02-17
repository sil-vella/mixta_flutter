import '../../tools/logging/logger.dart';
import '../00_base/plugin_base.dart';
import 'hooks_manager.dart';
import 'module_manager.dart';
import 'state_manager.dart'; // ✅ Import StateManager

class PluginManager {
  final HooksManager hooksManager;
  final ModuleManager moduleManager = ModuleManager();
  final StateManager stateManager; // ✅ Pass StateManager

  final Map<String, dynamic> _plugins = {};
  final Map<String, dynamic> _pluginStates = {};

  PluginManager(this.hooksManager, this.stateManager); // ✅ Require StateManager

  /// Register and initialize a plugin
  void registerPlugin(String pluginKey, PluginBase plugin) {
    if (_plugins.containsKey(pluginKey)) {
      Logger().info('Plugin with key "$pluginKey" is already registered. Skipping initialization.');
      return; // Prevent duplicate registration
    }

    _plugins[pluginKey] = plugin;
    Logger().info('Initializing plugin: $pluginKey');
    plugin.initialize(stateManager); // ✅ Pass StateManager here
    Logger().info('Plugin initialized: $pluginKey');
  }

  /// Deregister a plugin
  void deregisterPlugin(String pluginKey) {
    final plugin = _plugins.remove(pluginKey);
    if (plugin != null) {
      plugin.dispose();
      Logger().info('Plugin deregistered: $pluginKey');
    }
    _pluginStates.remove(pluginKey);
  }

  /// Get a plugin
  T? getPlugin<T>(String pluginKey) {
    return _plugins[pluginKey] as T?;
  }

  /// Get plugin state
  T? getPluginState<T>(String pluginKey) {
    return _pluginStates[pluginKey] as T?;
  }



  /// Clear all plugins
  void clearPlugins() {
    _plugins.clear();
    _pluginStates.clear();
    Logger().info('All plugins and their states have been cleared.');
  }

  /// Dispose all plugins
  void dispose() {
    Logger().info('Disposing all plugins.');
    for (final plugin in _plugins.values) {
      if (plugin is PluginBase) {
        plugin.dispose();
        Logger().info('Disposed plugin: ${plugin.runtimeType}');
      }
    }
    clearPlugins(); // Clear the plugins and their states
    Logger().info('All plugins disposed and cleared.');
  }
}
