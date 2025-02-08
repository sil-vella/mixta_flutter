import 'package:flutter/material.dart';
import '../../tools/logging/logger.dart';

class StateManager with ChangeNotifier {
  static StateManager? _instance;

  final Map<String, dynamic> _pluginStates = {}; // Stores states for plugins
  Map<String, dynamic> _mainAppState = {'main_state': 'idle'}; // Default main app state

  StateManager._internal() {
    Logger().info('StateManager instance created.');
  }

  /// Factory method to provide the singleton instance
  factory StateManager() {
    if (_instance == null) {
      Logger().info('Initializing StateManager for the first time.');
      _instance = StateManager._internal();
    } else {
      Logger().info('StateManager instance already exists.');
    }
    return _instance!;
  }

  // ------ Plugin State Methods ------

  bool isPluginStateRegistered(String pluginKey) {
    return _pluginStates.containsKey(pluginKey);
  }

  void registerPluginState(String pluginKey, dynamic initialState) {
    if (!_pluginStates.containsKey(pluginKey)) {
      _pluginStates[pluginKey] = initialState;
      Logger().info("Registered state for key: $pluginKey");
      notifyListeners();
    }
  }

  void unregisterPluginState(String pluginKey) {
    if (_pluginStates.containsKey(pluginKey)) {
      _pluginStates.remove(pluginKey);
      Logger().info("Unregistered state for key: $pluginKey");
      notifyListeners();
    }
  }

  T? getPluginState<T>(String pluginKey) {
    return _pluginStates[pluginKey] as T?;
  }

  void updatePluginState(String pluginKey, Map<String, dynamic> newState) {
    if (_pluginStates.containsKey(pluginKey)) {
      _pluginStates[pluginKey] = {
        ..._pluginStates[pluginKey],
        ...newState,
      };
      Logger().info("Updated state for $pluginKey: ${_pluginStates[pluginKey]}");
    } else {
      _pluginStates[pluginKey] = newState;
      Logger().info("Created new state for $pluginKey: ${_pluginStates[pluginKey]}");
    }
    notifyListeners();
  }

  // ------ Main App State Methods ------

  void setMainAppState(Map<String, dynamic> initialState) {
    _mainAppState = {'main_state': 'idle', ...initialState};
    Logger().info("Main app state initialized: $_mainAppState");
    notifyListeners();
  }

  Map<String, dynamic> get mainAppState => _mainAppState;

  void updateMainAppState(String key, dynamic value) {
    _mainAppState[key] = value;
    Logger().info("Main app state updated: key=$key, value=$value");
    notifyListeners();
  }

  T? getMainAppState<T>(String key) {
    return _mainAppState[key] as T?;
  }
}
