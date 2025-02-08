import '../../../../../core/00_base/module_base.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../../../tools/logging/logger.dart';

class BannerAdModule extends ModuleBase {
  final String adUnitId;
  BannerAd? _bannerAd;

  BannerAdModule._internal(this.adUnitId) {
    _registerBannerMethods();
  }

  /// Factory method to create an instance with the specified ad unit ID
  factory BannerAdModule(String adUnitId) {
    return BannerAdModule._internal(adUnitId);
  }

  void _registerBannerMethods() {
    registerMethod('loadBannerAd', loadBannerAd);
    registerMethod('disposeBannerAd', disposeBannerAd);
    registerMethod('getBannerWidget', getBannerWidget); // ✅ Register widget retrieval
  }

  /// ✅ Loads the banner ad
  Future<void> loadBannerAd() async {
    Logger().info('📢 Loading Banner Ad...');

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => Logger().info('✅ Banner Ad Loaded.'),
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          Logger().error('❌ Failed to load Banner Ad: ${error.message}');
          ad.dispose();
        },
      ),
    );

    _bannerAd?.load();
  }

  /// ✅ Returns a widget that loads and displays the banner ad
  Widget getBannerWidget(BuildContext context) {
    return FutureBuilder<void>(
      future: loadBannerAd(), // ✅ Ensure ad loads before displaying
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(), // ✅ Show loading spinner
          );
        } else if (snapshot.connectionState == ConnectionState.done) {
          if (_bannerAd != null) {
            return Container(
              width: MediaQuery.of(context).size.width,
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            );
          } else {
            return const Text("❌ Failed to load banner ad.");
          }
        }
        return const SizedBox();
      },
    );
  }

  /// ✅ Disposes of the banner ad
  void disposeBannerAd() {
    _bannerAd?.dispose();
  }
}
