import '../../tools/logging/logger.dart';
import '../00_base/module_base.dart';

class ModuleManager {
  // Singleton instance
  static final ModuleManager _instance = ModuleManager._internal();

  // Factory constructor to return the same instance
  factory ModuleManager() => _instance;

  // Internal constructor for singleton
  ModuleManager._internal();

  // Module storage
  final Map<String, ModuleBase> _modules = {};

  /// Register a module
  void registerModule(String moduleKey, ModuleBase module) {
    if (_modules.containsKey(moduleKey)) {
      throw Exception('Module with key "$moduleKey" is already registered.');
    }

    _modules[moduleKey] = module;
    Logger().info('Module registered: $moduleKey');
  }

  /// Deregister a module
  void deregisterModule(String moduleKey) {
    final module = _modules.remove(moduleKey);
    if (module != null) {
      module.dispose();
      Logger().info('Module deregistered and disposed: $moduleKey');
    }
  }

  /// Get a module
  T? getModule<T extends ModuleBase>(String moduleKey) {
    Logger().info('Fetching module: $moduleKey');
    return _modules[moduleKey] as T?;
  }

  /// Dispose all modules
  void dispose() {
    Logger().info('Disposing all modules.');
    for (var entry in _modules.entries) {
      entry.value.dispose();
      Logger().info('Disposed module: ${entry.key}');
    }
    _modules.clear();
    Logger().info('All modules have been disposed.');
  }
}
