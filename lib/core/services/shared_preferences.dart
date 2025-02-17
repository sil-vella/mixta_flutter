import 'dart:convert'; // ✅ Import for JSON encoding/decoding
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
    Logger().info('✅ SharedPreferences initialized.');

    // ✅ Register Setter Methods
    registerServiceMethod('setString', setString);
    registerServiceMethod('setInt', setInt);
    registerServiceMethod('setBool', setBool);
    registerServiceMethod('setDouble', setDouble);
    registerServiceMethod('setStringList', setStringList);

    // ✅ Register Getter Methods
    registerServiceMethod('getString', getString);
    registerServiceMethod('getInt', getInt);
    registerServiceMethod('getBool', getBool);
    registerServiceMethod('getDouble', getDouble);
    registerServiceMethod('getStringList', getStringList);

    // ✅ Register Removal Methods
    registerServiceMethod('remove', remove);
    registerServiceMethod('clear', clear);

    // ✅ Register Create Methods (Optional Pre-checks Before Setting)
    registerServiceMethod('createString', createString);
    registerServiceMethod('createInt', createInt);
    registerServiceMethod('createBool', createBool);
    registerServiceMethod('createDouble', createDouble);
    registerServiceMethod('createStringList', createStringList);

    // ✅ Log all SharedPreferences data at startup
    _logAllSharedPreferences();
  }

  /// ✅ Logs all stored SharedPreferences data at startup
  void _logAllSharedPreferences() {
    final allKeys = _prefs?.getKeys() ?? {};

    if (allKeys.isEmpty) {
      Logger().info("⚠️ SharedPreferences is empty.");
      return;
    }

    Logger().info("📜 SharedPreferences Data Dump:");
    for (String key in allKeys) {
      final value = _prefs?.get(key);
      if (value is String && _isJson(value)) {
        Logger().info("📌 $key: ${jsonDecode(value)} (List<String>)");
      } else {
        Logger().info("📌 $key: $value");
      }
    }
  }

  /// ✅ Helper to check if a string is valid JSON (for lists stored as JSON strings)
  bool _isJson(String str) {
    try {
      jsonDecode(str);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ------------------- CREATE METHODS (Only Set If Key Doesn't Exist) -------------------

  Future<void> createString(String key, String value) async {
    if (_prefs?.containsKey(key) == true) {
      Logger().info('⚠️ Skipped creating String: $key already exists with value ${_prefs?.getString(key)}');
      return;
    }
    await setString(key, value);
  }

  Future<void> createInt(String key, int value) async {
    if (_prefs?.containsKey(key) == true) {
      Logger().info('⚠️ Skipped creating Int: $key already exists with value ${_prefs?.getInt(key)}');
      return;
    }
    await setInt(key, value);
  }

  Future<void> createBool(String key, bool value) async {
    if (_prefs?.containsKey(key) == true) {
      Logger().info('⚠️ Skipped creating Bool: $key already exists with value ${_prefs?.getBool(key)}');
      return;
    }
    await setBool(key, value);
  }

  Future<void> createDouble(String key, double value) async {
    if (_prefs?.containsKey(key) == true) {
      Logger().info('⚠️ Skipped creating Double: $key already exists with value ${_prefs?.getDouble(key)}');
      return;
    }
    await setDouble(key, value);
  }

  Future<void> createStringList(String key, List<String> value) async {
    if (_prefs?.containsKey(key) == true) {
      Logger().info('⚠️ Skipped creating String List: $key already exists with value ${getStringList(key)}');
      return;
    }
    await setStringList(key, value);
  }

  // ------------------- SETTER METHODS (Always Set the Value) -------------------

  Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
    Logger().info('✅ Set String: $key = $value');
  }

  Future<void> setInt(String key, int value) async {
    await _prefs?.setInt(key, value);
    Logger().info('✅ Set Int: $key = $value');
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
    Logger().info('✅ Set Bool: $key = $value');
  }

  Future<void> setDouble(String key, double value) async {
    await _prefs?.setDouble(key, value);
    Logger().info('✅ Set Double: $key = $value');
  }

  /// ✅ Store list as JSON string
  Future<void> setStringList(String key, List<String> value) async {
    await _prefs?.setString(key, jsonEncode(value));
    Logger().info('✅ Set String List: $key = $value');
  }

  // ------------------- GETTER METHODS -------------------

  String? getString(String key) => _prefs?.getString(key);
  int? getInt(String key) => _prefs?.getInt(key);
  bool? getBool(String key) => _prefs?.getBool(key);
  double? getDouble(String key) => _prefs?.getDouble(key);

  /// ✅ Retrieve list by decoding JSON string
  List<String> getStringList(String key) {
    String? jsonString = _prefs?.getString(key);
    if (jsonString == null) return [];
    return List<String>.from(jsonDecode(jsonString)); // ✅ Convert JSON back to List<String>
  }

  // ------------------- UTILITY METHODS -------------------

  Future<void> remove(String key) async {
    await _prefs?.remove(key);
    Logger().info('🗑️ Removed key: $key');
  }

  Future<void> clear() async {
    await _prefs?.clear();
    Logger().info('🗑️ Cleared all preferences');
  }

  @override
  void dispose() {
    super.dispose();
    Logger().info('🛑 SharedPrefManager disposed.');
  }
}
