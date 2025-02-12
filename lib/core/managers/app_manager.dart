import 'package:mixta_guess_who/core/managers/plugin_manager.dart';
import 'package:flutter/material.dart';
import '../../plugins/plugin_registry.dart';
import '../services/shared_preferences.dart';
import 'hooks_manager.dart';
import 'module_manager.dart';
import 'navigation_manager.dart';
import 'services_manager.dart';
import 'state_manager.dart'; // ✅ Import StateManager

class AppManager extends ChangeNotifier {
  static final AppManager _instance = AppManager._internal();

  static late BuildContext globalContext;

  final NavigationContainer navigationContainer;
  final PluginManager pluginManager;
  final ModuleManager moduleManager;
  final HooksManager hooksManager;
  final ServicesManager servicesManager;
  final StateManager stateManager; // ✅ Add StateManager instance

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  factory AppManager() {
    if (!_instance._isInitialized) {
      _instance._initializePlugins();
    }
    return _instance;
  }

  AppManager._internal()
      : navigationContainer = NavigationContainer(),
        hooksManager = HooksManager(),
        stateManager = StateManager(), // ✅ Initialize StateManager first
        pluginManager = PluginManager(HooksManager(), StateManager()), // ✅ Pass StateManager
        moduleManager = ModuleManager(),
        servicesManager = ServicesManager() {
    servicesManager.autoRegisterAllServices();
  }

  /// Trigger hooks dynamically
  void triggerHook(String hookName) {
    hooksManager.triggerHook(hookName);
  }

  /// Initializes plugins and services
  Future<void> _initializePlugins() async {
    final plugins = PluginRegistry.getPlugins(pluginManager, navigationContainer, stateManager); // ✅ Pass StateManager
    for (var entry in plugins.entries) {
      pluginManager.registerPlugin(entry.key, entry.value);
    }

    hooksManager.triggerHook('app_startup');
    hooksManager.triggerHook('reg_nav');
    _isInitialized = true;
    notifyListeners();
  }

  /// Cleans up app resources
  void _disposeApp() {
    moduleManager.dispose();
    pluginManager.dispose();
    servicesManager.dispose();
    notifyListeners();
    debugPrint('App resources disposed successfully.');
  }
}
