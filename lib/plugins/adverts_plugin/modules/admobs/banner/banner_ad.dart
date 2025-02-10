import '../../../../../core/00_base/module_base.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../../../tools/logging/logger.dart';

class BannerAdModule extends ModuleBase {
  final Map<String, BannerAd?> _banners = {}; // Store multiple ads

  BannerAdModule() {
    _registerBannerMethods();
  }

  void _registerBannerMethods() {
    registerMethod('loadBannerAd', (String adUnitId) => loadBannerAd(adUnitId));
    registerMethod('disposeBannerAd', (String adUnitId) => disposeBannerAd(adUnitId));
    registerMethod('getBannerWidget', (String adUnitId, BuildContext context) => getBannerWidget(adUnitId, context));
  }

  /// ✅ Loads the banner ad with a specified ad unit ID
  Future<void> loadBannerAd(String adUnitId) async {
    Logger().info('📢 Loading Banner Ad for ID: $adUnitId');

    final bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => Logger().info('✅ Banner Ad Loaded for ID: $adUnitId.'),
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          Logger().error('❌ Failed to load Banner Ad for ID: $adUnitId. Error: ${error.message}');
          ad.dispose();
        },
      ),
    );

    await bannerAd.load();
    _banners[adUnitId] = bannerAd;
  }

  Widget getBannerWidget(String adUnitId, BuildContext context) {
    // Always create a new BannerAd instance to avoid reusing the same AdWidget
    final bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => Logger().info('✅ Banner Ad Loaded for ID: $adUnitId.'),
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          Logger().error('❌ Failed to load Banner Ad for ID: $adUnitId. Error: ${error.message}');
          ad.dispose();
        },
      ),
    );

    bannerAd.load(); // Ensure the ad is loaded before displaying

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: bannerAd.size.height.toDouble(),
      child: AdWidget(ad: bannerAd),
    );
  }



  /// ✅ Disposes of the banner ad
  void disposeBannerAd(String adUnitId) {
    _banners[adUnitId]?.dispose();
    _banners.remove(adUnitId);
  }
}