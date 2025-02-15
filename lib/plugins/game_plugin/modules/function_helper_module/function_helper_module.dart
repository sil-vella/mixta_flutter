import 'dart:async';
import 'dart:convert'; // ✅ Required for JSON encoding/decoding
import '../../../../core/00_base/module_base.dart';
import '../../../../core/managers/services_manager.dart';
import '../../../../tools/logging/logger.dart';

class FunctionHelperModule extends ModuleBase {
  static FunctionHelperModule? _instance;
  final ServicesManager _servicesManager = ServicesManager();
  final Logger logger = Logger();

  FunctionHelperModule._internal() {
    logger.info('FunctionHelperModule initialized.');

    cleanupExpiredImages();
  }

  /// ✅ Factory method to ensure singleton
  factory FunctionHelperModule() {
    _instance ??= FunctionHelperModule._internal();
    return _instance!;
  }

  Future<void> storeImageCacheTimestamp(String imageUrl) async {
    final sharedPref = _servicesManager.getService('shared_pref');

    if (sharedPref == null) {
      logger.error('❌ SharedPreferences service not available.');
      return;
    }

    // ✅ Retrieve existing cached image timestamps
    String? cachedImages = await sharedPref.callServiceMethod('getString', ['cached_images']);
    Map<String, int> imageCacheMap = cachedImages != null ? Map<String, int>.from(jsonDecode(cachedImages)) : {};

    // ✅ Skip if image is already cached (avoid redundant updates)
    if (imageCacheMap.containsKey(imageUrl)) {
      return;
    }

    // ✅ Add new image timestamp
    imageCacheMap[imageUrl] = DateTime.now().millisecondsSinceEpoch;

    // ✅ Cleanup old images before saving the new entry
    await cleanupExpiredImages();

    // ✅ Save updated cache back to SharedPreferences (only if changed)
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

    // ✅ Remove expired images
    imageCacheMap.removeWhere((_, timestamp) => timestamp < twoMonthsAgo);

    // ✅ Save updated map back to SharedPreferences
    await sharedPref.callServiceMethod('setString', ['cached_images', jsonEncode(imageCacheMap)]);
  }
}
