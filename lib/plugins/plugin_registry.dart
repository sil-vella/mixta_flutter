import 'package:guess_the_celebrity/core/managers/state_manager.dart';
import 'package:guess_the_celebrity/plugins/adverts_plugin/adverts_plugin_main.dart';
import 'package:guess_the_celebrity/plugins/game_plugin/game_plugin_main.dart';
import 'package:guess_the_celebrity/plugins/game_plugin/screens/game_screen/game_screen.dart';
import 'package:guess_the_celebrity/plugins/main_plugin/main_plugin_main.dart';
import '../tools/logging/logger.dart';
import '../core/managers/plugin_manager.dart';
import '../core/managers/navigation_manager.dart';

class PluginRegistry {
  static final Map<String, dynamic> _pluginInstances = {};

  static Map<String, dynamic> getPlugins(
      PluginManager pluginManager,
      NavigationContainer navigationContainer,
      ) {
    if (_pluginInstances.isEmpty) {
      _pluginInstances.addAll({
        // Register plugins here
        'main_plugin': MainPlugin(
          pluginManager.hooksManager,
          pluginManager.moduleManager,
          navigationContainer,
        ),
        'game_plugin': GamePlugin(
          pluginManager.hooksManager,
          pluginManager.moduleManager,
          navigationContainer,
        ),
        'adverts_plugin': AdvertsPlugin(
          pluginManager.hooksManager,
          pluginManager.moduleManager,
          navigationContainer,
        ),
      });

      // Automatically register plugin states
      _registerPluginStates();

      Logger().info('Plugins registered in PluginRegistry: ${_pluginInstances.keys}');
    } else {
      Logger().info('Plugins already registered. Skipping re-registration.');
    }

    return _pluginInstances;
  }

  /// Automatically register plugin states using StateManager
  static void _registerPluginStates() {
    final stateManager = StateManager(); // Access singleton instance

    for (var entry in _pluginInstances.entries) {
      final pluginKey = entry.value.runtimeType.toString(); // Use runtime type as key
      final plugin = entry.value;

      if (!stateManager.isPluginStateRegistered(pluginKey)) {
        final initialState = (plugin as dynamic).getInitialState();
        stateManager.registerPluginState(pluginKey, initialState);
        Logger().info('Plugin state registered for: $pluginKey');
      }
    }
  }
}
