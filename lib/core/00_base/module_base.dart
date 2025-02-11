import '../../tools/logging/logger.dart';

abstract class ModuleBase {
  final Map<String, Function> _methodMap = {};

  /// Initialize the module
  void initialize() {
    Logger().info('${this.runtimeType} initialized.');
  }

  /// Register a method with a name
  void registerMethod(String methodName, Function method) {
    _methodMap[methodName] = method;
  }

  /// Dynamically calls a registered method with support for any kind of args
  dynamic callMethod(String methodName, [dynamic args, Map<String, dynamic>? namedArgs]) {
    if (_methodMap.containsKey(methodName)) {
      final method = _methodMap[methodName]!;

      // Ensure args is always a List
      final List<dynamic> positionalArgs = (args is List) ? args : (args != null ? [args] : []);

      return Function.apply(method, positionalArgs, namedArgs?.map((key, value) => MapEntry(Symbol(key), value)));
    } else {
      throw Exception('Method "$methodName" not found in ${this.runtimeType}.');
    }
  }



  /// Dispose method to clean up resources
  void dispose() {
    Logger().info('${this.runtimeType} disposed.');
  }
}
