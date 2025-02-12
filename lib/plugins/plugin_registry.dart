import 'package:mixta_guess_who/core/managers/state_manager.dart';
import 'package:mixta_guess_who/plugins/adverts_plugin/adverts_plugin_main.dart';
import 'package:mixta_guess_who/plugins/game_plugin/game_plugin_main.dart';
import 'package:mixta_guess_who/plugins/main_plugin/main_plugin_main.dart';
import '../core/00_base/plugin_base.dart';
import '../tools/logging/logger.dart';
import '../core/managers/plugin_manager.dart';
import '../core/managers/navigation_manager.dart';

class PluginRegistry {
  static final Map<String, PluginBase> _pluginInstances = {};

  static Map<String, PluginBase> getPlugins(
      PluginManager pluginManager,
      NavigationContainer navigationContainer,
      StateManager stateManager) {

    if (_pluginInstances.isEmpty) {
      _pluginInstances.addAll({
        'main_plugin': MainPlugin(
          pluginManager.hooksManager,
          pluginManager.moduleManager,
          navigationContainer,
          stateManager, // ✅ Pass StateManager
        ),
        'game_plugin': GamePlugin(
          pluginManager.hooksManager,
          pluginManager.moduleManager,
          navigationContainer,
          stateManager, // ✅ Pass StateManager
        ),
        'adverts_plugin': AdvertsPlugin(
          pluginManager.hooksManager,
          pluginManager.moduleManager,
          navigationContainer,
          stateManager, // ✅ Pass StateManager
        ),
      });

      // ✅ Auto-register all plugin states
      _registerPluginStates(stateManager);

      Logger().info('✅ Plugins registered: ${_pluginInstances.keys}');
    }

    return _pluginInstances;
  }

  /// ✅ Register all plugin states automatically
  static void _registerPluginStates(StateManager stateManager) {
    for (var plugin in _pluginInstances.values) {
      plugin.registerStates(stateManager);
    }
  }
}
