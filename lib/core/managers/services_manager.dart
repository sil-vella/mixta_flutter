import '../../tools/logging/logger.dart';
import '../00_base/service_base.dart';
import '../services/shared_preferences.dart'; // Import your services here

class ServicesManager {
  static final ServicesManager _instance = ServicesManager._internal();

  factory ServicesManager() => _instance;

  ServicesManager._internal();

  final Map<String, ServicesBase> _services = {};

  /// List of all services with keys
  static final List<MapEntry<String, ServicesBase>> _allServices = [
    MapEntry('shared_pref', SharedPrefManager()), // Add your services with keys
    // MapEntry('another_service', AnotherService()),
  ];

  /// Automatically register and initialize all services
  void autoRegisterAllServices() {
    for (var entry in _allServices) {
      final serviceKey = entry.key;
      final service = entry.value;
      if (!_services.containsKey(serviceKey)) {
        _services[serviceKey] = service;
        service.initialize();
        Logger().info('Service registered and initialized: $serviceKey');
      }
    }
  }

  /// Fetch a service by key
  T? getService<T extends ServicesBase>(String serviceKey) {
    Logger().info('Fetching service: $serviceKey');
    return _services[serviceKey] as T?;
  }

  /// Check if a service is already registered
  bool isServiceRegistered(String serviceKey) {
    return _services.containsKey(serviceKey);
  }

  /// Deregister a service
  void deregisterService(String serviceKey) {
    final service = _services.remove(serviceKey);
    if (service != null) {
      service.dispose();
      Logger().info('Service deregistered and disposed: $serviceKey');
    }
  }

  /// Dispose all services
  void dispose() {
    Logger().info('Disposing all services.');
    for (var entry in _services.entries) {
      entry.value.dispose();
      Logger().info('Disposed service: ${entry.key}');
    }
    _services.clear();
    Logger().info('All services have been disposed.');
  }
}
