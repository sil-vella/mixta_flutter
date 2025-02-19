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
}
