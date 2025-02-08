import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../tools/logging/logger.dart';
import '../00_base/service_base.dart';
import '../managers/services_manager.dart'; // Import ServicesManager

class SharedPrefManager extends ServicesBase {
  static final SharedPrefManager _instance = SharedPrefManager._internal();
  SharedPreferences? _prefs;

  SharedPrefManager._internal();

  factory SharedPrefManager() => _instance;

  @override
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    Logger().info('SharedPreferences initialized.');

    // Register methods to ServicesBase
    registerServiceMethod('setString', setString);
    registerServiceMethod('setInt', setInt);
    registerServiceMethod('setBool', setBool);
    registerServiceMethod('setDouble', setDouble);

    registerServiceMethod('getString', getString);
    registerServiceMethod('getInt', getInt);
    registerServiceMethod('getBool', getBool);
    registerServiceMethod('getDouble', getDouble);

    registerServiceMethod('remove', remove);
    registerServiceMethod('clear', clear);
  }

  // Override to provide the service instance
  static List<ServicesBase> getAllServices() {
    return [_instance];
  }

  // ------ Setter Methods ------
  Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
    Logger().info('Set String: $key = $value');
  }

  Future<void> setInt(String key, int value) async {
    await _prefs?.setInt(key, value);
    Logger().info('Set Int: $key = $value');
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
    Logger().info('Set Bool: $key = $value');
  }

  Future<void> setDouble(String key, double value) async {
    await _prefs?.setDouble(key, value);
    Logger().info('Set Double: $key = $value');
  }

  // ------ Getter Methods ------
  String? getString(String key) => _prefs?.getString(key);
  int? getInt(String key) => _prefs?.getInt(key);
  bool? getBool(String key) => _prefs?.getBool(key);
  double? getDouble(String key) => _prefs?.getDouble(key);

  // ------ Utility Methods ------
  Future<void> remove(String key) async {
    await _prefs?.remove(key);
    Logger().info('Removed key: $key');
  }

  Future<void> clear() async {
    await _prefs?.clear();
    Logger().info('Cleared all preferences');
  }

  @override
  void dispose() {
    super.dispose();
    Logger().info('SharedPrefManager disposed.');
  }
}
