import 'dart:async';
import 'dart:convert'; // ✅ Required for JSON encoding/decoding
import '../../../../core/00_base/module_base.dart';
import '../../../../core/managers/module_manager.dart';
import '../../../../core/managers/services_manager.dart';
import '../../../../tools/logging/logger.dart';
import '../../../main_plugin/modules/connections_module/connections_module.dart';

class FunctionHelperModule extends ModuleBase {
  static FunctionHelperModule? _instance;
  final ServicesManager _servicesManager = ServicesManager();
  final Logger logger = Logger();

  FunctionHelperModule._internal() {
    logger.info('🚀 FunctionHelperModule initialized.');
    cleanupExpiredImages(); // ✅ Run cleanup task
  }

  /// ✅ Factory method to ensure singleton
  factory FunctionHelperModule() {
    _instance ??= FunctionHelperModule._internal();
    return _instance!;
  }

  /// ✅ Fetches total points from all categories
  Future<int> getTotalPoints() async {
    final sharedPref = _servicesManager.getService('shared_pref');

    if (sharedPref == null) {
      logger.error('❌ SharedPreferences service not available.');
      return 0;
    }

    List<String> categories = await sharedPref.callServiceMethod('getStringList', ['available_categories']) ?? [];

    int totalPoints = 0;

    for (String category in categories) {
      int maxLevels = await sharedPref.callServiceMethod('getInt', ['max_levels_$category']) ?? 1;

      for (int level = 1; level <= maxLevels; level++) {
        int points = await sharedPref.callServiceMethod('getInt', ['points_${category}_level$level']) ?? 0;
        totalPoints += points;
      }
    }

    logger.info("🏆 Total Points across all categories: $totalPoints");
    return totalPoints;
  }

  Future<void> storeImageCacheTimestamp(String imageUrl) async {
    final sharedPref = _servicesManager.getService('shared_pref');

    if (sharedPref == null) {
      logger.error('❌ SharedPreferences service not available.');
      return;
    }

    String? cachedImages = await sharedPref.callServiceMethod('getString', ['cached_images']);
    Map<String, int> imageCacheMap = cachedImages != null ? Map<String, int>.from(jsonDecode(cachedImages)) : {};

    if (imageCacheMap.containsKey(imageUrl)) {
      return;
    }

    imageCacheMap[imageUrl] = DateTime.now().millisecondsSinceEpoch;
    await cleanupExpiredImages();
    await sharedPref.callServiceMethod('setString', ['cached_images', jsonEncode(imageCacheMap)]);
  }

  Future<void> cleanupExpiredImages() async {
    final sharedPref = _servicesManager.getService('shared_pref');

    if (sharedPref == null) {
      logger.error('❌ SharedPreferences service not available.');
      return;
    }

    String? cachedImages = await sharedPref.callServiceMethod('getString', ['cached_images']);
    if (cachedImages == null) return;

    Map<String, int> imageCacheMap = Map<String, int>.from(jsonDecode(cachedImages));

    final int now = DateTime.now().millisecondsSinceEpoch;
    final int twoMonthsAgo = now - (60 * 24 * 60 * 60 * 1000); // ✅ 60 days in milliseconds

    imageCacheMap.removeWhere((_, timestamp) => timestamp < twoMonthsAgo);
    await sharedPref.callServiceMethod('setString', ['cached_images', jsonEncode(imageCacheMap)]);
  }

  Future<void> clearUserProgress() async {
    final sharedPref = _servicesManager.getService('shared_pref');
    try {
      Logger().info("🧹 Resetting SharedPreferences values for levels, points, and guessed names...");

      // ✅ Fetch all keys from SharedPreferences
      final Set<String> allKeys = await sharedPref?.callServiceMethod('getKeys', []) ?? {};

      if (allKeys.isEmpty) {
        Logger().info("⚠️ No keys found in SharedPreferences.");
        return;
      }

      Logger().info("✅ Retrieved all keys from SharedPreferences: $allKeys");

      for (String key in allKeys) {
        // Check if the key contains 'level', 'points', or 'guessed'
        if (key.contains('level') || key.contains('points') || key.contains('guessed')) {
          // Determine the type of the value and reset it
          dynamic value = await sharedPref?.callServiceMethod('get', [key]);

          if (value is int) {
            int resetValue = key.contains('level_') ? 1 : 0; // ✅ Levels reset to 1, Points reset to 0
            await sharedPref?.callServiceMethod('setInt', [key, resetValue]);
            Logger().info("✅ Reset key: $key to $resetValue");

          } else if (value is List<String>) {
            // ✅ Reset lists to empty
            await sharedPref?.callServiceMethod('setStringList', [key, []]);
            Logger().info("✅ Reset key: $key to []");

          } else if (value is String) {
            // ✅ Reset strings to empty (if applicable)
            await sharedPref?.callServiceMethod('setString', [key, '']);
            Logger().info("✅ Reset key: $key to ''");

          } else {
            Logger().info("⚠️ Key $key has an unsupported type: ${value.runtimeType}");
          }
        }
      }



      Logger().info("✅ SharedPreferences values reset successfully.");
    } catch (e) {
      Logger().error("❌ Error resetting category system: $e", error: e);
    }
  }
}
