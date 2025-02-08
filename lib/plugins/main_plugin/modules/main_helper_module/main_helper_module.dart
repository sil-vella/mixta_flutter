import '../../../../core/00_base/module_base.dart';
import '../../../../core/managers/services_manager.dart';
import '../../../../tools/logging/logger.dart';

class MainHelperModule extends ModuleBase {
  static MainHelperModule? _instance;
  final ServicesManager _servicesManager = ServicesManager();

  MainHelperModule._internal() {
    Logger().info('FunctionHelperModule initialized.');
  }

  /// Factory method to ensure singleton
  factory MainHelperModule() {
    _instance ??= MainHelperModule._internal();
    return _instance!;
  }

  /// Update user information in Shared Preferences
  Future<void> updateUserInfo(String key, dynamic value) async {
    final sharedPref = _servicesManager.getService('shared_pref');

    if (sharedPref != null) {
      if (value is String) {
        await sharedPref.callServiceMethod('setString', [key, value]);
      } else if (value is int) {
        await sharedPref.callServiceMethod('setInt', [key, value]);
      }
      Logger().info('Updated $key: $value');
    } else {
      Logger().error('SharedPrefManager not available.');
    }
  }

  /// Retrieve stored user information
  Future<dynamic> getUserInfo(String key) async {
    final sharedPref = _servicesManager.getService('shared_pref');

    if (sharedPref != null) {
      if (key == 'points') {
        return await sharedPref.callServiceMethod('getInt', [key]);
      } else {
        return await sharedPref.callServiceMethod('getString', [key]);
      }
    }
    Logger().error('SharedPrefManager not available.');
    return null;
  }
}
