import '../../tools/logging/logger.dart';
import '../00_base/plugin_base.dart';
import 'hooks_manager.dart';
import 'module_manager.dart';

class PluginManager {
  final HooksManager hooksManager;
  final ModuleManager moduleManager = ModuleManager();

  final Map<String, dynamic> _plugins = {};
  final Map<String, dynamic> _pluginStates = {};

  PluginManager(this.hooksManager);

  /// Register and initialize a plugin
  void registerPlugin(String pluginKey, PluginBase plugin) {
    if (_plugins.containsKey(pluginKey)) {
      Logger().info('Plugin with key "$pluginKey" is already registered. Skipping initialization.');
      return; // Prevent duplicate registration
    }

    _plugins[pluginKey] = plugin;
    Logger().info('Initializing plugin: $pluginKey');
    plugin.initialize();
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

  /// Update plugin state
  void updatePluginState(String pluginKey, dynamic newState) {
    if (_pluginStates.containsKey(pluginKey)) {
      _pluginStates[pluginKey] = newState;
      Logger().info('Plugin state updated for $pluginKey.');
    }
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
