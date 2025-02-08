import '../../tools/logging/logger.dart';

typedef HookCallback = void Function();

class HooksManager {
  static final HooksManager _instance = HooksManager._internal();

  factory HooksManager() => _instance;

  HooksManager._internal();

  // Map of hooks with a list of (priority, callback) pairs
  final Map<String, List<MapEntry<int, HookCallback>>> _hooks = {};

  /// Register a hook callback with an optional priority (default: 10)
  void registerHook(String hookName, HookCallback callback, {int priority = 10}) {
    Logger().info('Registering hook: $hookName with priority $priority');
    _hooks.putIfAbsent(hookName, () => []).add(MapEntry(priority, callback));
    _hooks[hookName]!.sort((a, b) => a.key.compareTo(b.key)); // Sort by priority
    Logger().info('Current hooks: $hookName - ${_hooks[hookName]}'); // Log hooks to verify registration
  }

  /// Trigger a hook by name, executing all its callbacks in priority order
  void triggerHook(String hookName) {
    if (_hooks.containsKey(hookName)) {
      Logger().info('Triggering hook: $hookName with ${_hooks[hookName]!.length} callbacks');
      for (final entry in _hooks[hookName]!) {
        Logger().info('Executing callback for hook: $hookName with priority ${entry.key}');
        entry.value(); // Execute the callback
      }
    } else {
      Logger().info('No callbacks registered for hook: $hookName');
    }
  }

  /// Deregister all hooks for a specific event
  void deregisterHook(String hookName) {
    _hooks.remove(hookName);
    Logger().info('Deregistered all callbacks for hook: $hookName');
  }

  /// Deregister a specific callback from a hook
  void deregisterCallback(String hookName, HookCallback callback) {
    _hooks[hookName]?.removeWhere((entry) => entry.value == callback);
    if (_hooks[hookName]?.isEmpty ?? true) {
      _hooks.remove(hookName);
    }
    Logger().info('Deregistered a callback for hook: $hookName');
  }
}
