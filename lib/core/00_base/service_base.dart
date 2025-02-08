import '../../tools/logging/logger.dart';

abstract class ServicesBase {
  final Map<String, Function> _methodMap = {};

  /// Initialize the service (now asynchronous)
  Future<void> initialize() async {
    Logger().info('${this.runtimeType} initialized.');
  }

  /// Register a method with a name
  void registerServiceMethod(String methodName, Function method) {
    if (_methodMap.containsKey(methodName)) {
      throw Exception('Method $methodName is already registered in ${this.runtimeType}.');
    }
    _methodMap[methodName] = method;
    Logger().info('Registered method $methodName in ${this.runtimeType}.');
  }

  /// Dynamically call a registered method
  dynamic callServiceMethod(String methodName, [dynamic args = const [], Map<String, dynamic>? namedArgs]) {
    if (_methodMap.containsKey(methodName)) {
      final method = _methodMap[methodName]!;
      if (namedArgs != null && namedArgs.isNotEmpty) {
        // Convert String keys to Symbol for named arguments
        final namedSymbols = {for (var key in namedArgs.keys) Symbol(key): namedArgs[key]};
        return Function.apply(method, args is List ? args : [args], namedSymbols);
      }
      return Function.apply(method, args is List ? args : [args]);
    } else {
      throw Exception('Method $methodName not found in ${this.runtimeType}.');
    }
  }

  /// Dispose method to clean up resources
  void dispose() {
    Logger().info('${this.runtimeType} disposed.');
    _methodMap.clear();
  }
}
