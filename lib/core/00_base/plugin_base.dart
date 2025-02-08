import '../managers/module_manager.dart';
import '../managers/hooks_manager.dart';

abstract class PluginBase {
  final HooksManager hooksManager;
  final ModuleManager moduleManager;

  /// Map for modules
  final Map<String, Function> moduleMap = {};

  /// Map for hooks
  final Map<String, HookCallback> hookMap = {}; // Add hookMap

  PluginBase(this.hooksManager, this.moduleManager);


  /// Initialize the plugin
  void initialize() {
    registerModules();
    registerHooks(); // Ensure hooks are registered
  }

  /// Register hooks dynamically from the hookMap
  void registerHooks() {
    hookMap.forEach((hookName, callback) {
      hooksManager.registerHook(hookName, callback); // Register hooks
    });
  }

  /// Register modules dynamically from the moduleMap
  void registerModules() {
    moduleMap.forEach((moduleKey, createModule) {
      final module = createModule();
      moduleManager.registerModule(moduleKey, module);
    });
  }

  /// Override to provide initial state for plugin (used by PluginRegistry)
  dynamic getInitialState() => {};


  /// Dispose the plugin
  void dispose() {
    // Deregister modules
    moduleMap.keys.forEach(moduleManager.deregisterModule);
    // Deregister hooks
    hookMap.keys.forEach(hooksManager.deregisterHook);

  }
}
