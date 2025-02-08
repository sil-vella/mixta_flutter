import 'package:flush_me_im_famous/core/managers/plugin_manager.dart';
import 'package:flutter/material.dart';
import '../../plugins/plugin_registry.dart';
import '../services/shared_preferences.dart';
import 'hooks_manager.dart';
import 'module_manager.dart';
import 'navigation_manager.dart';
import 'services_manager.dart';

class AppManager extends ChangeNotifier {
  static final AppManager _instance = AppManager._internal();

  final NavigationContainer navigationContainer;
  final PluginManager pluginManager;
  final ModuleManager moduleManager;
  final HooksManager hooksManager;
  final ServicesManager servicesManager;

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
        pluginManager = PluginManager(HooksManager()),
        moduleManager = ModuleManager(),
        servicesManager = ServicesManager() {
    servicesManager.autoRegisterAllServices(); // Automatically register and initialize all services
  }

  /// Trigger hooks dynamically
  void triggerHook(String hookName) {
    hooksManager.triggerHook(hookName);
  }

  /// Initializes plugins and services
  Future<void> _initializePlugins() async {

    final plugins = PluginRegistry.getPlugins(pluginManager, navigationContainer);
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
    servicesManager.dispose(); // Dispose services
    notifyListeners();
    debugPrint('App resources disposed successfully.');
  }
}
