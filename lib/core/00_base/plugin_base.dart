import '../managers/module_manager.dart';
import '../managers/hooks_manager.dart';
import '../managers/state_manager.dart';
import '../../tools/logging/logger.dart';

abstract class PluginBase {
  final HooksManager hooksManager;
  final ModuleManager moduleManager;

  /// Map for modules
  final Map<String, Function> moduleMap = {};

  /// Map for hooks
  final Map<String, HookCallback> hookMap = {};

  PluginBase(this.hooksManager, this.moduleManager);

  /// Initialize the plugin (registers modules, hooks, and states)
  void initialize(StateManager stateManager) {
    registerModules();
    registerHooks();
    registerStates(stateManager); // ✅ Register states
  }

  /// Register hooks dynamically from the hookMap
  void registerHooks() {
    hookMap.forEach((hookName, callback) {
      hooksManager.registerHook(hookName, callback);
    });
  }

  /// Register modules dynamically from the moduleMap
  void registerModules() {
    moduleMap.forEach((moduleKey, createModule) {
      final module = createModule();
      moduleManager.registerModule(moduleKey, module);
    });
  }

  /// ✅ Each plugin must override this to define its states
  Map<String, Map<String, dynamic>> getInitialStates();

  /// ✅ Registers the plugin states using StateManager
  void registerStates(StateManager stateManager) {
    for (var entry in getInitialStates().entries) {
      final stateKey = entry.key;
      final stateData = entry.value;

      if (!stateManager.isPluginStateRegistered(stateKey)) {
        stateManager.registerPluginState(stateKey, stateData);
        Logger().info("✅ Registered plugin state: $stateKey");
      }
    }
  }

  /// Dispose the plugin (removes modules and hooks)
  void dispose() {
    moduleMap.keys.forEach(moduleManager.deregisterModule);
    hookMap.keys.forEach(hooksManager.deregisterHook);
  }
}
